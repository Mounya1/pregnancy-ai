import { Link } from "@tanstack/react-router";
import { Stethoscope, CalendarDays, MessageCircle } from "lucide-react";

import { BloomLogo } from "@/components/site/Logo";
import { usePregnancy } from "@/hooks/use-pregnancy";
import { cn } from "@/lib/utils";

const navItems = [
  { to: "/", label: "Overview", icon: null },
  { to: "/symptom-checker", label: "Symptoms", icon: Stethoscope },
  { to: "/assistant", label: "Assistant", icon: MessageCircle },
] as const;

export function Header() {
  const { ready, week, trimester } = usePregnancy();

  return (
    <header className="mx-auto flex max-w-6xl items-center justify-between px-5 pt-6 pb-4">
      <BloomLogo />

      <nav className="hidden items-center gap-1 rounded-full bg-white p-1 shadow-sm ring-1 ring-ink/5 md:flex">
        {navItems.map((item) => (
          <NavLink key={item.to} to={item.to} label={item.label} />
        ))}
      </nav>

      <div className="flex items-center gap-3">
        {ready && (
          <span className="hidden items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-semibold ring-1 ring-ink/5 shadow-sm sm:inline-flex">
            <CalendarDays className="size-4 text-brand" />
            Week {week} · T{trimester}
          </span>
        )}
        <Link
          to="/assistant"
          className="rounded-full bg-coral px-5 py-3 text-sm font-bold text-white shadow-lg shadow-coral/30 transition hover:brightness-105"
        >
          Ask Bloom
        </Link>
      </div>
    </header>
  );
}

function NavLink({ to, label }: { to: string; label: string }) {
  return (
    <Link
      to={to}
      className="rounded-full px-4 py-2 text-sm font-semibold text-ink/60 transition hover:text-ink"
      activeProps={{ className: cn("bg-ink text-white hover:text-white") }}
      activeOptions={{ exact: to === "/" }}
    >
      {label}
    </Link>
  );
}
