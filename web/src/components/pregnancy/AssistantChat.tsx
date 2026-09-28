import { useMemo } from "react";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import { AlertCircle, Send } from "lucide-react";

import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from "@/components/ai-elements/conversation";
import {
  Message,
  MessageContent,
  MessageResponse,
} from "@/components/ai-elements/message";
import {
  PromptInput,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
} from "@/components/ai-elements/prompt-input";
import { Shimmer } from "@/components/ai-elements/shimmer";
import { BloomAvatar } from "@/components/site/Logo";
import { usePregnancy } from "@/hooks/use-pregnancy";

const SUGGESTIONS = [
  "Is this normal?",
  "What should I eat this week?",
  "When should I call my midwife?",
];

export function AssistantChat() {
  const { ready, week, trimester, weeksLeft, profile } = usePregnancy();
  const dueDate = profile?.dueDate ?? "";

  const transport = useMemo(
    () =>
      new DefaultChatTransport({
        api: "/api/chat",
        body: { context: { week, trimester, weeksLeft, dueDate } },
      }),
    [week, trimester, weeksLeft, dueDate],
  );

  const { messages, sendMessage, status, stop, error, regenerate } = useChat({
    transport,
  });

  const busy = status === "submitted" || status === "streaming";
  const showThinking = status === "submitted";

  return (
    <div className="mx-auto flex h-[calc(100dvh-7.5rem)] max-w-3xl flex-col px-5">
      <div className="flex items-center gap-3 border-b border-ink/5 py-4">
        <BloomAvatar className="size-10 rounded-2xl bg-brand-soft p-1" />
        <div>
          <p className="font-display text-lg font-bold leading-none">Bloom Assistant</p>
          <p className="mt-1 text-xs text-ink/45">
            {ready ? `Week ${week} · Trimester ${trimester}` : ""} · Informational, not a substitute for care
          </p>
        </div>
      </div>

      <Conversation className="py-4">
        <ConversationContent className="gap-6">
          {messages.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-4 py-10 text-center">
              <BloomAvatar className="size-16 rounded-3xl bg-brand-soft p-2" />
              <div>
                <h2 className="font-display text-2xl font-black">How can I help today?</h2>
                <p className="mx-auto mt-2 max-w-sm text-sm text-ink/55">
                  Ask about symptoms, nutrition, sleep, or what's happening at your week. I'll be
                  clear about when to contact your care team.
                </p>
              </div>
              <div className="flex flex-wrap justify-center gap-2">
                {SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => sendMessage({ text: s })}
                    disabled={busy}
                    className="rounded-full bg-white px-4 py-2 text-sm font-semibold text-brand ring-1 ring-ink/5 transition hover:bg-brand-soft disabled:opacity-50"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          ) : null}

          {messages.map((m) => (
            <Message key={m.id} from={m.role}>
              {m.role === "assistant" && (
                <div className="mb-1 flex items-center gap-2">
                  <BloomAvatar className="size-7 rounded-lg bg-brand-soft p-0.5" />
                  <span className="text-xs font-semibold text-ink/45">Bloom</span>
                </div>
              )}
              <MessageContent>
                {m.parts.map((part, i) => {
                  if (part.type === "text") {
                    return <MessageResponse key={i}>{part.text}</MessageResponse>;
                  }
                  return null;
                })}
              </MessageContent>
            </Message>
          ))}

          {showThinking && (
            <Message from="assistant">
              <div className="mb-1 flex items-center gap-2">
                <BloomAvatar className="size-7 rounded-lg bg-brand-soft p-0.5" />
                <span className="text-xs font-semibold text-ink/45">Bloom</span>
              </div>
              <Shimmer className="text-sm">Thinking…</Shimmer>
            </Message>
          )}

          {error && (
            <div className="mx-auto flex items-center gap-2 rounded-2xl bg-coral-soft px-4 py-3 text-sm text-coral">
              <AlertCircle className="size-4 shrink-0" />
              <span>Something went wrong reaching the assistant.</span>
              <button
                onClick={() => regenerate()}
                className="ml-auto font-bold underline underline-offset-2"
              >
                Retry
              </button>
            </div>
          )}
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>

      <PromptInput
        onSubmit={({ text }) => {
          if (text.trim()) sendMessage({ text: text.trim() });
        }}
        className="mb-2 rounded-3xl"
      >
        <PromptInputTextarea placeholder="Ask about sleep, diet, or symptoms…" />
        <PromptInputFooter className="justify-end">
          {busy ? (
            <button
              type="button"
              onClick={() => stop()}
              className="inline-flex items-center gap-1 rounded-full bg-ink px-4 py-2 text-xs font-bold text-white"
            >
              Stop
            </button>
          ) : (
            <span className="hidden text-xs text-ink/35 sm:inline">Enter to send</span>
          )}
          <PromptInputSubmit status={status} disabled={busy && !showThinking}>
            <Send className="size-4" />
          </PromptInputSubmit>
        </PromptInputFooter>
      </PromptInput>
    </div>
  );
}
