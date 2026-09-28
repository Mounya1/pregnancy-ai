import { useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { RefreshCw } from "lucide-react";

import { Shimmer } from "@/components/ai-elements/shimmer";
import { getWeekInsights } from "@/lib/pregnancy.functions";
import { usePregnancy } from "@/hooks/use-pregnancy";

export function InsightCards() {
  const { week } = usePregnancy();
  const fetchInsights = useServerFn(getWeekInsights);
  const { data, isLoading, isError, refetch, isFetching } = useQuery({
    queryKey: ["bloom", "insights", week],
    queryFn: () => fetchInsights({ data: { week } }),
  });

  return (
    <section>
      <div className="mb-3 flex items-center justify-between">
        <div>
          <h2 className="font-display text-2xl font-black">Week-by-week insights</h2>
          <p className="text-sm text-ink/45">AI-generated for week {week}</p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="inline-flex items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-bold text-brand ring-1 ring-ink/5 transition hover:bg-ink/5 disabled:opacity-50"
        >
          <RefreshCw className={isFetching ? "size-4 animate-spin" : "size-4"} />
          Refresh
        </button>
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2">
          {[0, 1].map((i) => (
            <div
              key={i}
              className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm"
            >
              <Shimmer className="text-sm">Generating clinical insight…</Shimmer>
            </div>
          ))}
        </div>
      ) : isError ? (
        <div className="rounded-[28px] bg-coral-soft p-6 ring-1 ring-coral/20">
          <p className="font-display text-lg font-bold text-coral">
            We couldn't generate insights right now.
          </p>
          <p className="mt-1 text-sm text-ink/60">
            Please try again in a moment.
          </p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {data?.map((insight, i) => (
            <div
              key={i}
              className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-[11px] font-medium uppercase tracking-[0.12em] text-brand">
                <span className="size-1.5 rounded-full bg-brand" />
                {i === 0 ? "Development" : "Your body"}
              </div>
              <h3 className="mt-3 font-display text-lg font-bold">{insight.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-ink/60">{insight.body}</p>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
