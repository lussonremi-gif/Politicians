"use client";

import { useState } from "react";
import Link from "next/link";
import { presentCard } from "@/lib/cardArt";
import { Photo } from "./Photo";
import { RARITY_LABEL, formatDate, type GameCard, type Rarity } from "@/lib/types";

const RARITY_GEMS: Record<Rarity, number> = { common: 1, rare: 2, epic: 3, legendary: 4 };

/**
 * Carte à collectionner : la photo de la citation en grand et la phrase au recto ;
 * au verso, le contexte, la citation et la date.
 * Cadre, gemmes et reflet holographique montent en gamme avec la rareté.
 * Le retournement est un pivot à plat (pas de 3D) : aucun texte ne s'affiche jamais à l'envers.
 * Les cartes non obtenues restent grisées et renvoient vers les boosters.
 */
export function CollectibleCard({ card, locked = false }: { card: GameCard; locked?: boolean }) {
  const shown = presentCard(card);
  const [flipped, setFlipped] = useState(false);
  const [turning, setTurning] = useState(false);
  const year = shown.said_on ? shown.said_on.slice(0, 4) : null;

  function turn() {
    if (turning) return;
    setTurning(true);
    setTimeout(() => setFlipped((f) => !f), 160);
    setTimeout(() => setTurning(false), 340);
  }

  const front = (
    <div className="ccard-face ccard-front">
      <div className="ccard-art">
        <Photo src={shown.image_url} fallbackSrc={shown.fallback_image_url} focus={shown.image_focus} name={shown.name} />
        <div className="ccard-foil" aria-hidden />
        <div className="ccard-art-fade" aria-hidden />
        {locked && (
          <div className="ccard-locked-hint" aria-hidden>
            <span>Non obtenue</span>
          </div>
        )}
        <div className="ccard-top">
          <span className="ccard-rarity">
            <span className="ccard-gems" aria-hidden>
              {Array.from({ length: RARITY_GEMS[shown.rarity] }, (_, i) => (
                <i key={i} />
              ))}
            </span>
            {RARITY_LABEL[shown.rarity]}
          </span>
          {shown.party_short && <span className="ccard-party">{shown.party_short}</span>}
        </div>
        {!locked && (
          <div className="ccard-badges">
            {shown.new === true && <span className="new-tag">Nouvelle</span>}
            {shown.new === false && <span className="dupe-tag">Déjà obtenue</span>}
            {shown.copies && shown.copies > 1 ? <span className="copies-tag light">×{shown.copies}</span> : null}
          </div>
        )}
        <div className="ccard-nameplate">
          <strong>{shown.name}</strong>
          {year && !locked && <span>{year}</span>}
        </div>
      </div>
      <p className="ccard-quote">{locked ? "À découvrir dans un booster" : `« ${shown.text} »`}</p>
      <div className="ccard-shine" aria-hidden />
    </div>
  );

  if (locked) {
    return (
      <Link
        href="/boosters"
        className={`ccard rarity-${shown.rarity} locked`}
        style={{ ["--party" as string]: shown.party_color ?? "#8d939c" }}
        aria-label={`${shown.name} : carte ${RARITY_LABEL[shown.rarity].toLowerCase()} non obtenue — ouvrir un booster`}
      >
        <div className="ccard-inner">{front}</div>
      </Link>
    );
  }

  return (
    <button
      type="button"
      className={`ccard rarity-${shown.rarity} ${flipped ? "flipped" : ""}`}
      style={{ ["--party" as string]: shown.party_color ?? "#8d939c" }}
      onClick={turn}
      aria-label={`${shown.name} : ${shown.text}`}
    >
      <div className={`ccard-inner ${turning ? "turning" : ""}`}>
        {!flipped ? (
          front
        ) : (
          <div className="ccard-face ccard-back">
            <span className="ccard-back-label">Contexte</span>
            <p className="ccard-back-context">{shown.occasion ?? shown.name}</p>
            <p className="ccard-back-quote">« {shown.text} »</p>
            {shown.said_on && <span className="ccard-back-date">{formatDate(shown.said_on)}</span>}
            {shown.image_url && (
              <span className="ccard-credit">
                Photo : {shown.image_credit ?? "Wikimedia Commons"}
                {shown.image_license && <> · {shown.image_license}</>}
              </span>
            )}
          </div>
        )}
      </div>
    </button>
  );
}
