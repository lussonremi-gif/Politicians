"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { CollectibleCard } from "./CollectibleCard";
import { presentCard } from "@/lib/cardArt";
import * as sfx from "@/lib/sfx";
import { RARITY_LABEL, RARITY_RANK, type OpenedCard, type Rarity } from "@/lib/types";

/*
 * Ouverture de booster, façon « walkout » FIFA :
 *   1. le booster flotte ; on le touche
 *   2. il se charge (tremblements, lumière qui fuit) plus ou moins longtemps selon sa meilleure carte
 *   3. il explose
 *   4. pour chaque carte, de la plus commune à la plus rare, un indice à la fois :
 *        le parti (écusson) → le poste, s'il y en a un → la carte d'un coup (photo + citation)
 *      Chaque indice entre, reste, puis sort en fondu avant le suivant ; le décor (faisceaux,
 *      aurores, étincelles) prend la couleur de la rareté et s'emballe à chaque changement.
 *   5. récapitulatif
 * Toucher l'écran passe à l'indice suivant.
 */

type Phase = "pack" | "charging" | "burst" | "reveal" | "summary";

// Étapes d'une carte
const PARTY = 0;
const ROLE = 1;
const CARD = 2;

// Durée de la charge du booster selon sa meilleure carte
const CHARGE_MS: Record<Rarity, number> = { common: 1200, rare: 1900, epic: 2600, legendary: 3600 };

// Temps passé sur chaque indice (parti, poste), entrée comprise
const HOLD_MS: Record<Rarity, number> = { common: 1700, rare: 2000, epic: 2300, legendary: 2700 };

// Durée de la sortie d'un indice avant l'entrée du suivant
const LEAVE_MS = 380;

const HINT: Record<Rarity, string> = {
  common: "Ouverture…",
  rare: "Ça brille…",
  epic: "Ça brille très fort…",
  legendary: "Une phrase historique arrive…",
};

const isLegendary = (r: Rarity) => r === "legendary";

function bestRarity(cards: OpenedCard[]): Rarity {
  return cards.reduce<Rarity>((b, c) => (RARITY_RANK[c.rarity] > RARITY_RANK[b] ? c.rarity : b), "common");
}

/** « Premier ministre (1997-2002) » → titre « Premier ministre », période « 1997-2002 ». */
function splitRole(role: string | null | undefined): { title: string; period: string | null } | null {
  if (!role) return null;
  const m = role.match(/^(.*?)\s*\(([^)]*)\)\s*$/);
  return m ? { title: m[1], period: m[2] } : { title: role, period: null };
}

/** Générateur pseudo-aléatoire stable (pour que les effets ne changent pas à chaque rendu). */
function seeded(seed: number) {
  let s = seed * 9301 + 49297;
  return () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };
}

/** Décor plein écran : aurores, faisceaux de stade, étincelles qui montent, sol lumineux. */
function Stage({ pulse }: { pulse: string }) {
  const sparks = useMemo(() => {
    const rand = seeded(3);
    return Array.from({ length: 36 }, () => ({
      left: rand() * 100,
      delay: -rand() * 6,
      duration: 3 + rand() * 4,
      size: 2 + rand() * 4,
      drift: (rand() - 0.5) * 80,
    }));
  }, []);
  return (
    <div className="bo-bg" aria-hidden>
      <div className="bo-aurora">
        <i />
        <i />
        <i />
      </div>
      <div className="bo-beams">
        {Array.from({ length: 6 }, (_, i) => (
          <i key={i} style={{ ["--i" as string]: i }} />
        ))}
      </div>
      <div className="bo-floor" />
      <div className="bo-sparks">
        {sparks.map((s, i) => (
          <i
            key={i}
            style={{
              left: `${s.left}%`,
              width: s.size,
              height: s.size,
              animationDelay: `${s.delay}s`,
              animationDuration: `${s.duration}s`,
              ["--drift" as string]: `${s.drift}px`,
            }}
          />
        ))}
      </div>
      {/* Lignes de vitesse : rejouées à chaque changement d'indice */}
      {pulse && <div className="bo-warp" key={pulse} />}
      <div className="bo-vignette" />
    </div>
  );
}

