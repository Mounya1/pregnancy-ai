import { useEffect, useState } from "react";
import { CalendarHeart } from "lucide-react";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { BloomLogo } from "@/components/site/Logo";
import { suggestedDueDate, usePregnancy } from "@/hooks/use-pregnancy";

interface OnboardingProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function Onboarding({ open, onOpenChange }: OnboardingProps) {
  const { profile, setDueDate } = usePregnancy();
  const [date, setDate] = useState("");

  useEffect(() => {
    if (open) setDate(profile?.dueDate || suggestedDueDate());
  }, [open, profile?.dueDate]);

  function save() {
    if (!date) return;
    setDueDate(date);
    onOpenChange(false);
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md rounded-[28px] p-8">
        <div className="flex flex-col items-center text-center">
          <BloomLogo withWordmark={false} className="mb-4" />
          <DialogHeader className="items-center">
            <div className="mb-2 grid size-12 place-items-center rounded-2xl bg-brand-soft text-brand">
              <CalendarHeart className="size-6" />
            </div>
            <DialogTitle className="font-display text-2xl font-black">
              {profile ? "Update your due date" : "Welcome to Bloom"}
            </DialogTitle>
            <DialogDescription className="text-ink/55">
              {profile
                ? "Adjust your estimated due date to keep your week-by-week guidance accurate."
                : "Tell us your estimated due date and we'll personalise your tracker."}
            </DialogDescription>
          </DialogHeader>
        </div>

        <div className="mt-6">
          <label className="text-xs font-semibold uppercase tracking-wide text-ink/45">
            Estimated due date
          </label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="mt-2 w-full rounded-xl bg-cream px-4 py-3 text-base ring-1 ring-ink/10 outline-none focus:ring-brand"
          />
          <p className="mt-2 text-xs text-ink/40">
            Saved only on this device. Bloom never replaces your midwife or doctor.
          </p>
        </div>

        <DialogFooter className="mt-6 sm:justify-center">
          <Button
            onClick={save}
            disabled={!date}
            className="w-full rounded-full bg-brand px-6 py-6 text-base font-bold shadow-lg shadow-brand/30 hover:bg-brand/90"
          >
            {profile ? "Save date" : "Start tracking"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
