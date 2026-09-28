"""General pregnancy assistant: conversation, week insights, symptom guidance.

Distinct from rag_chain, which answers one question - "is this food safe?" -
against a curated knowledge base and returns a verdict. This module handles
open conversation and the week-shaped features the web client needs, where
there is no single food to look up and no verdict to give.

It exists on the backend rather than on whichever host serves the web client
so that the OpenAI key stays in one place. Two clients, one key, one set of
prompts - a second copy on the web tier would be a second key to rotate and a
second place for the clinical guardrails to drift.
"""

import json
import logging

from openai import OpenAI

from app.config import settings
from app.schemas import (
    AssistantChatRequest,
    SymptomClassification,
    SymptomGuidance,
    SymptomRequest,
    TipsRequest,
    WeekInsight,
    WellnessTip,
)

logger = logging.getLogger(__name__)
client = OpenAI(api_key=settings.openai_api_key)

# Shared by all three features. The scope limits are the point: this is the
# only thing standing between a chat box and someone treating it as a
# diagnosis, so they are stated once and reused rather than restated per
# prompt where they would drift apart.
BASE_SYSTEM = """You are Bloom, an evidence-informed AI pregnancy companion inside a
pregnancy tracker.

Tone: precise, calm, reassuring, clinical. Plain language a clinician would be
comfortable with. Cite week-specific physiology where it is relevant.

SCOPE - you are informational, NOT a diagnostic device and NOT a replacement for
a clinician:
- Never give a diagnosis, and never contradict the user's care team.
- Tailor answers to the stated gestational week.
- Where a symptom could be urgent - heavy bleeding, severe abdominal pain,
  sudden severe swelling, severe headache with vision changes, reduced fetal
  movement after about 20 weeks, fever, signs of preterm labour - say plainly
  that they should contact their midwife, doctor, or emergency services now.
- Keep answers short and skimmable. Metric units. Practical, non-prescriptive.
"""


def _context_line(req: AssistantChatRequest) -> str:
    ctx = req.context
    parts = [
        f"Current gestational week: {ctx.week} of 40." if ctx.week else "",
        f"Trimester: {ctx.trimester}." if ctx.trimester else "",
        f"Weeks remaining: {ctx.weeks_left}." if ctx.weeks_left is not None else "",
        f"Estimated due date: {ctx.due_date}." if ctx.due_date else "",
    ]
    line = " ".join(p for p in parts if p)
    return line or (
        "No pregnancy profile is set, so answer generally and ask for the "
        "current week if it changes the answer."
    )


def _chat_messages(req: AssistantChatRequest) -> list[dict]:
    messages = [{"role": "system", "content": f"{BASE_SYSTEM}\n{_context_line(req)}"}]
    # Only the two roles the model accepts, and only the recent turns. A client
    # that invents a third role should not be able to smuggle it into the
    # system position, and an unbounded history is an unbounded bill.
    for m in req.messages[-20:]:
        role = "assistant" if m.role == "assistant" else "user"
        messages.append({"role": role, "content": m.content})
    return messages


def chat(req: AssistantChatRequest) -> str:
    """One assistant turn, complete. For clients that cannot stream."""
    completion = client.chat.completions.create(
        model=settings.chat_model,
        messages=_chat_messages(req),
    )
    return completion.choices[0].message.content or ""


def chat_stream(req: AssistantChatRequest):
    """The same turn as text chunks, for clients that can render them as they land.

    Yields plain text, not a wire protocol. The web client speaks the AI SDK's
    UI-message stream and the mobile client does not, so the shape they each
    need is decided at their own edge rather than here.
    """
    stream = client.chat.completions.create(
        model=settings.chat_model,
        messages=_chat_messages(req),
        stream=True,
    )
    for chunk in stream:
        if not chunk.choices:
            continue
        piece = chunk.choices[0].delta.content
        if piece:
            yield piece


