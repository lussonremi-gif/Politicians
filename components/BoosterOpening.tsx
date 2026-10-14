"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { CollectibleCard } from "./CollectibleCard";
import { presentCard } from "@/lib/cardArt";
import { RARITY_LABEL, RARITY_RANK, type OpenedCard, type Rarity } from "@/lib/types";

type Phase = "pack" | "charging" | "reveal" | "summary";

// Durée de la « charge » du booster selon la meilleure carte qu'il contient
const CHARGE_MS: Record<Rarity, number> = {
  common: 700,
  rare: 1400,
  epic: 2000,
  legendary: 2800,
  mythic: 3600,
};

// Étapes d'entrée en scène avant l'apparition de la carte
const STEPS: Record<Rarity, number> = { common: 0, rare: 1, epic: 1, legendary: 3, mythic: 3 };

const HINT: Record<Rarity, string> = {
  common: "Ouverture…",
  rare: "Ça brille…",
  epic: "Ça brille fort…",
  legendary: "Quelque chose de spécial se prépare…",
  mythic: "Une carte historique arrive…",
};

function bestRarity(cards: OpenedCard[]): Rarity {
  return cards.reduce<Rarity>((best, c) => (RARITY_RANK[c.rarity] > RARITY_RANK[best] ? c.rarity : best), "common");
}

function CardView({ card }: { card: OpenedCard }) {
  return <CollectibleCard card={card} />;
}

const isWalkout = (r: Rarity) => r === "legendary" || r === "mythic";

