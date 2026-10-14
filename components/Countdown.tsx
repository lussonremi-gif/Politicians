"use client";

import { useEffect, useState } from "react";

/** Barre de temps restant jusqu'à `until` (horloge serveur corrigée par `offsetMs`). */
export function Countdown({ until, totalSeconds, offsetMs = 0, onEnd }: { until: string; totalSeconds: number; offsetMs?: number; onEnd?: () => void }) {
  const end = new Date(until).getTime();
  const remainingNow = () => Math.max(0, end - (Date.now() + offsetMs));
  const [remaining, setRemaining] = useState(remainingNow);

  useEffect(() => {
    const t = setInterval(() => {
      const r = remainingNow();
      setRemaining(r);
      if (r <= 0) {
        clearInterval(t);
        onEnd?.();
      }
    }, 200);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [until, offsetMs]);

  const ratio = Math.min(1, remaining / (totalSeconds * 1000));
  return (
    <div className={`countdown ${ratio < 0.25 ? "low" : ""}`} role="timer" aria-label={`${Math.ceil(remaining / 1000)} secondes`}>
      <div className="countdown-bar" style={{ width: `${ratio * 100}%` }} />
      <span>{Math.ceil(remaining / 1000)} s</span>
    </div>
  );
}
