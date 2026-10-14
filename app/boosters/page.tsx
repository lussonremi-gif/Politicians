"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { BoosterOpening } from "@/components/BoosterOpening";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import type { BoosterType, OpenedCard } from "@/lib/types";

type Opened = { booster: BoosterType; cards: OpenedCard[] };

function BoosterTile({
  b,
  points,
  busy,
  onOpen,
}: {
  b: BoosterType;
  points: number;
  busy: boolean;
  onOpen: (b: BoosterType) => void;
}) {
  const accent = b.party?.color ?? (b.kind === "quotes" ? "#2f5597" : b.slug === "premium" ? "#b8892b" : "#141b2d");
  return (
    <article className={`booster ${b.kind}`} style={{ ["--accent" as string]: accent }}>
      <div className="booster-pack" aria-hidden>
        <span className="tricolor small" />
        <span className="pack-count">{b.card_count}</span>
        <span className="pack-label">{b.kind === "quotes" ? "citations" : "cartes"}</span>
        {b.party && <span className="pack-party">{b.party.short_name}</span>}
      </div>
      <h3>{b.name}</h3>
      {b.description && <p className="muted">{b.description}</p>}
      <p className="odds">
        Commune {b.weight_common}% · Rare {b.weight_rare}% · Légendaire {b.weight_legendary}%
      </p>
      <button className="btn primary" disabled={points < b.price || busy} onClick={() => onOpen(b)}>
        Ouvrir · {b.price} pts
      </button>
    </article>
  );
}

function Boosters() {
  const { profile, setPoints } = useAuth();
  const [boosters, setBoosters] = useState<BoosterType[]>([]);
  const [busy, setBusy] = useState(false);
  const [opened, setOpened] = useState<Opened | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSupabase()
      .from("booster_types")
      .select("*, party:parties(*)")
      .eq("active", true)
      .order("sort_order")
      .order("price")
      .then(({ data, error }) => {
        if (error) setError(errorMessage(error));
        else setBoosters(data as BoosterType[]);
      });
  }, []);

  async function open(b: BoosterType) {
    setBusy(true);
    setError(null);
    try {
      const { data, error } = await getSupabase().rpc("open_booster", { p_slug: b.slug });
      if (error) throw error;
      const res = data as { cards: OpenedCard[]; points_left: number };
      setPoints(res.points_left);
      setOpened({ booster: b, cards: res.cards });
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  const points = profile?.points ?? 0;
  const general = boosters.filter((b) => b.kind === "politicians" && !b.party_id);
  const byParty = boosters.filter((b) => b.kind === "politicians" && b.party_id);
  const quotes = boosters.filter((b) => b.kind === "quotes");

  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Boosters</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">
          Vous avez <strong>{points.toLocaleString("fr-FR")} points</strong>. Chaque personnalité existe en plusieurs
          versions : plus elle est ancienne, plus elle est rare.
        </p>
      </div>

      {error && <p className="notice error center">{error}</p>}

      {general.length > 0 && (
        <>
          <h2 className="shop-title">Personnalités politiques</h2>
          <div className="booster-grid">
            {general.map((b) => (
              <BoosterTile key={b.slug} b={b} points={points} busy={busy} onOpen={open} />
            ))}
          </div>
        </>
      )}

      {byParty.length > 0 && (
        <>
          <h2 className="shop-title">Par parti</h2>
          <div className="booster-grid">
            {byParty.map((b) => (
              <BoosterTile key={b.slug} b={b} points={points} busy={busy} onOpen={open} />
            ))}
          </div>
        </>
      )}

      {quotes.length > 0 && (
        <>
          <h2 className="shop-title">Citations</h2>
          <div className="booster-grid">
            {quotes.map((b) => (
              <BoosterTile key={b.slug} b={b} points={points} busy={busy} onOpen={open} />
            ))}
          </div>
        </>
      )}

      {opened && (
        <BoosterOpening
          cards={opened.cards}
          boosterName={opened.booster.name}
          accent={opened.booster.party?.color ?? (opened.booster.slug === "premium" ? "#b8892b" : "#2f5597")}
          onClose={() => setOpened(null)}
        />
      )}
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
