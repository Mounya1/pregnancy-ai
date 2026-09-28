import { usePregnancy } from "@/hooks/use-pregnancy";
import { trimesterName } from "@/lib/pregnancy";

export function GrowthCard() {
  const { week, trimester, weeksLeft, progress, weekData } = usePregnancy();

  const stats = [
    { label: "Length", value: `${weekData.lengthCm} cm` },
    { label: "Weight", value: `${weekData.weightG} g` },
    { label: "Fundal height", value: `${week} cm` },
    { label: "Heart rate", value: "140 bpm" },
  ];

  return (
    <div className="rounded-[28px] bg-white p-6 shadow-xl shadow-ink/5 ring-1 ring-ink/5">
      <div className="flex items-center justify-between">
        <h2 className="font-display text-xl font-bold">Growth this week</h2>
        <span className="rounded-full bg-mint-soft px-3 py-1 text-xs font-bold text-emerald-700">
          On track
        </span>
      </div>

      <div className="mt-5 grid grid-cols-2 gap-3">
        {stats.map((s) => (
          <div key={s.label} className="rounded-2xl bg-cream p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-ink/45">
              {s.label}
            </p>
            <p className="mt-1 font-display text-3xl font-black">{s.value}</p>
          </div>
        ))}
      </div>

      <div className="mt-5">
        <div className="flex items-center justify-between text-xs font-semibold text-ink/45">
          <span>{trimesterName(trimester)}</span>
          <span>{weeksLeft} weeks left</span>
        </div>
        <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-cream">
          <div
            className="h-full rounded-full bg-brand transition-all"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      <div className="mt-4 rounded-2xl bg-brand-soft p-4">
        <p className="text-xs font-bold uppercase tracking-wide text-brand">This week</p>
        <p className="mt-1 text-sm leading-relaxed text-ink/70">{weekData.note}</p>
      </div>
    </div>
  );
}
