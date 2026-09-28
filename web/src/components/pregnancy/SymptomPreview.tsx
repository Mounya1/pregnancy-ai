import { Link } from "@tanstack/react-router";
import { ArrowRight } from "lucide-react";

import { usePregnancy } from "@/hooks/use-pregnancy";

const severityStyle: Record<string, string> = {
  mild: "bg-mint-soft text-emerald-700",
  moderate: "bg-amber-soft text-amber",
  strong: "bg-coral-soft text-coral",
};

export function SymptomPreview() {
  const { symptoms, week } = usePregnancy();
  const recent = symptoms.slice(0, 3);

  return (
    <div className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm">
      <div className="size-12 grid place-items-center rounded-2xl bg-coral-soft text-2xl">🩺</div>
      <h3 className="mt-4 font-display text-xl font-bold">Symptom checker</h3>
      <p className="mt-1 text-sm leading-relaxed text-ink/55">
        Describe how you feel and get guidance on what's typical vs. worth a call.
      </p>

      <div className="mt-4 space-y-2">
        {recent.length === 0 ? (
          <p className="rounded-xl bg-cream px-3 py-2 text-sm text-ink/45">
            Nothing logged yet this week.
          </p>
        ) : (
          recent.map((s) => (
            <div
              key={s.id}
              className="flex items-center justify-between rounded-xl bg-cream px-3 py-2"
            >
              <span className="truncate text-sm font-semibold">{s.text}</span>
              <span
                className={`ml-2 shrink-0 rounded-full px-2 py-0.5 text-xs font-bold capitalize ${
                  severityStyle[s.severity] ?? severityStyle.mild
                }`}
              >
                {s.severity}
              </span>
            </div>
          ))
        )}
      </div>

      <Link
        to="/symptom-checker"
        className="mt-4 inline-flex items-center gap-2 text-sm font-bold text-brand transition hover:gap-3"
      >
        Check a symptom <ArrowRight className="size-4" />
      </Link>
      <span className="ml-2 text-xs text-ink/35">Week {week}</span>
    </div>
  );
}
