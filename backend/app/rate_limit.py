"""Per-client rate limiting and request-size limits.

Every POST on this API spends OpenAI credit, and the URL is public - the web
app has to be able to call it without a login. CORS does not help: it stops
other *websites* reading the response, not a script calling the API directly.
So the cap has to live here.

In memory, per instance, on purpose. Cloud Run may run several instances, so
the real ceiling is the limit times the instance count - which is why the
deploy guide also caps --max-instances. A shared store (Redis, Firestore)
would make it exact, at the price of a second service to run and pay for;
for a free-tier app the goal is to stop one abusive client burning the
budget, not to meter precisely.
"""
from __future__ import annotations

import threading
import time
from collections import defaultdict, deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from app.config import settings

# Cheap, AI-free, or needed to diagnose an outage - never limited.
_EXEMPT_PATHS = {"/health", "/docs", "/openapi.json", "/redoc"}

# GET endpoints that call a paid model.
_PAID_GET_PATHS = {"/tts", "/assistant/insights"}

_MINUTE = 60.0
_DAY = 86_400.0


def client_id(request: Request) -> str:
    """The caller's IP.

    Cloud Run (and Render, Koyeb) sit behind a proxy, so request.client is the
    proxy. The first X-Forwarded-For entry is the address the proxy saw.
    """
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


class RateLimiter:
    """Sliding-window counts per client, for a per-minute and a per-day cap."""

    def __init__(self, per_minute: int, per_day: int):
        self.per_minute = per_minute
        self.per_day = per_day
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def check(self, key: str, now: float | None = None) -> int | None:
        """Records a hit. Returns None if allowed, else seconds to wait."""
        now = time.monotonic() if now is None else now
        with self._lock:
            hits = self._hits[key]
            while hits and now - hits[0] >= _DAY:
                hits.popleft()

            if len(hits) >= self.per_day:
                return max(1, int(_DAY - (now - hits[0])))

            recent = [t for t in hits if now - t < _MINUTE]
            if len(recent) >= self.per_minute:
                return max(1, int(_MINUTE - (now - recent[0])))

            hits.append(now)
            # Idle clients would otherwise keep an empty deque forever.
            if len(self._hits) > 10_000:
                for k in [k for k, v in self._hits.items() if not v]:
                    del self._hits[k]
            return None


class AbuseProtectionMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limiter: RateLimiter, max_body_bytes: int):
        super().__init__(app)
        self.limiter = limiter
        self.max_body_bytes = max_body_bytes

    def _reject(self, request: Request, status: int, detail: str, headers: dict | None = None):
        # Built here, outside CORSMiddleware's reach for errors, so it carries
        # its own CORS header - otherwise the browser reports "cannot reach the
        # server" instead of the actual reason.
        headers = dict(headers or {})
        origin = request.headers.get("origin")
        allowed = settings.cors_origins
        if origin and ("*" in allowed or origin in allowed):
            headers["Access-Control-Allow-Origin"] = origin
            headers["Vary"] = "Origin"
        return JSONResponse(status_code=status, content={"detail": detail}, headers=headers)

    async def dispatch(self, request: Request, call_next):
        # POSTs call the model, and so does GET /tts - a GET so the URL can go
        # straight into an audio player, but it spends credit like any other.
        # OPTIONS preflights must never be counted, or every request would
        # cost two.
        costs_credit = request.method == "POST" or (
            request.method == "GET" and request.url.path in _PAID_GET_PATHS
        )
        if not costs_credit or request.url.path in _EXEMPT_PATHS:
            return await call_next(request)

        length = request.headers.get("content-length")
        if length and length.isdigit() and int(length) > self.max_body_bytes:
            mb = self.max_body_bytes // (1024 * 1024)
            return self._reject(request, 413, f"Upload too large - the limit is {mb} MB.")

        wait = self.limiter.check(client_id(request))
        if wait is not None:
            return self._reject(
                request,
                429,
                "Too many requests - please wait a moment and try again.",
                {"Retry-After": str(wait)},
            )
        return await call_next(request)
