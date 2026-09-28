/**
 * Client-callable server functions for Bloom's one-shot AI features.
 * Client code imports these; they delegate to server-only modules.
 */
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

import {
  generateInsights,
  generateSymptomGuidance,
  generatePersonalizedTips,
  type WeekInsight,
  type SymptomGuidance,
  type WellnessTip,
} from "./pregnancy.server";

export const getWeekInsights = createServerFn({ method: "GET" })
  .inputValidator((data) => z.object({ week: z.number() }).parse(data))
  .handler(async ({ data }) => generateInsights(data.week));

export const checkSymptom = createServerFn({ method: "POST" })
  .inputValidator((data) =>
    z.object({ description: z.string(), week: z.number() }).parse(data),
  )
  .handler(async ({ data }) => generateSymptomGuidance(data.description, data.week));

export const getPersonalizedTips = createServerFn({ method: "POST" })
  .inputValidator((data) =>
    z
      .object({ week: z.number(), profile: z.string().optional() })
      .parse(data),
  )
  .handler(async ({ data }) => generatePersonalizedTips(data.week, data.profile));

export type { WeekInsight, SymptomGuidance, WellnessTip };
