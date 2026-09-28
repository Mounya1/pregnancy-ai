import { Link } from "@tanstack/react-router";
import { Pencil, Sparkles } from "lucide-react";

import { usePregnancy } from "@/hooks/use-pregnancy";
import { trimesterName } from "@/lib/pregnancy";
import heroImg from "@/assets/hero.png";

export function Hero({ onEditProfile }: { onEditProfile: () => void }) {
  const { ready, week, trimester, weeksLeft, weekData, profile } = usePregnancy();

  return (
    <section className="mx-auto max-w-6xl px-5 pb-10 pt-4">
      <div className="grid items-center gap-8 lg:grid-cols-12">
        <div className="lg:col-span-7">
          <span className="inline-flex items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-semibold shadow-sm ring-1 ring-ink/5">
            <span className="size-2 rounded-full bg-mint" />
            {ready ? `Week ${week} · ${trimesterName(trimester)}` : "Loading your week…"}
          </span>

          <h1 className="mt-5 font-display text-[clamp(2.75rem,7vw,5.25rem)] font-black leading-[0.92] text-balance">
            Your baby is
            <br />
            <span className="text-brand">the size of</span>
            <br />
            <span className="text-coral">{weekData.comparison}.</span>
          </h1>

          <p className="mt-6 max-w-md text-lg leading-relaxed text-ink/60">
            {ready ? (
              <>
                You're {week} weeks along — about {weeksLeft} weeks to go. Your baby is
                roughly {weekData.lengthCm} cm and {weekData.weightG} g, and {weekData.note.toLowerCase()}
              </>
            ) : (
              "Set your due date to see personalised week-by-week insights, symptom guidance, and AI support."
            )}
          </p>

          <div className="mt-7 flex flex-wrap gap-3">
            <Link
              to="/symptom-checker"
              className="rounded-full bg-brand px-6 py-4 font-bold text-white shadow-lg shadow-brand/30 transition hover:brightness-105"
            >
              Log today's symptoms
            </Link>
            <Link
              to="/assistant"
              className="inline-flex items-center gap-2 rounded-full bg-white px-6 py-4 font-bold text-ink ring-1 ring-ink/10 transition hover:bg-ink/5"
            >
              <Sparkles className="size-4 text-coral" />
              Ask Bloom
            </Link>
            {ready && profile && (
              <button
                onClick={onEditProfile}
                className="inline-flex items-center gap-2 rounded-full px-4 py-4 text-sm font-semibold text-ink/50 transition hover:text-ink"
              >
                <Pencil className="size-4" />
                Edit due date
              </button>
            )}
          </div>
        </div>

        <div className="lg:col-span-5">
          <img
            src={heroImg}
            alt="An abstract, warm illustration representing pregnancy"
            width={1200}
            height={1008}
            className="w-full rounded-[28px] object-cover shadow-2xl shadow-ink/10 ring-1 ring-ink/5"
          />
        </div>
      </div>
    </section>
  );
}
