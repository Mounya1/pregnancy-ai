import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";

import { Footer } from "@/components/site/Footer";
import { Onboarding } from "@/components/site/Onboarding";
import { Hero } from "@/components/pregnancy/Hero";
import { GrowthCard } from "@/components/pregnancy/GrowthCard";
import { InsightCards } from "@/components/pregnancy/InsightCards";
import { WellnessTips } from "@/components/pregnancy/WellnessTips";
import { Appointments } from "@/components/pregnancy/Appointments";
import { SymptomPreview } from "@/components/pregnancy/SymptomPreview";
import { AssistantPromo } from "@/components/pregnancy/AssistantPromo";
import { usePregnancy } from "@/hooks/use-pregnancy";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Bloom — AI Pregnancy Companion" },
      {
        name: "description",
        content:
          "Track your pregnancy week by week with Bloom: AI week-by-week insights, a symptom checker, personalised wellness tips, and an always-on AI assistant.",
      },
      { property: "og:title", content: "Bloom — AI Pregnancy Companion" },
      {
        property: "og:description",
        content:
          "An AI-powered, clinical pregnancy tracker with week-by-week insights, symptom guidance, and a 24/7 AI assistant.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: DashboardPage,
});

function DashboardPage() {
  const { ready, profile } = usePregnancy();
  const [setupOpen, setSetupOpen] = useState(false);

  useEffect(() => {
    if (ready && !profile) setSetupOpen(true);
  }, [ready, profile]);

  return (
    <>
      <Onboarding open={setupOpen} onOpenChange={setSetupOpen} />

      <Hero onEditProfile={() => setSetupOpen(true)} />

      <section className="mx-auto max-w-6xl px-5 pb-6">
        <div className="grid gap-6 lg:grid-cols-12">
          <div className="lg:col-span-7">
            <InsightCards />
          </div>
          <div className="lg:col-span-5">
            <GrowthCard />
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-5 pb-8">
        <h2 className="mb-5 font-display text-3xl font-black">Your week, at a glance</h2>
        <div className="grid gap-5 md:grid-cols-3">
          <SymptomPreview />
          <WellnessTips />
          <Appointments />
        </div>
      </section>

      <AssistantPromo />

      <Footer />
    </>
  );
}
