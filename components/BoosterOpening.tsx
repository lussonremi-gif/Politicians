"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { CollectibleCard } from "./CollectibleCard";
import { Photo } from "./Photo";
import * as sfx from "@/lib/sfx";
import { RARITY_LABEL, RARITY_RANK, type OpenedCard, type Rarity } from "@/lib/types";

/*
 * Ouverture de booster, façon « walkout » FIFA :
 *   1. le booster flotte ; on le touche
 *   2. il se charge (tremblements, lumière qui fuit) plus ou moins longtemps selon sa meilleure carte
 *   3. il explose
 *   4. pour chaque carte, de la plus commune à la plus rare :
 *        scène (projecteurs, couleur de la rareté)
 *        → le parti tombe sur la scène
 *        → la photo se dévoile pendant que la citation s'écrit
 *        → la carte est projetée, onde de choc, éclats (feux d'artifice pour légendaire et mythique)
 *   5. récapitulatif
 * Toucher l'écran accélère : la carte en cours se révèle directement.
 */

type Phase = "pack" | "charging" | "burst" | "reveal" | "summary";

// Durée de la charge du booster selon sa meilleure carte
const CHARGE_MS: Record<Rarity, number> = { common: 1000, uncommon: 1300, rare: 1800, epic: 2400, legendary: 3200, mythic: 4000 };

// Durées des étapes d'une carte : [scène → parti, parti → citation, citation → carte]
const STEP_MS: Record<Rarity, [number, number, number]> = {
  common: [300, 700, 1300],
  uncommon: [400, 800, 1500],
  rare: [600, 1000, 1900],
  epic: [800, 1200, 2300],
  legendary: [1100, 1500, 2900],
  mythic: [1400, 1800, 3400],
};

const HINT: Record<Rarity, string> = {
  common: "Ouverture…",
  uncommon: "Ouverture…",
  rare: "Ça brille…",
  epic: "Ça brille très fort…",
  legendary: "Quelque chose de spécial se prépare…",
  mythic: "Une phrase historique arrive…",
};

const big = (r: Rarity) => RARITY_RANK[r] >= RARITY_RANK.legendary;

function bestRarity(cards: OpenedCard[]): Rarity {
  return cards.reduce<Rarity>((b, c) => (RARITY_RANK[c.rarity] > RARITY_RANK[b] ? c.rarity : b), "common");
}

/** Générateur pseudo-aléatoire stable (pour que les effets ne changent pas à chaque rendu). */
function seeded(seed: number) {
  let s = seed * 9301 + 49297;
  return () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };
}

function Particles({ rarity, seed }: { rarity: Rarity; seed: number }) {
  const rank = RARITY_RANK[rarity];
  const count = [0, 0, 22, 32, 50, 80][rank];
  const parts = useMemo(() => {
    const rand = seeded(seed);
    return Array.from({ length: count }, (_, i) => ({
      angle: (360 / count) * i + rand() * 15,
      distance: 160 + rand() * (rank >= 4 ? 320 : 170),
      delay: rand() * 0.3,
      size: 4 + rand() * (rank >= 4 ? 10 : 6),
    }));
  }, [count, rank, seed]);
  if (!count) return null;
  return (
    <div className={`bo-particles ${rarity}`} aria-hidden>
      {parts.map((p, i) => (
        <span
          key={i}
          style={{
            ["--a" as string]: `${p.angle}deg`,
            ["--d" as string]: `${p.distance}px`,
            animationDelay: `${p.delay}s`,
            width: p.size,
            height: p.size,
          }}
        />
      ))}
    </div>
  );
}

/** Feux d'artifice autour de la carte (légendaire et mythique). */
function Fireworks({ rarity, seed }: { rarity: Rarity; seed: number }) {
  const bursts = useMemo(() => {
    const rand = seeded(seed + 7);
    const n = rarity === "mythic" ? 7 : 4;
    return Array.from({ length: n }, (_, i) => ({
      x: 10 + rand() * 80,
      y: 8 + rand() * 50,
      delay: 0.3 + i * 0.35 + rand() * 0.2,
      hue: rarity === "mythic" ? ["#2f5597", "#ffffff", "#c8313b"][i % 3] : ["#ffd66b", "#fff1b8", "#ffb347"][i % 3],
    }));
  }, [rarity, seed]);
  return (
    <div className="bo-fireworks" aria-hidden>
      {bursts.map((b, i) => (
        <span key={i} className="firework" style={{ left: `${b.x}%`, top: `${b.y}%`, animationDelay: `${b.delay}s`, ["--fw" as string]: b.hue }}>
          {Array.from({ length: 12 }, (_, j) => (
            <i key={j} style={{ ["--r" as string]: `${j * 30}deg`, animationDelay: `${b.delay}s` }} />
          ))}
        </span>
      ))}
    </div>
  );
}

