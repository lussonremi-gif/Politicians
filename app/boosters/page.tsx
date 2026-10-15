"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { BoosterOpening } from "@/components/BoosterOpening";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { asRarity } from "@/lib/cardArt";
import { RARITIES, RARITY_LABEL, type BoosterType, type OpenedCard, type Rarity } from "@/lib/types";

type Opened = { booster: BoosterType; cards: OpenedCard[] };

// Couleur et rareté mise en avant de chaque booster
const RARITY_ACCENT: Record<Rarity, string> = { common: "#6b7280", rare: "#2f5bd3", epic: "#7b3fc4", legendary: "#c9971d" };

function boosterRarity(b: BoosterType): Rarity {
  if (b.guarantee) return asRarity(b.guarantee);
  const bySlug: Record<string, Rarity> = { "rarete-legendaire": "legendary", "rarete-epique": "epic", "rarete-rare": "rare" };
  return bySlug[b.slug] ?? "common";
}

function boosterAccent(b: BoosterType) {
  return RARITY_ACCENT[boosterRarity(b)];
}

/** Probabilités par carte, ramenées aux quatre raretés. */
function odds(b: BoosterType) {
  const raw = (b.weights ?? {}) as Record<string, number>;
  const folded: Record<Rarity, number> = { common: 0, rare: 0, epic: 0, legendary: 0 };
  for (const [k, v] of Object.entries(raw)) folded[asRarity(k)] += v;
  return RARITIES.filter((r) => folded[r] > 0).map((r) => ({ r, p: folded[r] }));
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
  const rarity = boosterRarity(b);
  return (
    <article className={`booster rarity-booster rb-${rarity}`} style={{ ["--accent" as string]: boosterAccent(b) }}>
      <div className="booster-pack" aria-hidden>
        <span className="tricolor small" />
        <span className="pack-rarity">{RARITY_LABEL[rarity]}</span>
        <span className="pack-label">{b.card_count} cartes</span>
      </div>
      <h3>{b.name}</h3>
      <p className="booster-guarantee">{b.guarantee ? `Au moins 1 ${RARITY_LABEL[rarity].toLowerCase()}` : "Pour compléter sa collection"}</p>
      <ul className="odds-bars" aria-label="Probabilités par carte">
        {odds(b).map(({ r, p }) => (
          <li key={r} className={`odd rarity-${r}`}>
            <span>{RARITY_LABEL[r]}</span>
            <i style={{ width: `${p}%` }} />
            <b>{p}%</b>
          </li>
        ))}
      </ul>
      <button className="btn primary" disabled={points < b.price || busy} onClick={() => onOpen(b)}>
        Ouvrir · {b.price.toLocaleString("fr-FR")} 🪙
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

  return (
    <section className="shop fit">
      <div className="fit-head">
        <h1 className="headline">Boosters</h1>
        <p className="collection-count">
          Vous avez <strong>{points.toLocaleString("fr-FR")} 🪙</strong> · plus le booster est rare, plus la citation est culte
        </p>
      </div>

      {error && <p className="notice error center">{error}</p>}

      <div className="booster-grid rarity-grid">
        {boosters.map((b) => (
          <BoosterTile key={b.slug} b={b} points={points} busy={busy} onOpen={open} />
        ))}
      </div>

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
