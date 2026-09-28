import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { ArrowLeft, Loader2, ShieldAlert, CheckCircle2, AlertTriangle } from "lucide-react";

import { Footer } from "@/components/site/Footer";
import { checkSymptom } from "@/lib/pregnancy.functions";
import type { SymptomGuidance } from "@/lib/pregnancy.functions";
import { usePregnancy } from "@/hooks/use-pregnancy";
import { trimesterName } from "@/lib/pregnancy";

export const Route = createFileRoute("/symptom-checker")({
  head: () => ({
    meta: [
      { title: "Symptom Checker — Bloom" },
      {
        name: "description",
        content:
          "Describe a pregnancy symptom and get clear, informational guidance on what's typical and when to contact your care team.",
      },
      { property: "og:title", content: "Symptom Checker — Bloom" },
      {
        property: "og:description",
        content:
          "AI symptom guidance for pregnancy — what's normal versus worth a call to your midwife or doctor.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: SymptomCheckerPage,
});

function SymptomCheckerPage() {
  const { week, trimester, addSymptom } = usePregnancy();
  const check = useServerFn(checkSymptom);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [result, setResult] = useState<SymptomGuidance | null>(null);

  async function run() {
    if (!text.trim()) return;
    setLoading(true);
    setError(false);
    setResult(null);
    try {
      const guidance = await check({ data: { description: text.trim(), week } });
      setResult(guidance);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }

  function log() {
    if (!result || !text.trim()) return;
    const severity =
      result.classification === "normal"
        ? "mild"
        : result.classification === "caution"
          ? "moderate"
          : "strong";
    addSymptom({ text: text.trim(), week, severity });
  }

  return (
    <div className="mx-auto max-w-3xl px-5 pb-10 pt-4">
      <Link
        to="/"
        className="mb-5 inline-flex items-center gap-1 text-sm font-semibold text-ink/50 transition hover:text-ink"
      >
        <ArrowLeft className="size-4" /> Back to overview
      </Link>

      <header className="mb-6">
        <h1 className="font-display text-4xl font-black">Symptom checker</h1>
        <p className="mt-2 text-ink/55">
          Week {week} · {trimesterName(trimester)}. Describe how you feel and Bloom will give
          informational guidance — not a diagnosis.
        </p>
      </header>

      <div className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm">
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={4}
          placeholder="e.g. I've had a mild headache for two days, mostly in the evening…"
          className="w-full resize-none rounded-2xl bg-cream p-4 text-base ring-1 ring-ink/10 outline-none focus:ring-brand"
        />
        <div className="mt-4 flex items-center justify-between">
          <p className="text-xs text-ink/40">
            For emergencies, call your local emergency number immediately.
          </p>
          <button
            onClick={run}
            disabled={loading || !text.trim()}
            className="inline-flex items-center gap-2 rounded-full bg-brand px-6 py-3 font-bold text-white shadow-lg shadow-brand/30 transition hover:brightness-105 disabled:opacity-50"
          >
            {loading && <Loader2 className="size-4 animate-spin" />}
            {loading ? "Checking…" : "Check symptom"}
          </button>
        </div>
      </div>

      {error && (
        <div className="mt-6 rounded-[28px] bg-coral-soft p-6 ring-1 ring-coral/20">
          <p className="font-display text-lg font-bold text-coral">
            We couldn't assess that just now.
          </p>
          <p className="mt-1 text-sm text-ink/60">Please try again shortly.</p>
        </div>
      )}

      {result && (
        <ResultCard guidance={result} onLog={log} logged={false} />
      )}
    </div>
  );
}

function ResultCard({
  guidance,
  onLog,
}: {
  guidance: SymptomGuidance;
  onLog: () => void;
  logged: boolean;
}) {
  const config = {
    normal: {
      icon: CheckCircle2,
      tone: "text-emerald-700 bg-mint-soft",
      ring: "ring-emerald-200",
      label: "Likely typical",
    },
    caution: {
      icon: AlertTriangle,
      tone: "text-amber bg-amber-soft",
      ring: "ring-amber-200",
      label: "Worth monitoring",
    },
    "seek-care": {
      icon: ShieldAlert,
      tone: "text-coral bg-coral-soft",
      ring: "ring-coral/30",
      label: "Contact your care team",
    },
  }[guidance.classification];

  const Icon = config.icon;

  return (
    <div className={`mt-6 rounded-[28px] bg-white p-6 ring-1 ${config.ring} shadow-sm`}>
      <div className="flex items-center gap-3">
        <span className={`grid size-10 place-items-center rounded-xl ${config.tone}`}>
          <Icon className="size-5" />
        </span>
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-ink/45">
            {guidance.label ?? config.label}
          </p>
          <h2 className="font-display text-xl font-bold">{config.label}</h2>
        </div>
      </div>

      <p className="mt-4 leading-relaxed text-ink/70">{guidance.explanation}</p>

      {guidance.redFlags.length > 0 && (
        <div className="mt-4">
          <p className="text-xs font-bold uppercase tracking-wide text-coral">Seek care if</p>
          <ul className="mt-2 space-y-1">
            {guidance.redFlags.map((f, i) => (
              <li key={i} className="flex gap-2 text-sm text-ink/70">
                <span className="text-coral">•</span>
                {f}
              </li>
            ))}
          </ul>
        </div>
      )}

      <p className="mt-4 rounded-xl bg-cream p-3 text-sm text-ink/60">
        <span className="font-semibold text-ink/80">When to call: </span>
        {guidance.whenToCall}
      </p>

      <button
        onClick={onLog}
        className="mt-4 inline-flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-bold text-white transition hover:bg-ink/90"
      >
        Log to my tracker
      </button>
    </div>
  );
}
