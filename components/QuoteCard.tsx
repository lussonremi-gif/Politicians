"use client";

import { useState } from "react";
import { RARITY_LABEL, formatDate, type Card } from "@/lib/types";

/** Carte à collectionner : recto = citation + auteur, verso = contexte et source. */
export function QuoteCard({ card, flippable = true, startFlipped = false }: { card: Card; flippable?: boolean; startFlipped?: boolean }) {
  const [flipped, setFlipped] = useState(startFlipped);
  const date = formatDate(card.said_on);

  return (
    <button
      type="button"
      className={`qcard rarity-${card.rarity} ${flipped ? "flipped" : ""}`}
      onClick={() => flippable && setFlipped((f) => !f)}
      aria-label={flipped ? "Voir la citation" : "Voir le contexte"}
    >
      <div className="qcard-inner">
        <div className="qcard-face qcard-front">
          <div className="qcard-top">
            <span className="rarity-tag">{RARITY_LABEL[card.rarity]}</span>
            {card.new && <span className="new-tag">Nouvelle</span>}
            {card.copies && card.copies > 1 ? <span className="copies-tag">×{card.copies}</span> : null}
          </div>
          <p className="qcard-quote">« {card.text} »</p>
          <div className="qcard-author">
            <strong>{card.author}</strong>
            {card.author_description && <span>{card.author_description}</span>}
          </div>
          {card.is_demo && <span className="demo-tag">Démo · fictif</span>}
        </div>
        <div className="qcard-face qcard-back">
          <h4>Contexte</h4>
          <dl>
            {date && (
              <>
                <dt>Date</dt>
                <dd>{date}</dd>
              </>
            )}
            {card.occasion && (
              <>
                <dt>Occasion</dt>
                <dd>{card.occasion}</dd>
              </>
            )}
            {card.theme && (
              <>
                <dt>Thème</dt>
                <dd className="capitalize">{card.theme}</dd>
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
          <span className="qcard-author-small">{card.author}</span>
        </div>
      </div>
    </button>
  );
}
