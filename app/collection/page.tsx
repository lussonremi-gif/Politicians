"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { CardPager } from "@/components/CardPager";
import { CollectibleCard } from "@/components/CollectibleCard";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { asRarity } from "@/lib/cardArt";
import { RARITIES, RARITY_LABEL, type GameCard, type Rarity } from "@/lib/types";

type AlbumRow = GameCard & { copies: number; party_sort: number | null };

// De la plus rare à la plus commune
const TABS: Rarity[] = [...RARITIES].reverse();

function Collection() {
  const [rows, setRows] = useState<AlbumRow[] | null>(null);
  // « all » : toutes les cartes d'un coup, de la plus rare à la plus commune
  const [rarity, setRarity] = useState<Rarity | "all">("all");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSupabase()
      .rpc("collection_album")
      .then(({ data, error }) => {
        if (error) setError(errorMessage(error));
        else setRows(((data as AlbumRow[]) ?? []).map((r) => ({ ...r, rarity: asRarity(r.rarity) })));
      });
  }, []);

  const byRarity = useMemo(() => {
    const m = new Map<Rarity, AlbumRow[]>(TABS.map((r) => [r, []]));
    for (const r of rows ?? []) m.get(r.rarity)!.push(r);
    // Cartes obtenues d'abord, puis par nom
    for (const list of m.values()) list.sort((a, b) => Number(b.copies > 0) - Number(a.copies > 0) || a.name.localeCompare(b.name));
    return m;
  }, [rows]);

  if (error) return <p className="notice error center">{error}</p>;
  if (!rows) return <p className="muted center">Chargement de l&apos;album…</p>;

  const owned = rows.filter((r) => r.copies > 0).length;
  const active = rarity;
  const list = active === "all" ? TABS.flatMap((r) => byRarity.get(r)!) : byRarity.get(active)!;

  return (
    <section className="collection fit">
      <div className="fit-head">
        <h1 className="headline">Ma collection</h1>
        <p className="collection-count">
          <strong>{owned}</strong> / {rows.length} cartes
        </p>
        <div className="progress">
          <div style={{ width: `${rows.length ? (owned / rows.length) * 100 : 0}%` }} />
        </div>
        <div className="rarity-tabs" role="tablist">
          <button
            role="tab"
            aria-selected={active === "all"}
            className={`rarity-tab ${active === "all" ? "active" : ""}`}
            onClick={() => setRarity("all")}
          >
            <span>Toutes</span>
            <small>
              {owned}/{rows.length}
            </small>
          </button>
          {TABS.map((r) => {
            const all = byRarity.get(r)!;
            return (
              <button
                key={r}
                role="tab"
                aria-selected={active === r}
                className={`rarity-tab rarity-${r} ${active === r ? "active" : ""}`}
                onClick={() => setRarity(r)}
              >
                <span>{RARITY_LABEL[r]}</span>
                <small>
                  {all.filter((c) => c.copies > 0).length}/{all.length}
                </small>
              </button>
            );
          })}
        </div>
      </div>

      {list.length === 0 ? (
        <div className="center fit-body">
          <p className="muted">Aucune carte de cette rareté pour l&apos;instant.</p>
          <div className="actions">
            <Link href="/jouer" className="btn primary">Jouer</Link>
            <Link href="/boosters" className="btn">Ouvrir un booster</Link>
          </div>
        </div>
      ) : active === "all" ? (
        <div className="album-all">
          {list.map((c) => (
            <div key={c.card_id} className="album-all-cell">
              <CollectibleCard card={c} locked={c.copies === 0} />
            </div>
          ))}
        </div>
      ) : (
        <CardPager
          items={list}
          resetKey={active}
          render={(c) => <CollectibleCard key={c.card_id} card={c} locked={c.copies === 0} />}
        />
      )}
    </section>
  );
}

export default function CollectionPage() {
  return (
    <Gate>
      <Collection />
    </Gate>
  );
}
