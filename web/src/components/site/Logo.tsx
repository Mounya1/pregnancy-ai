import { Link } from "@tanstack/react-router";

import { cn } from "@/lib/utils";
import logoSrc from "@/assets/bloom-logo.png";

interface LogoProps {
  className?: string;
  withWordmark?: boolean;
  compact?: boolean;
}

export function BloomLogo({ className, withWordmark = true, compact = false }: LogoProps) {
  return (
    <div className={cn("flex items-center gap-3", className)}>
      <img
        src={logoSrc}
        alt="Bloom logo"
        width={44}
        height={44}
        className="size-11 rounded-2xl object-contain shadow-lg shadow-brand/20"
      />
      {withWordmark && (
        <div className={cn(compact && "hidden sm:block")}>
          <p className="font-display text-xl font-black leading-none">Bloom</p>
          <p className="text-[11px] font-medium tracking-wide text-ink/50">
            AI pregnancy companion
          </p>
        </div>
      )}
    </div>
  );
}

export function LogoLink() {
  return (
    <Link to="/" aria-label="Bloom home">
      <BloomLogo />
    </Link>
  );
}

export function BloomAvatar({ className }: { className?: string }) {
  return (
    <img
      src={logoSrc}
      alt="Bloom assistant"
      width={32}
      height={32}
      className={cn("size-8 rounded-xl object-contain", className)}
    />
  );
}
