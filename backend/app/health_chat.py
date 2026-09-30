"""Everyday health questions in the mobile chat - everything that is not
"is this food safe?".

The chat used to send every message down the food-verdict pipeline, so
"how much should I sleep?" or "is walking good in the third trimester?" came
back as a verdict card about a food called "sleep". This module decides which
kind of question a message is, and answers the non-food kind as a normal
conversational reply, personalised with the same profile the food pipeline
uses: stage, gender, conditions, report findings, language.

assistant.py serves the web client's Bloom chat and stays separate: it is
pregnancy-only and knows the week but not the profile.
"""
from __future__ import annotations

import json
import logging

from openai import OpenAI

from app.config import settings
from app.rag_chain import _build_context, constraints_note, language_note, life_stage_note
from app.schemas import AssistantMessage, LifeStage, UserProfile

logger = logging.getLogger(__name__)
client = OpenAI(api_key=settings.openai_api_key)

ROUTER_PROMPT = """Classify the user's latest chat message for a pregnancy and family
health app. Reply with JSON: {"kind": "food"} or {"kind": "health"}.

"food": asks whether a specific food, drink, dish, ingredient, supplement or herb is safe,
okay, healthy, or how much of it to have, or asks about one food's nutrition.
Examples: "can I eat custard apple", "is coffee ok", "how much fish per week",
"is ashwagandha safe", "benefits of dates".

"health": everything else - symptoms, sleep, exercise, daily routine, weight, stress and
mood, skin and hair, appointments, labour, recovery, baby care, general diet advice not
about one specific food ("what should I eat today", "foods for energy"), greetings, and
anything unclear.

Use the previous turn, if given, to resolve short follow-ups like "and at night?"."""

HEALTH_SYSTEM = """You are Bloom, a warm, knowledgeable health companion inside a pregnancy,
postpartum and family nutrition app. Answer the user's everyday health question -
daily routine, sleep, exercise, symptoms, mood, weight, hydration, skin, work, travel,
baby care, recovery - for THEIR life stage and situation, given below.

ALWAYS GIVE A REAL, PRACTICAL ANSWER. Never reply only "ask your doctor". Give concrete
steps someone can act on today: what to do, how much, how often, what to avoid. When the
answer depends on their health or the evidence is limited, still give the best general
guidance, then say what to confirm with their doctor.

SAFETY:
- You are not a diagnostic tool. Never diagnose, never prescribe medicine or doses, never
  contradict their care team.
- If anything described could be urgent, lead with that and tell them to contact their
  doctor, midwife or emergency services now. In pregnancy: bleeding, fluid leaking,
  severe or constant abdominal pain, severe headache or vision changes, sudden swelling of
  face or hands, fever, fewer baby movements after about 20 weeks, regular contractions
  before 37 weeks. After birth: heavy bleeding, fever, chest pain or breathlessness, a
  painful swollen leg, thoughts of self-harm. For anyone: chest pain, trouble breathing,
  fainting, signs of stroke.
- Use their medical report findings and conditions when they bear on the question, and
  say how.

STYLE: plain language, short and skimmable - a sentence or two, then a few bullet points
starting with "•". No markdown headings, no bold, no tables. Metric units. Under about
180 words unless they ask for more.

REFERENCE: material from the app's sourced library may be given below. Prefer it where it
applies; otherwise use mainstream guidance (ACOG, WHO, NHS, CDC, NIH). Never invent a
source."""

# Offered under a health answer, by stage. Kept to everyday topics.
_FOLLOWUPS = {
    LifeStage.PREGNANCY: [
        "What exercise is safe for me now?",
        "How can I sleep better?",
        "What should my daily routine look like?",
    ],
    LifeStage.BREASTFEEDING: [
        "How much water should I drink while nursing?",
        "How can I rest with a newborn?",
        "When can I start exercising again?",
    ],
    LifeStage.POSTPARTUM_NOT_NURSING: [
        "How long does recovery take?",
        "When can I start exercising again?",
        "What should I eat to recover?",
    ],
    LifeStage.GENERAL: [
        "What's a healthy daily routine?",
        "How much water should I drink?",
        "How can I sleep better?",
    ],
}


def _transcript(history: list[AssistantMessage], limit: int = 6) -> list[dict]:
    """Recent turns in the two roles the model accepts. Bounded - an
    unbounded history is an unbounded bill."""
    return [
        {"role": "assistant" if m.role == "assistant" else "user", "content": m.content[:1500]}
        for m in history[-limit:]
    ]


def classify(message: str, history: list[AssistantMessage] | None = None) -> str:
    """"food" or "health". Falls back to "food" - the original behaviour - if
    the router call fails, so an outage there never breaks the chat."""
    previous = ""
    if history:
        last = history[-1]
        previous = f"Previous turn ({last.role}): {last.content[:300]}\n"
    try:
        completion = client.chat.completions.create(
            model=settings.router_model,
            messages=[
                {"role": "system", "content": ROUTER_PROMPT},
                {"role": "user", "content": f"{previous}Latest message: {message}"},
            ],
            temperature=0,
            response_format={"type": "json_object"},
        )
        kind = json.loads(completion.choices[0].message.content).get("kind")
        return "health" if kind == "health" else "food"
    except Exception:
        logger.exception("chat router failed; treating as a food question")
        return "food"


def _profile_block(profile: UserProfile) -> str:
    parts = [life_stage_note(profile)]
    if profile.pregnancy_week and profile.life_stage == LifeStage.PREGNANCY:
        trimester = 1 if profile.pregnancy_week <= 13 else 2 if profile.pregnancy_week <= 27 else 3
        parts.append(f"Trimester {trimester}.")
    constraints = constraints_note(profile)
    if constraints:
        parts.append(constraints)
    language = language_note(profile)
    if language:
        parts.append(language.replace("every human-readable text value", "your whole reply"))
    return "\n".join(parts)


def answer(
    message: str, profile: UserProfile, history: list[AssistantMessage] | None = None
) -> str:
    try:
        reference = _build_context(message, "daily health routine")
    except Exception:
        # The library is a bonus here, not a requirement - answer without it.
        logger.exception("reference lookup failed for health chat")
        reference = ""

    system = f"{HEALTH_SYSTEM}\n\nABOUT THIS USER:\n{_profile_block(profile)}"
    if reference:
        system += f"\n\nREFERENCE:\n{reference}"

    completion = client.chat.completions.create(
        model=settings.chat_model,
        messages=[
            {"role": "system", "content": system},
            *_transcript(history or []),
            {"role": "user", "content": message},
        ],
        temperature=0.4,
    )
    return (completion.choices[0].message.content or "").strip()


def followups(message: str, profile: UserProfile) -> list[str]:
    options = _FOLLOWUPS.get(profile.life_stage, _FOLLOWUPS[LifeStage.GENERAL])
    return [q for q in options if q.lower() not in message.lower()][:3]
