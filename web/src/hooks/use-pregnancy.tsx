import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import {
  clampWeek,
  getWeekData,
  progressPercent,
  trimesterOf,
  weekFromDueDate,
  weeksLeftFromDueDate,
} from "@/lib/pregnancy";

export interface PregnancyProfile {
  dueDate: string; // ISO yyyy-mm-dd
}

export interface Appointment {
  id: string;
  title: string;
  date: string; // ISO yyyy-mm-dd
  time: string;
  provider?: string;
}

export interface SymptomEntry {
  id: string;
  text: string;
  week: number;
  severity: "mild" | "moderate" | "strong";
  createdAt: number;
}

export type MoodValue = "great" | "good" | "okay" | "low" | "rough";
export type MovementValue = "none" | "sparse" | "normal" | "active";

export interface DailySymptom {
  text: string;
  severity: "mild" | "moderate" | "strong";
}

export interface DailyLog {
  date: string; // yyyy-mm-dd
  mood: MoodValue;
  weightKg?: number;
  movement: MovementValue;
  movementNotes?: string;
  notes?: string;
  symptoms: DailySymptom[];
  updatedAt: number;
}

interface PregnancyContextValue {
  ready: boolean;
  profile: PregnancyProfile | null;
  week: number;
  trimester: 1 | 2 | 3;
  weeksLeft: number;
  progress: number;
  weekData: ReturnType<typeof getWeekData>;
  appointments: Appointment[];
  symptoms: SymptomEntry[];
  dailyLogs: DailyLog[];
  setDueDate: (iso: string) => void;
  clearProfile: () => void;
  addAppointment: (a: Omit<Appointment, "id">) => void;
  removeAppointment: (id: string) => void;
  addSymptom: (s: Omit<SymptomEntry, "id" | "createdAt">) => void;
  removeSymptom: (id: string) => void;
  saveDailyLog: (log: Omit<DailyLog, "updatedAt">) => void;
  getDailyLog: (date: string) => DailyLog | undefined;
}

const PROFILE_KEY = "bloom.profile.v1";
const APPTS_KEY = "bloom.appointments.v1";
const SYMPTOMS_KEY = "bloom.symptoms.v1";
const DAILY_KEY = "bloom.daily.v1";

const PregnancyContext = createContext<PregnancyContextValue | null>(null);

function read<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write<T>(key: string, value: T) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* ignore quota errors */
  }
}

function uid(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function PregnancyProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [profile, setProfile] = useState<PregnancyProfile | null>(null);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [symptoms, setSymptoms] = useState<SymptomEntry[]>([]);
  const [dailyLogs, setDailyLogs] = useState<DailyLog[]>([]);

  // Hydrate after mount to avoid SSR mismatch.
  useEffect(() => {
    setProfile(read<PregnancyProfile | null>(PROFILE_KEY, null));
    setAppointments(read<Appointment[]>(APPTS_KEY, []));
    setSymptoms(read<SymptomEntry[]>(SYMPTOMS_KEY, []));
    setDailyLogs(read<DailyLog[]>(DAILY_KEY, []));
    setReady(true);
  }, []);

  const setDueDate = useCallback((iso: string) => {
    const next = { dueDate: iso };
    setProfile(next);
    write(PROFILE_KEY, next);
  }, []);

  const clearProfile = useCallback(() => {
    setProfile(null);
    write(PROFILE_KEY, null);
  }, []);

  const addAppointment = useCallback((a: Omit<Appointment, "id">) => {
    setAppointments((prev) => {
      const next = [...prev, { ...a, id: uid() }].sort((x, y) =>
        x.date.localeCompare(y.date),
      );
      write(APPTS_KEY, next);
      return next;
    });
  }, []);

  const removeAppointment = useCallback((id: string) => {
    setAppointments((prev) => {
      const next = prev.filter((a) => a.id !== id);
      write(APPTS_KEY, next);
      return next;
    });
  }, []);

  const addSymptom = useCallback((s: Omit<SymptomEntry, "id" | "createdAt">) => {
    setSymptoms((prev) => {
      const next = [{ ...s, id: uid(), createdAt: Date.now() }, ...prev];
      write(SYMPTOMS_KEY, next);
      return next;
    });
  }, []);

  const removeSymptom = useCallback((id: string) => {
    setSymptoms((prev) => {
      const next = prev.filter((s) => s.id !== id);
      write(SYMPTOMS_KEY, next);
      return next;
    });
  }, []);

  const saveDailyLog = useCallback((log: Omit<DailyLog, "updatedAt">) => {
    setDailyLogs((prev) => {
      const entry: DailyLog = { ...log, updatedAt: Date.now() };
      const next = [...prev.filter((d) => d.date !== log.date), entry].sort((x, y) =>
        x.date.localeCompare(y.date),
      );
      write(DAILY_KEY, next);
      return next;
    });
  }, []);

  const getDailyLog = useCallback(
    (date: string) => dailyLogs.find((d) => d.date === date),
    [dailyLogs],
  );

  const value = useMemo<PregnancyContextValue>(() => {
    const due = profile?.dueDate ? new Date(profile.dueDate + "T00:00:00") : null;
    const week = due ? weekFromDueDate(due) : 24;
    return {
      ready,
      profile,
      week,
      trimester: trimesterOf(week),
      weeksLeft: due ? weeksLeftFromDueDate(due) : 16,
      progress: progressPercent(week),
      weekData: getWeekData(week),
      appointments,
      symptoms,
      dailyLogs,
      setDueDate,
      clearProfile,
      addAppointment,
      removeAppointment,
      addSymptom,
      removeSymptom,
      saveDailyLog,
      getDailyLog,
    };
  }, [
    ready,
    profile,
    appointments,
    symptoms,
    dailyLogs,
    setDueDate,
    clearProfile,
    addAppointment,
    removeAppointment,
    addSymptom,
    removeSymptom,
    saveDailyLog,
    getDailyLog,
  ]);

  return <PregnancyContext.Provider value={value}>{children}</PregnancyContext.Provider>;
}

export function usePregnancy(): PregnancyContextValue {
  const ctx = useContext(PregnancyContext);
  if (!ctx) {
    throw new Error("usePregnancy must be used within a PregnancyProvider");
  }
  return ctx;
}

/** A sensible suggested due date so the onboarding input isn't blank. */
export function suggestedDueDate(now: Date = new Date()): string {
  const d = new Date(now.getTime() + 16 * 7 * 24 * 60 * 60 * 1000);
  return d.toISOString().slice(0, 10);
}

export function todayISO(now: Date = new Date()): string {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export { clampWeek };
