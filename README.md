# Pregnancy, Postpartum & Family Nutrition AI Assistant

An AI health companion for **pregnancy**, **breastfeeding and postpartum**, **baby feeding**, and **general adult nutrition**. Ask about any food or any everyday health question by text, voice, or photo, and get answers tailored to your life stage, gender, allergies, conditions, and your own medical reports.

Food answers are grounded in ACOG / CDC / FDA / NIH / AAP guidance through retrieval (RAG), with hard-coded overrides for the foods where a wrong answer is dangerous.

**Stack:** FastAPI + LangChain/FAISS + OpenAI on Google Cloud Run · Flutter web and Android on Vercel · optional AWS Cognito accounts and DynamoDB sync.

---

## Contents

- [Features](#features)
- [How answers work](#how-answers-work)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Run it locally](#run-it-locally)
- [Deploy](#deploy)
- [API reference](#api-reference)
- [Accounts & data](#accounts--data)
- [Safety design](#safety-design)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)

---

## Features

| | Feature | What it does |
|---|---|---|
| 💬 | **Chat** | Ask anything. Food questions ("can I eat custard apple?") get a Safe / Limit / Avoid verdict card; everyday health questions (sleep, exercise, symptoms, daily routine) get a conversational answer. Follow-ups use the recent conversation. |
| 👩‍🍼 | **Mother + baby verdicts** | In pregnancy, one question returns a card for you and one for the unborn baby. With a baby eating solids, the second card is about feeding the baby directly - e.g. honey: fine for a nursing mother, **Avoid** under 12 months. |
| 🎤 | **Voice** | Speak a question in any language (Whisper), hear the answer read back (OpenAI TTS). |
| 📷 | **Food photo** | Photograph a meal, fruit, package, or label; the vision model identifies it and the same verdict pipeline runs. |
| 🩺 | **Medical reports** | Upload a lab report (PDF or photo). It is summarised, conditions are added to your profile, and out-of-range values ("Haemoglobin 9.4 g/dL, low") shape every later answer and meal plan. |
| 🍽️ | **Meal planner + grocery list** | 1-7 day plans built around your stage, allergies, cuisines, and conditions, with a combined grocery list grouped by aisle - tick items off or copy the list. Never includes a high-risk food. |
| 📊 | **Nutrition tracker** | Search ~80 common foods (including Indian staples) or type any food for an AI estimate. Tracks iron, calcium, folate, protein, and vitamin D against targets for your stage - and, in General mode, your gender. |
| 🏃 | **Fitness plan** | Stage-appropriate exercise with warning signs to stop. |
| 🗓️ | **Pregnancy & baby tracking** | Week-by-week updates, kick counter, contraction timer, care plan and supplements, baby growth and milestones, reminders. |
| 🌐 | **Answer language** | The AI replies in English, Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Spanish, French, Portuguese, Arabic, or Chinese. |
| 🔐 | **Accounts** | Device-only by default; real email accounts with AWS Cognito when configured. |

The home screen follows your stage: a pregnancy picture while pregnant, a mother holding her baby after the birth, and a man or woman in General mode.

---

## How answers work

**Every chat message is first sorted** by a small model (`gpt-4o-mini`): is it about a specific food, or a general health question?

**Food questions** → retrieval over the knowledge base → `gpt-4o` → structured verdict:

| The food is… | You get |
|---|---|
| In the sourced knowledge base | An answer from that guidance, with sources |
| An everyday food not in it (custard apple, dates, guava…) | A full answer from general nutrition knowledge, labelled *"General guidance"* |
| Uncertain (herbs, supplements, depends on your health) | Still a full answer, with the most cautious verdict and a **"check with your doctor"** note |
| On the high-risk list, or one of your allergies | The app's own rules override the model |

**Health questions** → `gpt-4o` with your stage, trimester, conditions, report findings, and language. Always practical steps; anything that could be urgent is put first with a clear "contact your doctor now".

---

## Tech stack

**Backend** - FastAPI (Python 3.11) · LangChain + FAISS · Pydantic · Docker on Google Cloud Run

| Job | Model (env var) |
|---|---|
| Answers, plans, reports | `gpt-4o` (`CHAT_MODEL`) |
| Photos | `gpt-4o` (`VISION_MODEL`) |
| Sorting chat messages | `gpt-4o-mini` (`ROUTER_MODEL`) |
| Knowledge-base search | `text-embedding-3-small` (`EMBEDDING_MODEL`) |
| Speech to text | `whisper-1` (`STT_MODEL`) |
| Text to speech | `tts-1` (`TTS_MODEL`) |

**Frontend** - Flutter (web + Android) · `provider` · `shared_preferences` · `dio` · `record` / `just_audio` · `image_picker` / `file_picker`

**Also in the repo** - `web/`: a React (TanStack Start) client, "Bloom", that talks to the same backend's `/assistant/*` endpoints.

---

## Architecture

```
Flutter app (Vercel / Android)          React "Bloom" web client (web/)
          │                                         │
          └──────────────┬──────────────────────────┘
                         ▼
          FastAPI on Google Cloud Run  (OpenAI key in Secret Manager)
          ├── rate limiting + upload cap (every AI-calling request)
          ├── /chat, /voice   → router → food verdict (RAG) or health answer
          ├── /food-analysis  → vision → food verdict
          ├── /meal-plan, /fitness-plan, /medical-report, /nutrition/estimate
          ├── /tts
          ├── /assistant/*    → Bloom web client
          └── /sync           → DynamoDB (optional, Cognito-authenticated)
                         │
                         ▼
          FAISS index of seed_data/medical_knowledge.json (79 topics)
          + high_risk_list.py (pregnancy + age-gated baby hazards)
```

---

## Project structure

```
backend/
  app/
    main.py              app, CORS, rate-limit middleware, /health
    config.py            settings from environment variables
    schemas.py           request/response models
    rag_chain.py         food verdict pipeline (retrieval + rules + overrides)
    health_chat.py       message router + everyday health answers
    assistant.py         Bloom web client's assistant
    rate_limit.py        per-client limits and upload cap
    knowledge_base.py    builds/loads the FAISS index
    high_risk_list.py    hard-coded safety overrides
    auth_jwt.py          Cognito token verification (for /sync)
    routers/             chat, voice, food_analysis, tts, meal_plan, fitness,
                         medical_report, nutrition, assistant, sync
  seed_data/medical_knowledge.json
  vector_store/          prebuilt FAISS index
  Dockerfile
frontend/
  lib/
    models/              profile, verdicts, meal plans, reports, nutrition, ...
    services/            API client, auth (device + Cognito), storage, sync
    screens/             home, chat, planner, tracker, reports, profile, auth, ...
    widgets/             verdict cards, stage figures, UI kit
  assets/images/
  test/
web/                     React "Bloom" client
cloudbuild.yaml          Cloud Build: deploy the backend on every push
vercel.json              Vercel: build the Flutter web app
DEPLOY.md                full deployment guide
```

---

## Run it locally

**Backend**

```bash
cd backend
python -m venv venv
source venv/bin/activate              # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                  # then set OPENAI_API_KEY
uvicorn app.main:app --reload
```

Open `http://localhost:8000/docs`. The FAISS index ships in `vector_store/`; rebuild it after editing the knowledge base with `python -m app.knowledge_base`.

**Frontend**

```bash
cd frontend
flutter pub get
flutter run -d chrome
flutter test
```

It calls `http://127.0.0.1:8000` unless built with `--dart-define=API_BASE_URL=...`.

> ⚠️ Never run `flutter create . --overwrite` in this repo - it replaces `lib/` and `pubspec.yaml` with Flutter's template.

---

## Deploy

Full steps are in **[DEPLOY.md](DEPLOY.md)**. In short:

**Backend → Google Cloud Run** (from Cloud Shell):

```bash
git clone https://github.com/Mounya1/pregnancy-ai.git && cd pregnancy-ai
gcloud run deploy pregnancy-ai-backend --source backend --region us-central1 \
  --allow-unauthenticated --memory 1Gi --timeout 300
# OpenAI key goes in Secret Manager - see DEPLOY.md §1c step 5
gcloud run services update pregnancy-ai-backend --region us-central1 --max-instances 3
```

To update later: `git pull`, then the same `gcloud run deploy` line. Environment variables and secrets are kept.

**Frontend → Vercel:** import the repo, leave Root Directory as `./` and Framework as **Other** (`vercel.json` does the build), and set:

| Variable | Value |
|---|---|
| `API_BASE_URL` | your Cloud Run URL |
| `COGNITO_REGION`, `COGNITO_CLIENT_ID` | optional - enables real accounts |

The app reads these at **build** time, so redeploy after changing them. Then lock the API to your site:

```bash
gcloud run services update pregnancy-ai-backend --region us-central1 \
  --update-env-vars ALLOWED_ORIGINS=https://your-site.vercel.app
```

---

## API reference

Interactive docs at `/docs` on any running backend.

| Method | Path | Purpose |
|---|---|---|
| POST | `/chat` | Food verdict or health answer. Body: `message`, `profile`, optional `history` |
| POST | `/voice` | Multipart `audio` + `profile_json` → transcript + chat response |
| POST | `/food-analysis` | Multipart `image` + `profile_json` → detected food + verdicts |
| GET | `/tts?text=` | Speech as `audio/mpeg`, usable directly as a media URL |
| POST | `/meal-plan` | Day-by-day plan + `grocery_list` |
| POST | `/fitness-plan` | Exercise plan + warning signs |
| POST | `/medical-report` | Multipart `report` (PDF/photo) → summary, findings, conditions |
| POST | `/nutrition/estimate` | Nutrients for a typed food |
| POST | `/assistant/chat`, `/assistant/chat/stream`, `/assistant/symptom`, `/assistant/tips` · GET `/assistant/insights` | Bloom web client |
| GET / PUT / DELETE | `/sync` | Cloud backup (Cognito token required) |
| GET | `/health` | Status, key configured, index present, sync enabled |

**`/chat` example**

```json
{
  "message": "hey can i eat custard apple",
  "profile": {
    "life_stage": "pregnancy",
    "pregnancy_week": 24,
    "allergies": [],
    "health_conditions": ["anaemia"],
    "report_notes": ["Haemoglobin 9.4 g/dL (low)"],
    "language": "English"
  }
}
```

Returns `kind` (`"food"` or `"health"`), `reply_text`, and for food, `structured` (for you) and `baby_structured` (for baby) with `verdict`, `explanation`, `benefits`, `risks`, `recommended_serving`, `sources`, `from_general_knowledge`, and `consult_doctor`.

---

## Accounts & data

- **Device-only (default):** the account and all data live in the browser or phone (`shared_preferences`). No server, and no password reset.
- **Cloud accounts (optional):** build with `COGNITO_REGION` and `COGNITO_CLIENT_ID`. Sign-up emails a 6-digit code; entering it signs you straight in. Cognito holds identity only - name, email, password.
- **Cloud sync (optional):** with DynamoDB configured on the backend, every device signed in to the same account - website and phone - shows the same profile and data, synced automatically within seconds. See DEPLOY.md §2b-2c.

Health data never leaves the device unless sync is switched on.

---

## Safety design

- **Hard-coded overrides** (`high_risk_list.py`) decide the verdict for well-established hazards regardless of the model: raw fish, unpasteurised dairy, deli meat, raw eggs, alcohol, high-mercury fish, and raw sprouts in pregnancy. For babies, age-gated: honey and cow's milk as a drink under 12 months, added salt and sugar, and choking hazards at any age.
- **Allergies always win** - a listed allergen is Avoid, for both cards.
- **Stage-correct answers** - a General or postpartum user is never given pregnancy warnings.
- **Sourced vs general** - answers not drawn from the sourced library are labelled, and uncertain ones carry a "check with your doctor" note.
- **Urgent symptoms** - health answers lead with "contact your doctor now" for red-flag symptoms, and never diagnose or give medicine doses.
- **Abuse protection** - 20 AI requests a minute and 300 a day per client, a 10 MB upload cap, and CORS locked to your site.

---

## Limitations

- **Not medical advice.** Every answer carries a disclaimer.
- The knowledge base (79 topics) has **not been reviewed by a clinician** - that should happen before real-world use. Answers outside it come from the model's general knowledge and are labelled as such.
- Nutrient values are rounded approximations for self-tracking.
- The app's own buttons and labels are English-only; the AI's replies follow the chosen language.
- Rate limits are counted per server instance, so the effective limit is the limit × `--max-instances`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Chat says it cannot reach the server | `API_BASE_URL` was missing when Vercel built the app - set it and **Redeploy** |
| CORS error in the browser console | `ALLOWED_ORIGINS` must exactly match your site's address, with no trailing `/` |
| "You've asked a lot of questions…" | Rate limit - wait, or raise `RATE_LIMIT_PER_MINUTE` / `RATE_LIMIT_PER_DAY` |
| `/health` shows `openai_key_configured: false` | Secret not attached - DEPLOY.md §1c step 5 |
| Deploy fails: "Permission denied on secret" | Grant `roles/secretmanager.secretAccessor` to the compute service account |
| Stuck on the confirmation-code screen | Tap **Back to sign in**; check spam for the code, or use **Send a new code** |
| Old version still showing after deploy | Hard refresh (Ctrl+Shift+R) - browsers cache the Flutter app |
| `TypeError: … unexpected keyword argument 'proxies'` | `httpx` must stay at 0.27.2 (pinned in `requirements.txt`) |
| `Stream not supported` from `record` on web | Already handled - audio is recorded as PCM16 and wrapped as WAV |

---

## Roadmap

- [x] Expand the food database (15 → ~80 foods)
- [x] Grocery list from meal plans
- [x] AI replies in 12 languages
- [x] Rate limiting and upload caps
- [x] Everyday health questions in chat, not just food
- [x] Use medical report values in answers
- [ ] Clinical review of the knowledge base, then expand it
- [ ] Translate the app's own interface
- [x] Automatic sync between devices (needs the DynamoDB setup in DEPLOY.md §2c)

---

## Disclaimer

This app does not provide medical advice. All guidance is for information only - always consult your doctor, midwife, OB-GYN, or paediatrician about your or your baby's health.
