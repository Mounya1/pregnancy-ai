import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowRight, HeartPulse, Sparkles, ShieldCheck } from "lucide-react";

export const Route = createFileRoute("/sample")({
  head: () => ({
    meta: [
      { title: "Sample Page — Bloom" },
      {
        name: "description",
        content:
          "A minimal sample page showing Bloom's design tokens, layout, and components in action.",
      },
      { property: "og:title", content: "Sample Page — Bloom" },
      {
        property: "og:description",
        content: "A minimal sample page built with the Bloom design system.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: SamplePage,
});

const FEATURES = [
  {
    icon: HeartPulse,
    title: "Care you can trust",
    body: "Clear, expert-toned guidance grounded in your current week of pregnancy.",
  },
  {
    icon: Sparkles,
    title: "AI assistance",
    body: "Ask anything, any hour, and get calm, practical answers in seconds.",
  },
  {
    icon: ShieldCheck,
    title: "Private by default",
    body: "Your details stay on this device — no account, no tracking.",
  },
];

function SamplePage() {
  return (
    <main className="mx-auto max-w-3xl px-5 py-16 sm:py-24">
      <section className="text-center">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1 text-xs font-semibold text-brand">
          <Sparkles className="size-3.5" /> Sample page
        </span>
        <h1 className="mt-5 font-display text-5xl font-black leading-[1.05] tracking-tight sm:text-6xl">
          A simpler way to feel <span className="text-brand">prepared</span>.
        </h1>
        <p className="mx-auto mt-5 max-w-xl text-lg text-ink/60">
          This is a minimal sample page showing the Bloom design system — type, spacing, color
          tokens, and a few components working together.
        </p>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Link
            to="/"
            className="inline-flex items-center gap-2 rounded-full bg-brand px-6 py-3 font-bold text-white shadow-lg shadow-brand/30 transition hover:bg-brand/90"
          >
            Back to tracker <ArrowRight className="size-4" />
          </Link>
          <Link
            to="/assistant"
            className="inline-flex items-center gap-2 rounded-full bg-white px-6 py-3 font-bold text-ink ring-1 ring-ink/10 transition hover:bg-cream"
          >
            Try the assistant
          </Link>
        </div>
      </section>

      <section className="mt-16 grid gap-5 sm:grid-cols-3">
        {FEATURES.map(({ icon: Icon, title, body }) => (
          <article
            key={title}
            className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm transition hover:shadow-md"
          >
            <span className="grid size-11 place-items-center rounded-2xl bg-brand-soft text-brand">
              <Icon className="size-5" />
            </span>
            <h2 className="mt-4 font-display text-lg font-bold">{title}</h2>
            <p className="mt-1.5 text-sm leading-relaxed text-ink/55">{body}</p>
          </article>
        ))}
      </section>

      <section className="mt-10 rounded-[28px] bg-ink p-8 text-center text-white">
        <p className="font-display text-xl font-bold">
          Edit this page at{" "}
          <code className="rounded-md bg-white/10 px-2 py-0.5 text-sm">src/routes/sample.tsx</code>
        </p>
        <p className="mt-2 text-sm text-white/60">
          A lightweight starting point — replace this content with whatever you need next.
        </p>
      </section>
    </main>
  );
}
