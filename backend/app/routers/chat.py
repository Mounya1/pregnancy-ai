from fastapi import APIRouter
from app.schemas import ChatRequest, ChatResponse
from app.rag_chain import analyze_food, generate_followups
from app import health_chat

router = APIRouter(prefix="/chat", tags=["chat"])


def respond(message: str, profile, history=None) -> ChatResponse:
    """Food questions get a verdict card; everything else an everyday health
    answer. Shared with /voice, so speaking a question behaves like typing it."""
    if health_chat.classify(message, history) == "health":
        return ChatResponse(
            kind="health",
            reply_text=health_chat.answer(message, profile, history),
            suggested_followups=health_chat.followups(message, profile),
        )

    mother_result, baby_result = analyze_food(message, profile=profile)
    return ChatResponse(
        kind="food",
        reply_text=mother_result.explanation,
        structured=mother_result,
        baby_structured=baby_result,
        suggested_followups=generate_followups(message, profile),
    )


@router.post("", response_model=ChatResponse)
def chat(req: ChatRequest):
    return respond(req.message, req.profile, req.history)