/** Citation qui s'écrit lettre par lettre. */
function TypedQuote({ text, duration }: { text: string; duration: number }) {
  const [shown, setShown] = useState(0);
  useEffect(() => {
    setShown(0);
    const total = text.length;
    const every = Math.max(12, (duration * 0.75) / total);
    let i = 0;
    const t = setInterval(() => {
      i += 1;
      setShown(i);
      if (i % 2 === 0) sfx.tick();
      if (i >= total) clearInterval(t);
    }, every);
    return () => clearInterval(t);
  }, [text, duration]);
  return (
    <p className="wo-quote-text">
      « {text.slice(0, shown)}
      <span className="wo-caret" aria-hidden>
        |
      </span>
      {shown >= text.length ? " »" : ""}
    </p>
  );
}

export function BoosterOpening({
  cards,
  boosterName,
  accent,
  onClose,
}: {
  cards: OpenedCard[];
  boosterName: string;
  accent: string;
  onClose: () => void;
}) {
  const ordered = useMemo(() => [...cards].sort((a, b) => RARITY_RANK[a.rarity] - RARITY_RANK[b.rarity]), [cards]);
  const best = bestRarity(cards);
  const [phase, setPhase] = useState<Phase>("pack");
  const [index, setIndex] = useState(0);
  const [step, setStep] = useState(0); // 0 scène, 1 parti, 2 citation, 3 carte
  const [muted, setMutedState] = useState(sfx.isMuted());
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);

  const current = ordered[index];
  const later = useCallback((fn: () => void, ms: number) => {
    timers.current.push(setTimeout(fn, ms));
  }, []);
  const clearTimers = () => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
  };
  useEffect(() => clearTimers, []);

  // Bloque le défilement de la page
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  // Charge → explosion → première carte
  useEffect(() => {
    if (phase !== "charging") return;
    sfx.riser(CHARGE_MS[best] / 1000, RARITY_RANK[best]);
    later(() => {
      sfx.burst();
      setPhase("burst");
      later(() => {
        setIndex(0);
        setStep(0);
        setPhase("reveal");
      }, 650);
    }, CHARGE_MS[best]);
  }, [phase, best, later]);

  // Enchaînement des étapes de la carte courante
  useEffect(() => {
    if (phase !== "reveal" || !current || step >= 3) return;
    const ms = STEP_MS[current.rarity][step];
    const t = setTimeout(() => {
      const next = step + 1;
      if (next === 1) sfx.thud();
      if (next === 3) sfx.reveal(RARITY_RANK[current.rarity]);
      setStep(next);
    }, ms);
    return () => clearTimeout(t);
  }, [phase, step, current]);

  function advance() {
    if (phase === "pack") {
      setPhase("charging");
      return;
    }
    if (phase !== "reveal" || !current) return;
    if (step < 3) {
      // Accélérer : révéler directement la carte
      sfx.reveal(RARITY_RANK[current.rarity]);
      setStep(3);
      return;
    }
    if (index + 1 < ordered.length) {
      setIndex(index + 1);
      setStep(0);
    } else {
      setPhase("summary");
    }
  }

  // Clavier : Entrée / Espace pour avancer, Échap pour fermer à la fin
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && phase === "summary") onClose();
      if ((e.key === "Enter" || e.key === " ") && phase !== "summary") {
        e.preventDefault();
        advance();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  function toggleMute(e: React.MouseEvent) {
    e.stopPropagation();
    sfx.setMuted(!muted);
    setMutedState(!muted);
  }

  const stage: Rarity | "none" =
    phase === "reveal" && current ? current.rarity : phase === "charging" || phase === "burst" ? best : "none";
  const showRays = stage !== "none" && RARITY_RANK[stage] >= RARITY_RANK.rare && (phase !== "reveal" || step >= 1);

  return (
    <div
      className={`bo-overlay stage-${stage} phase-${phase} ${phase === "reveal" && step === 3 && current && big(current.rarity) ? "quake" : ""}`}
      role="dialog"
      aria-modal="true"
      aria-label={`Ouverture : ${boosterName}`}
      onClick={phase === "summary" ? undefined : advance}
    >
      <div className="bo-spotlights" aria-hidden>
        <span />
        <span />
      </div>
      {showRays && <div className="bo-rays" aria-hidden />}
      <div className="bo-dust" aria-hidden />

      <div className="bo-controls">
        <button className="bo-ctl" onClick={toggleMute} aria-label={muted ? "Activer le son" : "Couper le son"}>
          {muted ? "🔇" : "🔊"}
        </button>
        {phase !== "summary" && (
          <button
            className="bo-ctl"
            onClick={(e) => {
              e.stopPropagation();
              clearTimers();
              setPhase("summary");
            }}
          >
            Tout révéler
          </button>
        )}
      </div>

      {(phase === "pack" || phase === "charging" || phase === "burst") && (
        <div className="bo-center">
          <div
            className={`bo-pack ${phase === "charging" ? `charging charging-${best}` : ""} ${phase === "burst" ? "exploding" : ""}`}
            style={{ ["--accent" as string]: accent }}
          >
            <span className="bo-pack-tear" aria-hidden />
            <span className="tricolor small" aria-hidden />
            <span className="bo-pack-brand">Qui l&apos;a dit ?</span>
            <span className="bo-pack-name">{boosterName}</span>
            <span className="bo-pack-count">{cards.length} cartes</span>
          </div>
          {phase === "burst" && <div className={`bo-flash ${best}`} aria-hidden />}
          <p className="bo-hint">{phase === "pack" ? "Touchez pour ouvrir" : phase === "charging" ? HINT[best] : ""}</p>
        </div>
      )}

      {phase === "reveal" && current && step === 3 && big(current.rarity) && (
        <Fireworks key={`fw-${index}`} rarity={current.rarity} seed={index + 1} />
      )}

      {phase === "reveal" && current && (
        <div className="bo-center wo" key={index}>
          <p className="bo-counter">
            Carte {index + 1}/{ordered.length}
          </p>

          {step < 3 && (
            <div className={`wo-stage wo-${current.rarity}`}>
              {step >= 1 && (
                <div
                  className={`wo-party ${step >= 2 ? "docked" : ""} ${current.party_color ? "" : "no-party"}`}
                  style={{ ["--party" as string]: current.party_color ?? "#2f5bd3" }}
                >
                  <span className="wo-party-badge">{current.party_short ?? "★"}</span>
                  <span className="wo-party-name">{current.party_name ?? current.role ?? "Personnalité politique"}</span>
                  <span className="wo-ring" aria-hidden />
                </div>
              )}
              {step >= 2 && (
                <div className="wo-quote">
                  <div className="wo-photo" style={{ ["--party" as string]: current.party_color ?? "#7a7d85" }}>
                    <Photo src={current.image_url} fallbackSrc={current.fallback_image_url} focus={current.image_focus} name={current.name} />
                  </div>
                  {current.text && <TypedQuote text={current.text} duration={STEP_MS[current.rarity][2]} />}
                  {current.said_on && <span className="wo-year">{current.said_on.slice(0, 4)}</span>}
                </div>
              )}
              {step === 0 && <div className={`wo-glow wo-glow-${current.rarity}`} aria-hidden />}
            </div>
          )}

          {step === 3 && (
            <div className={`bo-card enter-${current.rarity}`} onClick={(e) => e.stopPropagation()}>
              <span className="wo-shockwave" aria-hidden />
              <Particles rarity={current.rarity} seed={index + 1} />
              <CollectibleCard card={current} />
              <span className={`bo-banner ${current.rarity}`}>
                {RARITY_LABEL[current.rarity]}
                {current.new ? " · Nouvelle !" : ""}
              </span>
            </div>
          )}

          <p className="bo-hint">
            {step < 3 ? "Touchez pour révéler" : index + 1 < ordered.length ? "Touchez pour la carte suivante" : "Touchez pour voir le résumé"}
          </p>
        </div>
      )}

      {phase === "summary" && (
        <div className="bo-summary">
          <h2>{boosterName}</h2>
          <div className="bo-summary-grid">
            {ordered.map((c, i) => (
              <div key={i} className="deal" style={{ animationDelay: `${i * 0.08}s` }}>
                <CollectibleCard card={c} />
              </div>
            ))}
          </div>
          <div className="actions">
            <button className="btn primary" onClick={onClose} autoFocus>
              Continuer
            </button>
            <Link href="/collection" className="btn light">
              Voir ma collection
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
