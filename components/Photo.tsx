"use client";

import { useState } from "react";

function initials(name: string) {
  return name
    .split(/[\s-]+/)
    .filter(Boolean)
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

/**
 * Photo d'une personnalité. Si l'image ne charge pas, essaie la photo de repli
 * (photo générale de la personnalité), puis affiche un monogramme.
 */
export function Photo({
  src,
  name,
  className,
  fallbackSrc,
  focus,
}: {
  src: string | null;
  name: string;
  className?: string;
  fallbackSrc?: string | null;
  focus?: string | null;
}) {
  const candidates = [src, fallbackSrc].filter((s, i, all): s is string => !!s && all.indexOf(s) === i);
  const [attempt, setAttempt] = useState(0);
  const current = candidates[attempt];

  if (!current) {
    return (
      <div className={`portrait-fallback ${className ?? ""}`} aria-hidden>
        <span>{initials(name)}</span>
      </div>
    );
  }

  // Wikimedia : version un peu plus nette pour les portraits de duel.
  let hiRes = current;
  if (current.includes("Special:FilePath/")) {
    hiRes = /[?&]width=\d+/i.test(current)
      ? current.replace(/([?&])width=\d+/i, "$1width=800")
      : `${current}${current.includes("?") ? "&" : "?"}width=800`;
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      className={className}
      src={hiRes}
      alt={name}
      loading="lazy"
      referrerPolicy="no-referrer"
      style={{ objectPosition: focus || "center 28%" }}
      onError={() => setAttempt((a) => a + 1)}
    />
  );
}