def _json_call(system: str, user: str) -> dict | None:
    """Returns None on any failure - every caller has a usable fallback."""
    try:
        completion = client.chat.completions.create(
            model=settings.chat_model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            response_format={"type": "json_object"},
        )
        return json.loads(completion.choices[0].message.content)
    except Exception:
        logger.exception("assistant json call failed")
        return None


def week_insights(week: int) -> list[WeekInsight]:
    """Two notes for the week: one about the baby, one about the mother."""
    data = _json_call(
        BASE_SYSTEM
        + '\nRespond ONLY with JSON: {"insights":[{"title":string,"body":string}]}. '
        "Exactly two items - the first about fetal development, the second about "
        "maternal changes and what to watch. One or two sentences each.",
        f"Pregnancy insights for week {week} of 40.",
    )
    items = (data or {}).get("insights") or []
    out = [
        WeekInsight(title=str(i.get("title") or ""), body=str(i.get("body") or ""))
        for i in items
        if isinstance(i, dict) and i.get("body")
    ]
    if out:
        return out[:2]

    # The week screen is not worth failing over a model hiccup, and the app
    # already ships week-by-week reference text for exactly this.
    return [
        WeekInsight(
            title=f"Week {week}",
            body="Insights are unavailable right now. Your week-by-week guide "
            "still has this week's development and what to expect.",
        )
    ]


def symptom_guidance(req: SymptomRequest) -> SymptomGuidance:
    """Triage-shaped guidance. Never a diagnosis - see the classification rule."""
    data = _json_call(
        BASE_SYSTEM
        + "\nYou are classifying a described symptom in pregnancy. Respond ONLY "
        'with JSON: {"classification":"normal"|"caution"|"seek-care",'
        '"label":string,"explanation":string,"red_flags":[string],'
        '"when_to_call":string}. '
        "classification is about urgency, never a diagnosis: 'normal' means "
        "common and not concerning at this stage, 'caution' means worth raising "
        "at the next appointment, 'seek-care' means contact a clinician now. "
        "When the description is ambiguous, choose the more cautious of two "
        "options - the cost of an unnecessary call is a phone call, and the "
        "cost of a missed one is not comparable. "
        "red_flags: what would change this into an emergency.",
        f"Week {req.week} of 40. The user describes: {req.description}",
    )

    if not data:
        # A failure must not read as reassurance. With no answer, the safe
        # output is the one that sends them to a person.
        return SymptomGuidance(
            classification=SymptomClassification.CAUTION,
            label="Could not assess this right now",
            explanation="The assistant could not review this symptom. That is a "
            "problem with the service, not a judgement about the symptom.",
            red_flags=[],
            when_to_call="If you are worried about this symptom, contact your "
            "midwife or doctor rather than waiting for the assistant.",
        )

    raw = str(data.get("classification") or "").lower()
    try:
        classification = SymptomClassification(raw)
    except ValueError:
        classification = SymptomClassification.CAUTION

    flags = data.get("red_flags")
    return SymptomGuidance(
        classification=classification,
        label=str(data.get("label") or "Symptom noted"),
        explanation=str(data.get("explanation") or ""),
        red_flags=[str(f) for f in flags if str(f).strip()] if isinstance(flags, list) else [],
        when_to_call=str(data.get("when_to_call") or "Contact your care team if this worsens."),
    )


def wellness_tips(req: TipsRequest) -> list[WellnessTip]:
    """Three tips for the week: nutrition, movement, wellness."""
    profile = f" The user adds: {req.profile}" if req.profile else ""
    data = _json_call(
        BASE_SYSTEM
        + '\nRespond ONLY with JSON: {"tips":[{"title":string,"body":string}]}. '
        "Exactly three items, titled Nutrition, Movement and Wellness in that "
        "order. One or two sentences each, specific to the stated week.",
        f"Wellness tips for week {req.week} of 40.{profile}",
    )
    items = (data or {}).get("tips") or []
    out = [
        WellnessTip(title=str(t.get("title") or ""), body=str(t.get("body") or ""))
        for t in items
        if isinstance(t, dict) and t.get("body")
    ]
    return out[:3]
