"use client";

import { useState } from "react";
import Link from "next/link";
import { presentCard } from "@/lib/cardArt";
import { Photo } from "./Photo";
import { RARITY_LABEL, formatDate, type GameCard, type Rarity } from "@/lib/types";

const RARITY_GEMS: Record<Rarity, number> = { common: 1, rare: 2, epic: 3, legendary: 4, mythic: 5 };

/**
 * Carte à collectionner : la photo de la citation en grand, la phrase, puis le contexte au verso.
 * Cadre, gemmes et reflet holographique montent en gamme avec la rareté.
 * Les cartes non obtenues restent grisées et renvoient vers les boosters.
 */
export function CollectibleCard({ card, locked = false }: { card: GameCard; locked?: boolean }) {
  const shown = presentCard(card);
  const [flipped, setFlipped] = useState(false);
  const year = shown.said_on ? shown.said_on.slice(0, 4) : null;

  const face = (
    <>
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
    </>
  );

  if (locked) {
    return (
      <Link
        href="/boosters"
        className={`ccard rarity-${shown.rarity} locked`}
        style={{ ["--party" as string]: shown.party_color ?? "#8d939c" }}
        aria-label={`${shown.name} : carte ${RARITY_LABEL[shown.rarity].toLowerCase()} non obtenue — ouvrir un booster`}
      >
        <div className="ccard-inner">
          <div className="ccard-face ccard-front">{face}</div>
        </div>
      </Link>
    );
  }

  return (
    <button
      type="button"
      className={`ccard rarity-${shown.rarity} ${flipped ? "flipped" : ""}`}
      style={{ ["--party" as string]: shown.party_color ?? "#8d939c" }}
      onClick={() => setFlipped((f) => !f)}
      aria-label={`${shown.name} : ${shown.text}`}
    >
      <div className="ccard-inner">
        <div className="ccard-face ccard-front">{face}</div>

        <div className="ccard-face ccard-back">
          <div className="ccard-back-head">
            <span className="ccard-back-portrait">
              <Photo src={shown.image_url} fallbackSrc={shown.fallback_image_url} focus={shown.image_focus} name={shown.name} />
            </span>
            <strong className="ccard-back-name">{shown.name}</strong>
          </div>
          {shown.role && <span className="ccard-back-role">{shown.role}</span>}
          <dl>
            {shown.said_on && (
              <>
                <dt>Date</dt>
                <dd>{formatDate(shown.said_on)}</dd>
              </>
            )}
            {shown.occasion && (
              <>
                <dt>Occasion</dt>
                <dd>{shown.occasion}</dd>
              </>
            )}
            <dt>Source</dt>
            <dd>
              {shown.source_url ? (
                <a href={shown.source_url} target="_blank" rel="noopener noreferrer" onClick={(e) => e.stopPropagation()}>
                  {shown.source_label ?? "Source d'origine"} ↗
                </a>
              ) : (
                shown.source_label ?? "—"
              )}
            </dd>
          </dl>
          {shown.image_url && (
            <p className="ccard-credit">
              Photo : {shown.image_credit ?? "Wikimedia Commons"}
              {shown.image_license && <> · {shown.image_license}</>}
              {shown.image_source_url && (
                <>
                  {" · "}
                  <a href={shown.image_source_url} target="_blank" rel="noopener noreferrer" onClick={(e) => e.stopPropagation()}>
                    source
                  </a>
                </>
              )}
            </p>
          )}
        </div>
      </div>
    </button>
  );
}