function Particles({ rarity, seed }: { rarity: Rarity; seed: number }) {
  const rank = RARITY_RANK[rarity];
  const count = [0, 24, 40, 80][rank];
  const parts = useMemo(() => {
    const rand = seeded(seed);
    return Array.from({ length: count }, (_, i) => ({
      angle: (360 / count) * i + rand() * 15,
      distance: 160 + rand() * (rank >= 3 ? 320 : 180),
      delay: rand() * 0.3,
      size: 4 + rand() * (rank >= 3 ? 10 : 6),
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

/** Feux d'artifice plein écran (légendaire). */
function Fireworks({ seed }: { seed: number }) {
  const bursts = useMemo(() => {
    const rand = seeded(seed + 7);
    return Array.from({ length: 7 }, (_, i) => ({
      x: 8 + rand() * 84,
      y: 8 + rand() * 50,
      delay: 0.25 + i * 0.3 + rand() * 0.2,
      hue: ["#ffd66b", "#fff1b8", "#ffb347", "#ffffff"][i % 4],
    }));
  }, [seed]);
  return (
    <div className="bo-fireworks" aria-hidden>
      {bursts.map((b, i) => (
        <span key={i} className="firework" style={{ left: `${b.x}%`, top: `${b.y}%`, ["--fw" as string]: b.hue }}>
          {Array.from({ length: 12 }, (_, j) => (
            <i key={j} style={{ ["--r" as string]: `${j * 30}deg`, animationDelay: `${b.delay}s` }} />
          ))}
        </span>
      ))}
    </div>
  );
}

/** Facteur de zoom pour que les cartes du récapitulatif (230 × 360) tiennent dans l'écran. */
function useSummaryZoom(count: number) {
  const [zoom, setZoom] = useState(1);
  useEffect(() => {
    function fit() {
      // On essaie 3, 2 ou 1 carte par ligne et on garde la disposition où les cartes sont les plus grandes
      let best = 0.35;
      for (let perRow = Math.min(count, 3); perRow >= 1; perRow--) {
        const rows = Math.ceil(count / perRow);
        const byWidth = (window.innerWidth - 32 - (perRow - 1) * 14) / perRow / 230;
        const byHeight = (window.innerHeight - 210 - (rows - 1) * 14) / rows / 360;
        best = Math.max(best, Math.min(1, byWidth, byHeight));
      }
      setZoom(best);
    }
    fit();
    window.addEventListener("resize", fit);
    return () => window.removeEventListener("resize", fit);
  }, [count]);
  return zoom;
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
  // presentCard : photo propre à la carte et rareté normalisée (voir lib/cardArt)
  const prepared = useMemo(() => cards.map(presentCard), [cards]);
  const ordered = useMemo(() => [...prepared].sort((a, b) => RARITY_RANK[a.rarity] - RARITY_RANK[b.rarity]), [prepared]);
  const best = bestRarity(prepared);
  const [phase, setPhase] = useState<Phase>("pack");
  const [index, setIndex] = useState(0);
  const [step, setStep] = useState(PARTY);
  const [leaving, setLeaving] = useState(false);
  const [muted, setMutedState] = useState(sfx.isMuted());
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);
  const summaryZoom = useSummaryZoom(cards.length);

  const current = ordered[index];
  const role = splitRole(current?.role);

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

  // Charge → explosion → premier indice de la première carte
  useEffect(() => {
    if (phase !== "charging") return;
    sfx.riser(CHARGE_MS[best] / 1000, RARITY_RANK[best]);
    later(() => {
      sfx.burst();
      setPhase("burst");
      later(() => {
        setIndex(0);
        setStep(PARTY);
        setPhase("reveal");
        sfx.thud();
      }, 600);
    }, CHARGE_MS[best]);
  }, [phase, best, later]);

  /** L'indice courant sort en fondu, puis le suivant entre (le poste est sauté s'il n'y en a pas). */
  const nextStep = useCallback(() => {
    if (!current || leaving) return;
    const next = step === PARTY && !role ? CARD : step + 1;
    setLeaving(true);
    sfx.whoosh();
    later(() => {
      setLeaving(false);
      setStep(next);
      if (next === CARD) sfx.reveal(RARITY_RANK[current.rarity]);
      else sfx.thud();
    }, LEAVE_MS);
  }, [current, step, role, leaving, later]);

  // Enchaînement automatique des indices
  useEffect(() => {
    if (phase !== "reveal" || !current || step >= CARD || leaving) return;
    const t = setTimeout(nextStep, HOLD_MS[current.rarity]);
    return () => clearTimeout(t);
  }, [phase, step, current, leaving, nextStep]);

  function advance() {
    if (phase === "pack") {
      setPhase("charging");
      return;
    }
    if (phase !== "reveal" || !current || leaving) return;
    if (step < CARD) {
      nextStep();
      return;
    }
    if (index + 1 < ordered.length) {
      setLeaving(true);
      sfx.whoosh();
      later(() => {
        setLeaving(false);
        setIndex(index + 1);
        setStep(PARTY);
        sfx.thud();
      }, LEAVE_MS);
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
  const revealed = phase === "reveal" && step === CARD && !leaving && current;
  const pulse = phase === "reveal" ? `${index}-${step}` : phase === "burst" ? "burst" : "";

  return (
    <div
      className={`bo-overlay stage-${stage} phase-${phase} ${phase === "reveal" ? `step-${step}` : ""}`}
      style={{ ["--party" as string]: phase === "reveal" ? current?.party_color ?? "#2f5bd3" : accent }}
      role="dialog"
      aria-modal="true"
      aria-label={`Ouverture : ${boosterName}`}
      onClick={phase === "summary" ? undefined : advance}
    >
      <Stage pulse={pulse} />

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
              setLeaving(false);
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

      {revealed && <div className={`bo-flash ${current.rarity}`} key={`flash-${index}`} aria-hidden />}
      {revealed && isLegendary(current.rarity) && <Fireworks key={`fw-${index}`} seed={index + 1} />}

      {phase === "reveal" && current && (
        <div className={`bo-center wo ${revealed && RARITY_RANK[current.rarity] >= 2 ? "quake" : ""}`}>
          <p className="bo-counter">
            Carte {index + 1}/{ordered.length}
          </p>

          <div className={`wo-slot ${leaving ? "leaving" : ""}`} key={`${index}-${step}`}>
            {step === PARTY && (
              <div className={`wo-clue wo-party ${current.party_color ? "" : "no-party"}`}>
                <span className="wo-label">Parti</span>
                <span className="wo-crest-wrap">
                  <span className="wo-crest-glow" aria-hidden />
                  <span className="wo-crest">
                    <span className="wo-crest-text">{current.party_short ?? "SE"}</span>
                  </span>
                </span>
                <strong className="wo-party-name">{current.party_name ?? "Sans étiquette"}</strong>
              </div>
            )}

            {step === ROLE && role && (
              <div className="wo-clue wo-role">
                <span className="wo-label">Poste</span>
                <strong className="wo-role-title">{role.title}</strong>
                {role.period && <span className="wo-role-period">{role.period}</span>}
                <span className="wo-underline" aria-hidden />
              </div>
            )}

            {step === CARD && (
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
          </div>

          <p className="bo-hint">
            {step < CARD ? "Touchez pour continuer" : index + 1 < ordered.length ? "Touchez pour la carte suivante" : "Touchez pour voir le résumé"}
          </p>
        </div>
      )}

      {phase === "summary" && (
        <div className="bo-summary">
          <h2>{boosterName}</h2>
          <div className="bo-summary-grid">
            {ordered.map((c, i) => (
              <div key={i} className="deal" style={{ animationDelay: `${i * 0.08}s`, zoom: summaryZoom }}>
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
