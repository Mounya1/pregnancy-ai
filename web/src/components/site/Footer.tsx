import { usePregnancy } from "@/hooks/use-pregnancy";

export function Footer() {
  const { ready } = usePregnancy();
  return (
    <footer className="mx-auto max-w-6xl px-5 pb-10 pt-6 text-center">
      <p className="mx-auto max-w-2xl text-xs leading-relaxed text-ink/45">
        Bloom is a wellness companion and provides informational AI guidance
        only{ready ? "; your progress is saved on this device" : ""}. It is not a
        substitute for professional medical advice, diagnosis, or treatment. Always
        seek the guidance of your midwife or doctor with any questions about your
        pregnancy.
      </p>
      <p className="mt-3 text-xs text-ink/30">© {new Date().getFullYear()} Bloom</p>
    </footer>
  );
}
