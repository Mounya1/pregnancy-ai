/**
 * Server-only one-shot AI features for Bloom.
 *
 * These used to call the Lovable AI Gateway directly with a key held by this
 * web host. They now call the project's own API, which holds the model key and
 * the clinical prompts - see ai/backend.server.ts for why.
 *
 * The exported types and signatures are unchanged, so the components that use
 * them did not need touching. What changed is where the answer comes from.
 */
import { getJson, postJson } from "./ai/backend.server";
import { getWeekData } from "./pregnancy";

export interface WeekInsight {
  title: string;
  body: string;
}

/** Week-by-week insights: development + what to watch this week. */
export async function generateInsights(week: number): Promise<WeekInsight[]> {
  try {
    const res = await getJson<{ insights: WeekInsight[] }>(
      `/assistant/insights?week=${week}`,
    );
    if (res.insights?.length) return res.insights;
  } catch {
    // Fall through to the local week data below.
  }

  // The app ships week-by-week reference text, so an unreachable backend costs
  // the generated phrasing rather than the screen.
  const data = getWeekData(week);
  return [
    { title: `Development at week ${week}`, body: data.note },
    {
      title: "Your body this week",
      body: "As blood volume rises, watch hydration, rest, and any new symptoms worth noting at your next visit.",
    },
  ];
}

export type SymptomClassification = "normal" | "caution" | "seek-care";

export interface SymptomGuidance {
  classification: SymptomClassification;
  label: string;
  explanation: string;
  redFlags: string[];
  whenToCall: string;
}

interface SymptomGuidanceWire {
  classification: SymptomClassification;
  label: string;
  explanation: string;
  red_flags: string[];
  when_to_call: string;
}

export async function generateSymptomGuidance(
  description: string,
  week: number,
): Promise<SymptomGuidance> {
  try {
    const wire = await postJson<SymptomGuidanceWire>("/assistant/symptom", {
      description,
      week,
    });
    return {
      classification: wire.classification,
      label: wire.label,
      explanation: wire.explanation,
      redFlags: wire.red_flags ?? [],
      whenToCall: wire.when_to_call,
    };
  } catch {
    // A failure must not read as reassurance, so the fallback is the cautious
    // one that sends the user to a person rather than "probably fine".
    return {
      classification: "caution",
      label: "Could not assess this right now",
      explanation:
        "The assistant could not review this symptom. That is a problem with the service, not a judgement about the symptom.",
      redFlags: [],
      whenToCall:
        "If you are worried about this symptom, contact your midwife or doctor rather than waiting for the assistant.",
    };
  }
}

export interface WellnessTip {
  category: "Nutrition" | "Movement" | "Wellness";
  tip: string;
}

// A tuple, not an array: indexing it gives a definite category rather than
// `category | undefined` under noUncheckedIndexedAccess.
const TIP_CATEGORIES = ["Nutrition", "Movement", "Wellness"] as const;

export async function generatePersonalizedTips(
  week: number,
  profile?: string,
): Promise<WellnessTip[]> {
  try {
    const res = await postJson<{ tips: Array<{ title: string; body: string }> }>(
      "/assistant/tips",
      { week, profile },
    );
    const tips: WellnessTip[] = (res.tips ?? [])
      .map((t, i) => ({
        // The API returns title/body; this UI is built around a fixed set of
        // three categories, so the title is matched to one rather than
        // trusted to be exactly right. Position is the fallback, which is why
        // the backend is asked for them in that order.
        category:
          TIP_CATEGORIES.find(
            (c) => c.toLowerCase() === t.title?.trim().toLowerCase(),
          ) ?? TIP_CATEGORIES[i % 3]!,
        tip: t.body,
      }))
      .filter((t) => t.tip);
    if (tips.length) return tips;
  } catch {
    // Fall through.
  }

  return [
    { category: "Nutrition", tip: "Prioritise iron-rich foods to support rising blood volume." },
    { category: "Movement", tip: "Low-impact walking most days is well supported." },
    { category: "Wellness", tip: "Aim for 7-9 hours of sleep; side-lying eases back pressure." },
  ];
}
