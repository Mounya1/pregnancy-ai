/**
 * Streaming chat handler for the Bloom assistant. Server-only, via /api/chat.
 *
 * The answer is produced by the project's own API, which holds the model key
 * and the clinical system prompt. This file's job is translation: the backend
 * streams plain text, the browser speaks the AI SDK's UI-message protocol, and
 * neither should have to know about the other.
 *
 * The prompt deliberately does NOT live here. It lived here when this app
 * called a model gateway directly, and keeping a second copy alongside the
 * backend's would mean two sets of clinical guardrails drifting apart.
 */
import { createUIMessageStream, createUIMessageStreamResponse, type UIMessage } from "ai";

import { backendBaseUrl } from "./backend.server";

export interface ChatContext {
  week?: number;
  trimester?: number;
  weeksLeft?: number;
  dueDate?: string;
}

/** The subset of a UIMessage the backend needs: who said it, and what. */
function flatten(messages: UIMessage[]) {
  return messages
    .map((m) => ({
      role: m.role === "assistant" ? "assistant" : "user",
      content: (m.parts ?? [])
        .filter((p): p is { type: "text"; text: string } => p.type === "text")
        .map((p) => p.text)
        .join(""),
    }))
    .filter((m) => m.content.trim().length > 0);
}

export async function handleChat(request: Request): Promise<Response> {
  let body: { messages?: UIMessage[]; context?: ChatContext };
  try {
    body = await request.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body." }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  const messages = flatten(body.messages ?? []);
  const ctx = body.context ?? {};

  let upstream: Response;
  try {
    upstream = await fetch(`${backendBaseUrl()}/assistant/chat/stream`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      signal: request.signal,
      body: JSON.stringify({
        messages,
        context: {
          week: ctx.week,
          trimester: ctx.trimester,
          weeks_left: ctx.weeksLeft,
          due_date: ctx.dueDate,
        },
      }),
    });
  } catch {
    return new Response(
      JSON.stringify({ error: "The assistant is unreachable right now." }),
      { status: 502, headers: { "content-type": "application/json" } },
    );
  }

  if (!upstream.ok || !upstream.body) {
    return new Response(
      JSON.stringify({ error: "The assistant could not answer right now." }),
      { status: 502, headers: { "content-type": "application/json" } },
    );
  }

  const stream = createUIMessageStream({
    execute: async ({ writer }) => {
      const id = "0";
      writer.write({ type: "text-start", id });

      const reader = upstream.body!.getReader();
      const decoder = new TextDecoder();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const delta = decoder.decode(value, { stream: true });
          if (delta) writer.write({ type: "text-delta", id, delta });
        }
        // Flush whatever the decoder was holding for a split multi-byte
        // character, or an answer ending mid-emoji loses its last glyph.
        const tail = decoder.decode();
        if (tail) writer.write({ type: "text-delta", id, delta: tail });
      } finally {
        reader.releaseLock();
        writer.write({ type: "text-end", id });
      }
    },
    onError: () => "The assistant stopped part-way through. Please try again.",
  });

  return createUIMessageStreamResponse({ stream });
}
