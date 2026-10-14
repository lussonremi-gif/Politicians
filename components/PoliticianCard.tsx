"use client";

import { useState } from "react";
import { Photo } from "./Photo";
import { RARITY_LABEL, type PoliticianCardData } from "@/lib/types";

/**
 * Carte « personnalité politique ».
 * Recto : photo, année de la version, parti, intitulé. Verso : contexte et crédit photo.
 * Le cadre dépend de la rareté (argent, bleu holographique, or animé).
 */
export function PoliticianCard({
  card,
  locked = false,
  flippable = true,
}: {
  card: PoliticianCardData;
  locked?: boolean;
  flippable?: boolean;
}) {
  const [flipped, setFlipped] = useState(false);
  const accent = card.party_color ?? "#7a7d85";

  return (
    <button
      type="button"
      className={`pcard rarity-${card.rarity} ${flipped ? "flipped" : ""} ${locked ? "locked" : ""}`}
      style={{ ["--party" as string]: accent }}
      onClick={() => flippable && !locked && setFlipped((f) => !f)}
      aria-label={locked ? `${card.name} ${card.year} : carte non obtenue` : `${card.name} ${card.year}`}
    >
      <div className="pcard-inner">
        <div className="pcard-face pcard-front">
          <div className="pcard-photo">
            <Photo src={card.image_url} name={card.name} />
            <div className="pcard-shine" aria-hidden />
          </div>
          <div className="pcard-top">
            <span className="pcard-year">{card.year}</span>
            {card.party_short && <span className="pcard-party">{card.party_short}</span>}
          </div>
          <div className="pcard-badges">
            {card.new && <span className="new-tag">Nouvelle</span>}
            {card.copies && card.copies > 1 ? <span className="copies-tag light">×{card.copies}</span> : null}
          </div>
          <div className="pcard-bottom">
            <span className="pcard-rarity">{RARITY_LABEL[card.rarity]}</span>
            <strong className="pcard-name">{card.name}</strong>
            <span className="pcard-title">{card.title}</span>
          </div>
          {locked && (
            <div className="pcard-lock" aria-hidden>
              <span>🔒</span>
            </div>
          )}
        </div>
        <div className="pcard-face pcard-back">
          <span className="pcard-year big">{card.year}</span>
          <strong className="pcard-name">{card.name}</strong>
          <dl>
            <dt>Version</dt>
            <dd>{card.title}</dd>
            {card.party_label && (
              <>
                <dt>Étiquette en {card.year}</dt>
                <dd>{card.party_label}</dd>
              </>
            )}
            {card.party_name && (
              <>
                <dt>Parti actuel</dt>
                <dd>{card.party_name}</dd>
              </>
            )}
            <dt>Rareté</dt>
            <dd>{RARITY_LABEL[card.rarity]}</dd>
          </dl>
          {card.image_url && (
            <p className="pcard-credit">
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
