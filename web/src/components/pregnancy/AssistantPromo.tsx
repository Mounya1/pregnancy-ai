import { Link } from "@tanstack/react-router";
import { ArrowRight } from "lucide-react";

import { BloomAvatar } from "@/components/site/Logo";

export function AssistantPromo() {
  return (
    <section className="mx-auto max-w-6xl px-5 pb-16">
      <div className="grid items-center gap-8 rounded-[32px] bg-ink p-7 text-white md:grid-cols-2 md:p-9">
        <div>
          <span className="inline-block rounded-full bg-white/10 px-3 py-1 text-xs font-bold tracking-wide">
            AI ASSISTANT
          </span>
          <h2 className="mt-4 font-display text-4xl font-black leading-tight">
            Ask Bloom anything, any hour.
          </h2>
          <p className="mt-3 max-w-sm leading-relaxed text-white/60">
            From “is this normal?” to “what should I eat?” — grounded in your current week,
            with clear guidance on when to contact your care team.
          </p>
          <Link
            to="/assistant"
            className="mt-6 inline-flex items-center gap-2 rounded-full bg-coral px-6 py-3 font-bold text-white shadow-lg shadow-coral/30 transition hover:brightness-105"
          >
            Open assistant <ArrowRight className="size-4" />
          </Link>
        </div>

        <div className="space-y-3">
          <div className="flex justify-end">
            <p className="max-w-[80%] rounded-2xl rounded-br-md bg-brand px-4 py-3 text-sm">
              My legs feel heavy at night, is that normal?
            </p>
          </div>
          <div className="flex items-end gap-2">
            <BloomAvatar className="shrink-0 bg-white/10 p-0.5" />
            <p className="max-w-[85%] rounded-2xl rounded-bl-md bg-white/10 px-4 py-3 text-sm">
              Common as blood volume rises. Try elevation and an evening walk. If swelling is
              sudden or one-sided, message your midwife.
            </p>
          </div>
          <div className="flex items-center gap-2 rounded-full bg-white/5 px-4 py-3">
            <span className="text-sm text-white/40">Ask about sleep, diet, or symptoms…</span>
            <span className="ml-auto grid size-8 place-items-center rounded-full bg-coral font-bold text-white">
              ↑
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
