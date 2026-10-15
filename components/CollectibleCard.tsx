"use client";

import { useState } from "react";
import { Photo } from "./Photo";
import { RARITY_LABEL, formatDate, type GameCard } from "@/lib/types";

/**
 * Carte à collectionner : une personnalité et une de ses citations.
 * Recto : photo, citation, nom. Verso : date, occasion, source et crédit photo.
 * Le cadre dépend de la rareté (de l'argent pour « commune » à l'irisé animé pour « mythique »).
 */
export function CollectibleCard({ card, locked = false }: { card: GameCard; locked?: boolean }) {
  const [flipped, setFlipped] = useState(false);
  const year = card.said_on ? card.said_on.slice(0, 4) : null;

  return (
    <button
      type="button"
      className={`ccard rarity-${card.rarity} ${flipped ? "flipped" : ""} ${locked ? "locked" : ""}`}
      style={{ ["--party" as string]: card.party_color ?? "#8d939c" }}
      onClick={() => !locked && setFlipped((f) => !f)}
      aria-label={locked ? `${card.name} : carte ${RARITY_LABEL[card.rarity].toLowerCase()} non obtenue` : `${card.name} : ${card.text}`}
    >
      <div className="ccard-inner">
        <div className="ccard-face ccard-front">
          <div className="ccard-photo">
            <Photo src={card.image_url} fallbackSrc={card.fallback_image_url} focus={card.image_focus} name={card.name} />
          </div>
          <div className="ccard-shine" aria-hidden />
          <div className="ccard-top">
            <span className="ccard-rarity">{RARITY_LABEL[card.rarity]}</span>
            {card.party_short && <span className="ccard-party">{card.party_short}</span>}
          </div>
          <div className="ccard-badges">
            {card.new && <span className="new-tag">Nouvelle</span>}
            {card.copies && card.copies > 1 ? <span className="copies-tag light">×{card.copies}</span> : null}
          </div>
          <div className="ccard-body">
            <p className="ccard-quote">{locked ? "« ? »" : `« ${card.text} »`}</p>
            <div className="ccard-author">
              <strong>{card.name}</strong>
              {year && !locked && <span>{year}</span>}
            </div>
          </div>
          {locked && <div className="ccard-lock" aria-hidden>🔒</div>}
        </div>

        <div className="ccard-face ccard-back">
          <strong className="ccard-back-name">{card.name}</strong>
          {card.role && <span className="ccard-back-role">{card.role}</span>}
          <dl>
            {card.said_on && (
              <>
                <dt>Date</dt>
                <dd>{formatDate(card.said_on)}</dd>
              </>
            )}
            {card.occasion && (
              <>
                <dt>Occasion</dt>
                <dd>{card.occasion}</dd>
              </>
            )}
            <dt>Source</dt>
            <dd>
              {card.source_url ? (
                <a href={card.source_url} target="_blank" rel="noopener noreferrer" onClick={(e) => e.stopPropagation()}>
                  {card.source_label ?? "Source d'origine"} ↗
                </a>
              ) : (
                card.source_label ?? "—"
              )}
            </dd>
          </dl>
          {card.image_url && (
            <p className="ccard-credit">
              Photo : {card.image_credit ?? "Wikimedia Commons"}
              {card.image_license && <> · {card.image_license}</>}
              {card.image_source_url && (
                <>
                  {" · "}
                  <a href={card.image_source_url} target="_blank" rel="noopener noreferrer" onClick={(e) => e.stopPropagation()}>
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
