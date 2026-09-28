import { createFileRoute } from "@tanstack/react-router";

import { AssistantChat } from "@/components/pregnancy/AssistantChat";

export const Route = createFileRoute("/assistant")({
  head: () => ({
    meta: [
      { title: "Bloom Assistant — AI Pregnancy Chat" },
      {
        name: "description",
        content:
          "Chat with Bloom, your AI pregnancy companion, for week-aware guidance on symptoms, nutrition, and when to contact your care team.",
      },
      { property: "og:title", content: "Bloom Assistant — AI Pregnancy Chat" },
      {
        property: "og:description",
        content:
          "Ask Bloom anything about your pregnancy — informational guidance grounded in your current week.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: AssistantPage,
});

function AssistantPage() {
  return <AssistantChat />;
}
