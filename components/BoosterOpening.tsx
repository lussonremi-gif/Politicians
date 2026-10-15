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
 *   4. pour chaque carte, de la plus commune à la plus rare, un indice à la fois, seul à l'écran :
 *        lumière qui monte (couleur de la rareté)
 *        → le parti (écusson)
 *        → le poste, s'il y en a un
 *        → la carte d'un coup : photo + citation, onde de choc, éclats
 *          (feux d'artifice pour légendaire et mythique)
 *   5. récapitulatif
 * Toucher l'écran passe à l'indice suivant.
 */

type Phase = "pack" | "charging" | "burst" | "reveal" | "summary";

// Durée de la charge du booster selon sa meilleure carte
const CHARGE_MS: Record<Rarity, number> = { common: 1000, rare: 1800, epic: 2400, legendary: 3200, mythic: 4000 };

// Étapes d'une carte
const INTRO = 0;
const PARTY = 1;
const ROLE = 2;
const CARD = 3;

// Temps passé sur chaque indice : [lumière, parti, poste]
const HOLD_MS: Record<Rarity, [number, number, number]> = {
  common: [700, 1400, 1400],
  rare: [900, 1700, 1700],
  epic: [1000, 1900, 1900],
  legendary: [1200, 2200, 2200],
  mythic: [1400, 2600, 2600],
};

const HINT: Record<Rarity, string> = {
  common: "Ouverture…",
  rare: "Ça brille…",
  epic: "Ça brille très fort…",
  legendary: "Quelque chose de spécial se prépare…",
  mythic: "Une phrase historique arrive…",
};

const big = (r: Rarity) => RARITY_RANK[r] >= RARITY_RANK.legendary;

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

function Particles({ rarity, seed }: { rarity: Rarity; seed: number }) {
  const rank = RARITY_RANK[rarity];
  const count = [0, 22, 32, 50, 80][rank];
  const parts = useMemo(() => {
    const rand = seeded(seed);
    return Array.from({ length: count }, (_, i) => ({
      angle: (360 / count) * i + rand() * 15,
      distance: 160 + rand() * (rank >= 3 ? 320 : 170),
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

/** Feux d'artifice plein écran (légendaire et mythique). */
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
  const [step, setStep] = useState(INTRO);
  const [muted, setMutedState] = useState(sfx.isMuted());
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);

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

  // Charge → explosion → première carte
  useEffect(() => {
    if (phase !== "charging") return;
    sfx.riser(CHARGE_MS[best] / 1000, RARITY_RANK[best]);
    later(() => {
      sfx.burst();
      setPhase("burst");
      later(() => {
        setIndex(0);
        setStep(INTRO);
        setPhase("reveal");
      }, 650);
    }, CHARGE_MS[best]);
  }, [phase, best, later]);

  /** Passe à l'indice suivant de la carte courante (le poste est sauté s'il n'y en a pas). */
  const nextStep = useCallback(() => {
    if (!current) return;
    const next = step === PARTY && !role ? CARD : step + 1;
    if (next === PARTY || next === ROLE) sfx.thud();
    if (next === CARD) sfx.reveal(RARITY_RANK[current.rarity]);
    setStep(next);
  }, [current, step, role]);

  // Enchaînement automatique des indices
  useEffect(() => {
    if (phase !== "reveal" || !current || step >= CARD) return;
    const t = setTimeout(nextStep, HOLD_MS[current.rarity][step]);
    return () => clearTimeout(t);
  }, [phase, step, current, nextStep]);

  // Petite montée sonore pendant que la lumière monte
  useEffect(() => {
    if (phase === "reveal" && current && step === INTRO) {
      sfx.riser(HOLD_MS[current.rarity][INTRO] / 1000, RARITY_RANK[current.rarity]);
    }
  }, [phase, step, current]);

  function advance() {
    if (phase === "pack") {
      setPhase("charging");
      return;
    }
    if (phase !== "reveal" || !current) return;
    if (step < CARD) {
      nextStep();
      return;
    }
    if (index + 1 < ordered.length) {
      setIndex(index + 1);
      setStep(INTRO);
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
  // Les rayons tournent dès la charge, et accélèrent quand la carte apparaît
  const showRays = phase === "charging" || phase === "burst" || phase === "reveal";
  const quake = phase === "reveal" && step === CARD && current && big(current.rarity);

  return (
    <div
      className={`bo-overlay stage-${stage} phase-${phase} ${phase === "reveal" ? `step-${step}` : ""}`}
      role="dialog"
      aria-modal="true"
      aria-label={`Ouverture : ${boosterName}`}
      onClick={phase === "summary" ? undefined : advance}
    >
      {/* Fond plein écran : couvre toujours tout le viewport, quelle que soit sa taille */}
      <div className="bo-bg" aria-hidden>
        {showRays && <div className="bo-bg-rays" />}
        <div className="bo-bg-vignette" />
      </div>
      <div className="bo-spotlights" aria-hidden>
        <span />
        <span />
      </div>
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

      {/* Coupure lumineuse entre deux indices (à la racine : plein écran même pendant le tremblement) */}
      {phase === "reveal" && step > INTRO && <div className="wo-cut" key={`cut-${index}-${step}`} aria-hidden />}

      {quake && <Fireworks key={`fw-${index}`} rarity={current.rarity} seed={index + 1} />}

      {phase === "reveal" && current && (
        <div className={`bo-center wo ${quake ? "quake" : ""}`} key={index}>
          <p className="bo-counter">
            Carte {index + 1}/{ordered.length}
          </p>

          {step < CARD && (
            <div className={`wo-stage wo-${current.rarity}`} key={`step-${step}`}>
              {step === INTRO && <div className="wo-glow" aria-hidden />}

              {step === PARTY && (
                <div className={`wo-clue wo-party ${current.party_color ? "" : "no-party"}`} style={{ ["--party" as string]: current.party_color ?? "#2f5bd3" }}>
                  <span className="wo-label">Parti</span>
                  <span className="wo-crest">
                    <span className="wo-crest-text">{current.party_short ?? "SE"}</span>
                  </span>
                  <span className="wo-ring" aria-hidden />
                  <span className="wo-ring late" aria-hidden />
                  <strong className="wo-party-name">{current.party_name ?? "Sans étiquette"}</strong>
                </div>
              )}

              {step === ROLE && role && (
                <div className="wo-clue wo-role" style={{ ["--party" as string]: current.party_color ?? "#2f5bd3" }}>
                  <span className="wo-label">Poste</span>
                  <strong className="wo-role-title">{role.title}</strong>
                  {role.period && <span className="wo-role-period">{role.period}</span>}
                  <span className="wo-underline" aria-hidden />
                </div>
              )}
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