/** Éclats de lumière projetés autour de la carte (rare et légendaire). */
function Particles({ rarity, seed }: { rarity: Rarity; seed: number }) {
  const big = isWalkout(rarity);
  const count = rarity === "mythic" ? 70 : big ? 46 : rarity === "epic" ? 30 : 20;
  const parts = useMemo(
    () =>
      Array.from({ length: count }, (_, i) => {
        const r = Math.sin(seed * 999 + i * 77.7) * 10000;
        const rand = r - Math.floor(r);
        return {
          angle: (360 / count) * i + rand * 20,
          distance: 140 + rand * (big ? 280 : 150),
          delay: rand * 0.25,
          size: 4 + rand * (big ? 9 : 5),
        };
      }),
    [count, big, seed],
  );
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

/**
 * Ouverture de booster en plein écran, façon FUT :
 * le booster « charge » plus ou moins longtemps selon sa meilleure carte, puis les cartes
 * sont révélées une à une, de la plus commune à la plus rare. Une carte légendaire a droit
 * à une entrée en scène (parti, puis année, puis la carte), rayons dorés et éclats.
 */
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
  const prepared = useMemo(() => cards.map(presentCard), [cards]);
  const ordered = useMemo(
    () => [...prepared].sort((a, b) => RARITY_RANK[a.rarity] - RARITY_RANK[b.rarity]),
    [prepared],
  );
  const best = bestRarity(prepared);
  const [phase, setPhase] = useState<Phase>("pack");
  const [index, setIndex] = useState(0);
  const [step, setStep] = useState(0); // étapes de l'entrée en scène d'une carte
  const [flash, setFlash] = useState(false);

  const current = ordered[index];
  // Nombre d'étapes avant que la carte n'apparaisse : légendaire 3 (parti, année, carte), rare 1, commune 0
  const stepsBeforeCard = current ? STEPS[current.rarity] : 0;
  const cardShown = phase === "reveal" && step >= stepsBeforeCard;

  // Bloque le défilement de la page pendant l'ouverture
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  // Charge du booster, puis éclair et première carte
  useEffect(() => {
    if (phase !== "charging") return;
    const t = setTimeout(() => {
      setFlash(true);
      setPhase("reveal");
      setIndex(0);
      setStep(0);
      setTimeout(() => setFlash(false), 450);
    }, CHARGE_MS[best]);
    return () => clearTimeout(t);
  }, [phase, best]);

  // Entrée en scène progressive de la carte courante
  useEffect(() => {
    if (phase !== "reveal" || step >= stepsBeforeCard) return;
    const delay = current?.rarity === "mythic" ? 1000 : current && isWalkout(current.rarity) ? 850 : 650;
    const t = setTimeout(() => setStep((s) => s + 1), delay);
    return () => clearTimeout(t);
  }, [phase, step, stepsBeforeCard, current]);

  // Clavier : Entrée / Espace pour avancer, Échap pour fermer à la fin
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && phase === "summary") onClose();
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        advance();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  function advance() {
    if (phase === "pack") setPhase("charging");
    else if (phase === "reveal" && cardShown) {
      if (index + 1 < ordered.length) {
        setIndex(index + 1);
        setStep(0);
      } else setPhase("summary");
    }
  }

  const stageRarity: Rarity | "none" =
    phase === "reveal" && current ? current.rarity : phase === "charging" ? best : "none";

  return (
    <div
      className={`bo-overlay stage-${stageRarity} phase-${phase}`}
      role="dialog"
      aria-modal="true"
      aria-label={`Ouverture : ${boosterName}`}
      onClick={phase === "summary" ? undefined : advance}
    >
      {stageRarity !== "none" && RARITY_RANK[stageRarity] >= RARITY_RANK.rare && <div className="bo-rays" aria-hidden />}
      {flash && <div className={`bo-flash ${best}`} aria-hidden />}

      {phase !== "summary" && (
        <button
          className="bo-skip"
          onClick={(e) => {
            e.stopPropagation();
            setPhase("summary");
          }}
        >
          Tout révéler
        </button>
      )}

      {(phase === "pack" || phase === "charging") && (
        <div className="bo-center">
          <div className={`bo-pack ${phase === "charging" ? `charging charging-${best}` : ""}`} style={{ ["--accent" as string]: accent }}>
            <span className="tricolor small" aria-hidden />
            <span className="bo-pack-brand">Qui l&apos;a dit ?</span>
            <span className="bo-pack-name">{boosterName}</span>
            <span className="bo-pack-count">{cards.length} cartes</span>
          </div>
          <p className="bo-hint">{phase === "pack" ? "Touchez pour ouvrir" : HINT[best]}</p>
        </div>
      )}

      {phase === "reveal" && current && (
        <div className="bo-center" key={index}>
          <p className="bo-counter">
            Carte {index + 1}/{ordered.length}
          </p>

          {!cardShown && isWalkout(current.rarity) && (
            <div className={`bo-walkout ${current.rarity}`}>
              {step >= 0 && (
                <span className="bo-walkout-party" style={{ ["--party" as string]: current.party_color ?? "#b8892b" }}>
                  {current.party_name ?? current.role ?? "Personnalité politique"}
                </span>
              )}
              {step >= 1 && current.said_on && <span className="bo-walkout-year">{current.said_on.slice(0, 4)}</span>}
              <span className="bo-walkout-label">{RARITY_LABEL[current.rarity]}</span>
            </div>
          )}
          {!cardShown && (current.rarity === "rare" || current.rarity === "epic") && (
            <div className={`bo-glow-orb ${current.rarity}`} aria-hidden />
          )}

          {cardShown && (
            // Toucher la carte la retourne (verso) ; toucher ailleurs passe à la suivante
            <div className={`bo-card enter-${current.rarity}`} onClick={(e) => e.stopPropagation()}>
              {RARITY_RANK[current.rarity] >= RARITY_RANK.rare && <Particles rarity={current.rarity} seed={index + 1} />}
              <CardView card={current} />
              <span className={`bo-banner ${current.rarity}`}>
                {RARITY_LABEL[current.rarity]}
                {current.new ? " · Nouvelle !" : ""}
              </span>
            </div>
          )}

          <p className="bo-hint">{cardShown ? (index + 1 < ordered.length ? "Touchez pour la carte suivante" : "Touchez pour voir le résumé") : ""}</p>
        </div>
      )}

      {phase === "summary" && (
        <div className="bo-summary">
          <h2>{boosterName}</h2>
          <div className="bo-summary-grid">
            {ordered.map((c, i) => (
              <div key={i} className="deal" style={{ animationDelay: `${i * 0.08}s` }}>
                <CardView card={c} />
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
