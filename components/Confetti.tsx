"use client";

import { useMemo } from "react";

const COLORS = ["#2f5597", "#ffffff", "#c8313b", "#ffc83d", "#3fb6a8"];

/** Pluie de confettis tricolores (bonne réponse, victoire). */
export function Confetti({ seed = 1, count = 70 }: { seed?: number; count?: number }) {
  const pieces = useMemo(() => {
    let s = seed * 7919;
    const rand = () => {
      s = (s * 16807) % 2147483647;
      return s / 2147483647;
    };
    return Array.from({ length: count }, () => ({
      left: rand() * 100,
      delay: rand() * 0.35,
      duration: 1.4 + rand() * 1.2,
      drift: (rand() - 0.5) * 220,
      rotate: rand() * 720,
      color: COLORS[Math.floor(rand() * COLORS.length)],
      w: 6 + rand() * 8,
    }));
  }, [seed, count]);
  return (
    <div className="confetti" aria-hidden>
      {pieces.map((p, i) => (
        <span
          key={i}
          style={{
            left: `${p.left}%`,
            background: p.color,
            width: p.w,
            height: p.w * 0.45,
            animationDelay: `${p.delay}s`,
            animationDuration: `${p.duration}s`,
            ["--drift" as string]: `${p.drift}px`,
            ["--rot" as string]: `${p.rotate}deg`,
          }}
        />
      ))}
    </div>
  );
}
