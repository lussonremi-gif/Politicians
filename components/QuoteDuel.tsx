import { Photo } from "./Photo";
import type { Option } from "@/lib/types";

/** Écran de choix commun au jeu solo et au duel : la citation et les deux personnalités. */
export function QuoteDuel({
  quote,
  isDemo,
  options,
  answerId,
  chosenId,
  disabled,
  onPick,
}: {
  quote: string;
  isDemo: boolean;
  options: [Option, Option];
  answerId?: string | null;
  chosenId?: string | null;
  disabled?: boolean;
  onPick: (id: string) => void;
}) {
  const stateOf = (id: string) => {
    if (!answerId) return id === chosenId ? "is-chosen" : "";
    if (id === answerId) return "is-right";
    if (id === chosenId) return "is-wrong";
    return "is-dim";
  };

  return (
    <>
      <div className="quote-glyph" aria-hidden>“</div>
      <blockquote className="headline quote">« {quote} »</blockquote>
      <span className="tricolor" aria-hidden />
      {isDemo && <p className="demo-banner">Citation fictive de démonstration</p>}

      <div className="duel">
        {options.map((opt, i) => [
          i === 1 && (
            <div key="or" className="duel-or" aria-hidden>
              <span className="bar" />
              ou
              <span className="bar" />
            </div>
          ),
          <button
            key={opt.id}
            className={`person-card ${stateOf(opt.id)}`}
            onClick={() => onPick(opt.id)}
            disabled={disabled}
          >
            <div className="person-photo">
              <Photo src={opt.image_url} name={opt.name} className="portrait-img" />
              {opt.party_short && (
                <span className="person-party" style={{ ["--party" as string]: opt.party_color ?? "#8d939c" }}>
                  {opt.party_short}
                </span>
              )}
            </div>
            <div className="person-name">
              {opt.name}
              {opt.description && <small>{opt.description}</small>}
            </div>
          </button>,
        ])}
      </div>
    </>
  );
}
