import { useState } from "react";
import { Plus, Trash2, CalendarDays } from "lucide-react";

import { usePregnancy, type Appointment } from "@/hooks/use-pregnancy";
import { Button } from "@/components/ui/button";

const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

function DateBadge({ iso }: { iso: string }) {
  const d = new Date(iso + "T00:00:00");
  return (
    <div className="grid size-11 shrink-0 place-items-center rounded-lg bg-amber-soft text-center">
      <p className="text-[10px] font-bold text-amber">{MONTHS[d.getMonth()]}</p>
      <p className="font-display text-lg font-black leading-none text-amber">{d.getDate()}</p>
    </div>
  );
}

export function Appointments() {
  const { appointments, addAppointment, removeAppointment } = usePregnancy();
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [date, setDate] = useState("");
  const [time, setTime] = useState("10:00");
  const [provider, setProvider] = useState("");

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim() || !date) return;
    addAppointment({ title: title.trim(), date, time, provider: provider.trim() || undefined });
    setTitle("");
    setDate("");
    setProvider("");
    setOpen(false);
  }

  return (
    <div className="rounded-[28px] bg-white p-6 ring-1 ring-ink/5 shadow-sm">
      <div className="flex items-center justify-between">
        <h3 className="font-display text-xl font-bold">Appointments</h3>
        <button
          onClick={() => setOpen((o) => !o)}
          className="inline-flex items-center gap-1 rounded-full bg-amber-soft px-3 py-1.5 text-xs font-bold text-amber transition hover:brightness-105"
        >
          <Plus className="size-3.5" /> Add
        </button>
      </div>

      {open && (
        <form
          onSubmit={submit}
          className="mt-4 space-y-2 rounded-2xl bg-cream p-3"
        >
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Appointment (e.g. Growth scan)"
            className="w-full rounded-lg bg-white px-3 py-2 text-sm ring-1 ring-ink/10 outline-none focus:ring-brand"
          />
          <div className="flex gap-2">
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="flex-1 rounded-lg bg-white px-3 py-2 text-sm ring-1 ring-ink/10 outline-none focus:ring-brand"
            />
            <input
              type="time"
              value={time}
              onChange={(e) => setTime(e.target.value)}
              className="rounded-lg bg-white px-3 py-2 text-sm ring-1 ring-ink/10 outline-none focus:ring-brand"
            />
          </div>
          <input
            value={provider}
            onChange={(e) => setProvider(e.target.value)}
            placeholder="Provider (optional)"
            className="w-full rounded-lg bg-white px-3 py-2 text-sm ring-1 ring-ink/10 outline-none focus:ring-brand"
          />
          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" size="sm" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" size="sm">
              Save
            </Button>
          </div>
        </form>
      )}

      <div className="mt-4 space-y-2">
        {appointments.length === 0 ? (
          <div className="flex items-center gap-3 rounded-xl bg-cream px-3 py-4 text-sm text-ink/45">
            <CalendarDays className="size-5 text-ink/30" />
            No appointments yet. Add your next scan or visit.
          </div>
        ) : (
          appointments.map((a: Appointment) => (
            <div
              key={a.id}
              className="group flex items-center gap-3 rounded-xl bg-cream px-3 py-2"
            >
              <DateBadge iso={a.date} />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold">{a.title}</p>
                <p className="text-xs text-ink/45">
                  {a.provider ? `${a.provider} · ` : ""}
                  {a.time}
                </p>
              </div>
              <button
                onClick={() => removeAppointment(a.id)}
                className="text-ink/30 opacity-0 transition hover:text-coral group-hover:opacity-100"
                aria-label="Remove appointment"
              >
                <Trash2 className="size-4" />
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
