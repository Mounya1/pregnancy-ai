import { useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";

import { Shimmer } from "@/components/ai-elements/shimmer";
import { getPersonalizedTips } from "@/lib/pregnancy.functions";
import { usePregnancy } from "@/hooks/use-pregnancy";
import { cn } from "@/lib/utils";

const accentByCategory: Record<string, string> = {
  Nutrition: "text-mint",
  Movement: "text-coral",
  Wellness: "text-amber",
};

export function WellnessTips() {
  const { week } = usePregnancy();
  const fetchTips = useServerFn(getPersonalizedTips);
  const { data, isLoading } = useQuery({
    queryKey: ["bloom", "tips", week],
    queryFn: () => fetchTips({ data: { week } }),
  });

  return (
    <div className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm">
      <div className="size-12 grid place-items-center rounded-2xl bg-mint-soft text-2xl">
        🌿
      </div>
      <h3 className="mt-4 font-display text-xl font-bold">Wellness tips</h3>
      <p className="mt-1 text-sm leading-relaxed text-ink/55">
        Personalised to your week and profile.
      </p>

      {isLoading ? (
        <div className="mt-4">
          <Shimmer className="text-sm">Tailoring your tips…</Shimmer>
        </div>
      ) : (
        <ul className="mt-4 space-y-2">
          {data?.map((tip, i) => (
            <li key={i} className="flex gap-2 text-sm leading-relaxed">
              <span className={cn("font-bold", accentByCategory[tip.category] ?? "text-mint")}>
                ✓
              </span>
              <span>
                <span className="font-semibold text-ink/80">{tip.category}:</span>{" "}
                <span className="text-ink/60">{tip.tip}</span>
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
