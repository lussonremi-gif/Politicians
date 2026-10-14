"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { BoosterOpening } from "@/components/BoosterOpening";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { RARITIES, RARITY_LABEL, type BoosterType, type OpenedCard } from "@/lib/types";

type Opened = { booster: BoosterType; cards: OpenedCard[] };

function boosterAccent(b: BoosterType) {
  if (b.party?.color) return b.party.color;
  if (b.slug === "premium") return "#b8892b";
  if (b.tag === "president") return "#2f5597";
  if (b.theme) return "#6b3fa0";
  return "#141b2d";
}

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
  const accent = boosterAccent(b);
  const raw = b.weights as (Partial<Record<(typeof RARITIES)[number], number>> & { uncommon?: number }) | null;
  const folded = raw
    ? { ...raw, common: (raw.common ?? 0) + (raw.uncommon ?? 0) }
    : null;
  const odds = folded
    ? RARITIES.filter((r) => (folded[r] ?? 0) > 0)
        .map((r) => `${RARITY_LABEL[r]} ${folded[r]}%`)
        .join(" · ")
    : `Commune ${b.weight_common}% · Rare ${b.weight_rare}% · Légendaire ${b.weight_legendary}%`;
  return (
    <article className={`booster ${b.kind}`} style={{ ["--accent" as string]: accent }}>
      <div className="booster-pack" aria-hidden>
        <span className="tricolor small" />
        <span className="pack-count">{b.card_count}</span>
        <span className="pack-label">cartes</span>
        {b.party && <span className="pack-party">{b.party.short_name}</span>}
      </div>
      <h3>{b.name}</h3>
      {b.description && <p className="muted">{b.description}</p>}
      <p className="odds">{odds}</p>
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
  const general = boosters.filter((b) => !b.party_id && !b.tag && !b.theme);
  const special = boosters.filter((b) => !b.party_id && (b.tag || b.theme));
  const byParty = boosters.filter((b) => b.party_id);

  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Boosters</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">
          Vous avez <strong>{points.toLocaleString("fr-FR")} points</strong>. Chaque carte associe une personnalité à
          l&apos;une de ses citations : plus la phrase est culte, plus elle est rare.
        </p>
      </div>

      {error && <p className="notice error center">{error}</p>}

      {general.length > 0 && (
        <>
          <h2 className="shop-title">Boosters</h2>
          <div className="booster-grid">
            {general.map((b) => (
              <BoosterTile key={b.slug} b={b} points={points} busy={busy} onOpen={open} />
            ))}
          </div>
        </>
      )}

      {special.length > 0 && (
        <>
          <h2 className="shop-title">Éditions spéciales</h2>
          <div className="booster-grid">
            {special.map((b) => (
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

      {opened && (
        <BoosterOpening
          cards={opened.cards}
          boosterName={opened.booster.name}
          accent={boosterAccent(opened.booster)}
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
