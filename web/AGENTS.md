<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

# Bloom — Architecture Decisions

## Stack
TanStack Start v1 (React 19) on Cloudflare Workers. Tailwind v4 via `src/styles.css` tokens (no tailwind.config). No backend database — the app is account-free and local-first.

## AI / Lovable AI Gateway
- All server-side chat/text calls use model `openai/gpt-6-astra` via the OpenAI Responses provider (`@ai-sdk/openai`) against the Lovable AI Gateway (`https://ai.gateway.lovable.dev`). Do not swap the model without an explicit user request. `LOVABLE_API_KEY` is read inside `.handler()`/route handlers only.
- AI helpers live in `src/lib/ai/*.server.ts` (server-only) and `src/lib/pregnancy.server.ts`; TanStack server functions in `src/lib/pregnancy.functions.ts` wrap the one-shot features for client RPC.
- Streaming chat is a server route `src/routes/api/chat.ts` returning the AI SDK UI-message stream (SSE). The client uses `useChat` + `DefaultChatTransport` from `@ai-sdk/react`/`ai`. Never call the gateway from the browser.

## Data & persistence
- No accounts. Pregnancy profile (due date), appointments, and symptom log are stored in `localStorage` via `src/hooks/use-pregnancy.tsx` (`PregnancyProvider`). Server functions receive week/trimester context per request.

## Routing
- `src/routes/index.tsx` = dashboard. `/assistant` = AI chat. `/symptom-checker` = symptom guidance. `__root.tsx` wraps everything in `QueryClientProvider` + `PregnancyProvider` + global `Header` and mounts the `sonner` Toaster.
- Head metadata is per-leaf-route (title/description/og). `__root` holds font `<link>`s and the favicon.

## Assets / branding
- Generated imagery: `src/assets/hero.png`, `src/assets/bloom-logo.png`. Favicon is `public/favicon.png` (64×64 padded downscale of the logo); `public/favicon.ico` was deleted.
- Visual direction: "Playful clinical" — Fraunces display + DM Sans body, purple brand + coral/mint/amber accents on cream. Clinical, expert medical tone across all AI prompts and copy.
