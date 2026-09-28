/**
 * Calls the project's own API (FastAPI on Cloud Run). Server-only.
 *
 * Replaces the Lovable AI Gateway. The model key stays on that service - one
 * key, one place to rotate it, one copy of the clinical prompts - rather than
 * being issued to whichever host happens to be serving this web client. It is
 * also the same API the Flutter mobile app talks to, so the two cannot drift
 * apart in what they tell people.
 */

/** Set at build/deploy time on the web host, e.g. the Cloud Run service URL. */
export function backendBaseUrl(): string {
  const raw = process.env["API_BASE_URL"] ?? process.env["VITE_API_BASE_URL"];
  if (!raw) {
    throw new Error(
      "API_BASE_URL is not set, so the assistant has no backend to call.",
    );
  }
  return raw.replace(/\/+$/, "");
}

export class BackendError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
    this.name = "BackendError";
  }
}

async function request<T>(
  path: string,
  init: RequestInit & { timeoutMs?: number } = {},
): Promise<T> {
  const { timeoutMs = 60_000, ...rest } = init;

  // A model call behind this can sit for a while, but not forever - without a
  // ceiling a stalled upstream holds the request open until the platform kills
  // it, which surfaces as a blank page rather than an error.
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), timeoutMs);

  try {
    const res = await fetch(`${backendBaseUrl()}${path}`, {
      ...rest,
      signal: rest.signal ?? abort.signal,
      headers: { "content-type": "application/json", ...(rest.headers ?? {}) },
    });

    if (!res.ok) {
      // FastAPI puts the human-readable reason in `detail`.
      let detail = `Request to ${path} failed (${res.status}).`;
      try {
        const body = (await res.json()) as { detail?: string };
        if (body?.detail) detail = body.detail;
      } catch {
        // Non-JSON error body; the status line is all there is.
      }
      throw new BackendError(detail, res.status);
    }

    return (await res.json()) as T;
  } finally {
    clearTimeout(timer);
  }
}

// signal is spread in only when present: exactOptionalPropertyTypes is on, so
// an explicit `signal: undefined` is a type error rather than a no-op.
export function postJson<T>(path: string, body: unknown, signal?: AbortSignal) {
  return request<T>(path, {
    method: "POST",
    body: JSON.stringify(body),
    ...(signal ? { signal } : {}),
  });
}

export function getJson<T>(path: string, signal?: AbortSignal) {
  return request<T>(path, { method: "GET", ...(signal ? { signal } : {}) });
}
