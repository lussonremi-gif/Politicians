"use client";

import { useState } from "react";
import { presentCard } from "@/lib/cardArt";
import { Photo } from "./Photo";
import { RARITY_LABEL, formatDate, type GameCard } from "@/lib/types";

/**
 * Carte à collectionner : le portrait de l'auteur, sa citation, puis le contexte au verso.
 * Le cadre et l'anneau du portrait suivent la rareté.
 */
export function CollectibleCard({ card, locked = false }: { card: GameCard; locked?: boolean }) {
  const shown = presentCard(card);
  const [flipped, setFlipped] = useState(false);
  const year = shown.said_on ? shown.said_on.slice(0, 4) : null;

  return (
    <button
      type="button"
      className={`ccard rarity-${shown.rarity} ${flipped ? "flipped" : ""} ${locked ? "locked" : ""}`}
      style={{ ["--party" as string]: shown.party_color ?? "#8d939c" }}
      onClick={() => !locked && setFlipped((f) => !f)}
      aria-label={locked ? `${shown.name} : carte ${RARITY_LABEL[shown.rarity].toLowerCase()} non obtenue` : `${shown.name} : ${shown.text}`}
    >
      <div className="ccard-inner">
        <div className="ccard-face ccard-front">
          <div className="ccard-pattern" aria-hidden />
          <div className="ccard-shine" aria-hidden />
          <div className="ccard-top">
            <span className="ccard-rarity">{RARITY_LABEL[shown.rarity]}</span>
            {shown.party_short && <span className="ccard-party">{shown.party_short}</span>}
          </div>
          <div className="ccard-badges">
            {shown.new && <span className="new-tag">Nouvelle</span>}
            {shown.copies && shown.copies > 1 ? <span className="copies-tag light">×{shown.copies}</span> : null}
          </div>
          <div className="ccard-portrait">
            <Photo src={shown.image_url} fallbackSrc={shown.fallback_image_url} focus={shown.image_focus} name={shown.name} />
            {locked && <div className="ccard-lock" aria-hidden>🔒</div>}
          </div>
          <div className="ccard-nameplate">
            <strong>{shown.name}</strong>
            {year && !locked && <span>{year}</span>}
          </div>
          <p className="ccard-quote">{locked ? "Citation à découvrir" : `« ${shown.text} »`}</p>
        </div>

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
