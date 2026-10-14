"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { Gate } from "@/components/Gate";
import { QuoteCard } from "@/components/QuoteCard";
import { errorMessage, getSupabase } from "@/lib/supabase";
import type { BoosterType, Card } from "@/lib/types";

function Boosters() {
  const { profile, setPoints } = useAuth();
  const [boosters, setBoosters] = useState<BoosterType[]>([]);
  const [opening, setOpening] = useState<string | null>(null);
  const [revealed, setRevealed] = useState<Card[] | null>(null);
  const [shownCount, setShownCount] = useState(0);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSupabase()
      .from("booster_types")
      .select("*")
      .order("sort_order")
      .order("price")
      .then(({ data, error }) => {
        if (error) setError(errorMessage(error));
        else setBoosters(data as BoosterType[]);
      });
  }, []);

  // Révélation des cartes une à une
  useEffect(() => {
    if (!revealed || shownCount >= revealed.length) return;
    const t = setTimeout(() => setShownCount((n) => n + 1), 550);
    return () => clearTimeout(t);
  }, [revealed, shownCount]);

  async function open(slug: string) {
    setOpening(slug);
    setError(null);
    try {
      const { data, error } = await getSupabase().rpc("open_booster", { p_slug: slug });
      if (error) throw error;
      const res = data as { cards: Card[]; points_left: number };
      setPoints(res.points_left);
      setShownCount(0);
      setRevealed(res.cards);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setOpening(null);
    }
  }

  const points = profile?.points ?? 0;

  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Boosters</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">
          Vous avez <strong>{points.toLocaleString("fr-FR")} points</strong>. Ouvrez des boosters pour compléter votre
          collection.
        </p>
      </div>

      {error && <p className="notice error center">{error}</p>}

      {revealed && (
        <div className="booster-reveal">
          <div className="card-grid">
            {revealed.slice(0, shownCount).map((c, i) => (
              <div key={c.quote_id + i} className="deal">
                <QuoteCard card={c} />
              </div>
            ))}
          </div>
          {shownCount >= revealed.length && (
            <div className="actions">
              <button className="btn" onClick={() => setRevealed(null)}>Fermer</button>
            </div>
          )}
        </div>
      )}

      <div className="booster-grid">
        {boosters.map((b) => (
          <article key={b.slug} className={`booster ${b.personality_id ? "by-person" : b.theme ? "by-theme" : ""}`}>
            <div className="booster-pack" aria-hidden>
              <span className="tricolor small" />
              <span className="pack-count">{b.card_count}</span>
              <span className="pack-label">cartes</span>
            </div>
            <h3>{b.name}</h3>
            {b.description && <p className="muted">{b.description}</p>}
            <p className="odds">
              Commune {b.weight_common}% · Rare {b.weight_rare}% · Légendaire {b.weight_legendary}%
            </p>
            <button
              className="btn primary"
              disabled={points < b.price || opening !== null}
              onClick={() => open(b.slug)}
            >
              {opening === b.slug ? "Ouverture…" : `Ouvrir · ${b.price} pts`}
            </button>
          </article>
        ))}
      </div>
    </section>
  );
}

export default function BoostersPage() {
  return (
    <Gate>
      <Boosters />
    </Gate>
  );
}
