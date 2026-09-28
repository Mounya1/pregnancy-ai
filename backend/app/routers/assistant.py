from fastapi import APIRouter
from fastapi.responses import StreamingResponse

from app import assistant
from app.schemas import (
    AssistantChatRequest,
    AssistantChatResponse,
    SymptomGuidance,
    SymptomRequest,
    TipsRequest,
    TipsResponse,
    WeekInsightsResponse,
)

router = APIRouter(prefix="/assistant", tags=["assistant"])


@router.post("/chat", response_model=AssistantChatResponse)
def chat(req: AssistantChatRequest):
    """Open conversation, as opposed to /chat which returns a food verdict."""
    return AssistantChatResponse(reply=assistant.chat(req))


@router.post("/chat/stream")
def chat_stream(req: AssistantChatRequest):
    """The same answer as it is generated, as plain UTF-8 text chunks.

    No SSE framing and no JSON envelope: the two clients want different wire
    formats, and each wraps this at its own edge. Buffering is disabled so a
    proxy in front does not hold the whole answer back and undo the point.
    """
    return StreamingResponse(
        assistant.chat_stream(req),
        media_type="text/plain; charset=utf-8",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@router.get("/insights", response_model=WeekInsightsResponse)
def insights(week: int):
    return WeekInsightsResponse(insights=assistant.week_insights(week))


@router.post("/symptom", response_model=SymptomGuidance)
def symptom(req: SymptomRequest):
    return assistant.symptom_guidance(req)


@router.post("/tips", response_model=TipsResponse)
def tips(req: TipsRequest):
    return TipsResponse(tips=assistant.wellness_tips(req))
