"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { CollectibleCard } from "@/components/CollectibleCard";
import { Gate } from "@/components/Gate";
import { Photo } from "@/components/Photo";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { asRarity } from "@/lib/cardArt";
import { RARITIES, RARITY_LABEL, RARITY_RANK, type GameCard, type Rarity } from "@/lib/types";

type AlbumRow = GameCard & { copies: number; party_sort: number | null };

type Group = {
  slug: string;
  name: string;
  role: string | null;
  image_url: string | null;
  party_name: string | null;
  party_color: string | null;
  party_sort: number;
  cards: AlbumRow[];
  owned: number;
};

function Collection() {
  const [rows, setRows] = useState<AlbumRow[] | null>(null);
  const [party, setParty] = useState<string>("all");
  const [rarity, setRarity] = useState<Rarity | "all">("all");
  const [onlyOwned, setOnlyOwned] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSupabase()
      .rpc("my_album")
      .then(({ data, error }) => {
        if (error) setError(errorMessage(error));
        else setRows((data as AlbumRow[]) ?? []);
      });
  }, []);

  const groups = useMemo(() => {
    const byPol = new Map<string, Group>();
    for (const r of rows ?? []) {
      const g = byPol.get(r.politician_slug) ?? {
        slug: r.politician_slug,
        name: r.name,
        role: r.role,
        image_url: r.image_url,
        party_name: r.party_name,
        party_color: r.party_color,
        party_sort: r.party_sort ?? 99,
        cards: [],
        owned: 0,
      };
      g.cards.push(r);
      if (r.copies > 0) g.owned += 1;
      byPol.set(r.politician_slug, g);
    }
    const list = [...byPol.values()];
    for (const g of list) g.cards.sort((a, b) => RARITY_RANK[asRarity(b.rarity)] - RARITY_RANK[asRarity(a.rarity)]);
    // Les personnalités les plus complètes d'abord, puis par nom
    return list.sort((a, b) => b.owned - a.owned || a.name.localeCompare(b.name));
  }, [rows]);

  const parties = useMemo(() => {
    const m = new Map<string, { name: string; color: string; sort: number }>();
    for (const g of groups) if (g.party_name) m.set(g.party_name, { name: g.party_name, color: g.party_color ?? "#8d939c", sort: g.party_sort });
    return [...m.values()].sort((a, b) => a.sort - b.sort);
  }, [groups]);

  if (error) return <p className="notice error center">{error}</p>;
  if (!rows) return <p className="muted center">Chargement de l&apos;album…</p>;

  const owned = rows.filter((r) => r.copies > 0);
  const countBy = (r: Rarity, list: AlbumRow[]) => list.filter((c) => asRarity(c.rarity) === r).length;

  const shown = groups
    .filter((g) => party === "all" || g.party_name === party || (party === "none" && !g.party_name))
    .map((g) => ({
      ...g,
      cards: g.cards.filter((c) => (rarity === "all" || asRarity(c.rarity) === rarity) && (!onlyOwned || c.copies > 0)),
    }))
    .filter((g) => g.cards.length > 0);

  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Ma collection</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">
          {owned.length} carte{owned.length > 1 ? "s" : ""} sur {rows.length}. Chaque carte associe une personnalité à
          l&apos;une de ses citations ; plus la phrase a marqué les esprits, plus elle est rare.
        </p>
        <div className="progress">
          <div style={{ width: `${rows.length ? (owned.length / rows.length) * 100 : 0}%` }} />
        </div>
        <div className="rarity-counts">
          {[...RARITIES].reverse().map((r) => (
            <button
              key={r}
              className={`rarity-pill rarity-${r} ${rarity === r ? "active" : ""}`}
              onClick={() => setRarity(rarity === r ? "all" : r)}
              aria-pressed={rarity === r}
            >
              {RARITY_LABEL[r]} {countBy(r, owned)}/{countBy(r, rows)}
            </button>
          ))}
        </div>
      </div>

      <div className="chips">
        <button className={party === "all" ? "chip active" : "chip"} onClick={() => setParty("all")}>
          Tous
        </button>
        {parties.map((p) => (
          <button
            key={p.name}
            className={party === p.name ? "chip active" : "chip"}
            style={{ ["--party" as string]: p.color }}
            onClick={() => setParty(p.name)}
          >
            <span className="party-dot" aria-hidden /> {p.name}
          </button>
        ))}
        <button className={party === "none" ? "chip active" : "chip"} onClick={() => setParty("none")}>
          Autres
        </button>
        <label className="chip toggle">
          <input type="checkbox" checked={onlyOwned} onChange={(e) => setOnlyOwned(e.target.checked)} /> Mes cartes
        </label>
      </div>
      <p className="muted small-text center">
        Les citations se découvrent en jouant ou en ouvrant des boosters. Touchez une carte obtenue pour voir sa date et
        sa source.
      </p>

      {shown.length === 0 && (
        <div className="center">
          <p className="muted">Aucune carte ici pour l&apos;instant.</p>
          <div className="actions">
            <Link href="/jouer" className="btn primary">Jouer</Link>
            <Link href="/boosters" className="btn">Ouvrir un booster</Link>
          </div>
        </div>
      )}

      {shown.map((g) => (
        <section key={g.slug} className="album-row" style={{ ["--party" as string]: g.party_color ?? "#8d939c" }}>
          <header>
            <span className="album-avatar">
              <Photo src={g.image_url} name={g.name} />
            </span>
            <div>
              <h3>{g.name}</h3>
              <span className="album-party">{[g.role, g.party_name].filter(Boolean).join(" · ")}</span>
            </div>
            <span className="album-count">
              {g.owned}/{rows.filter((r) => r.politician_slug === g.slug).length}
            </span>
          </header>
          <div className="album-cards">
            {g.cards.map((c) => (
              <CollectibleCard key={c.card_id} card={c} locked={c.copies === 0} />
            ))}
          </div>
        </section>
      ))}
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
