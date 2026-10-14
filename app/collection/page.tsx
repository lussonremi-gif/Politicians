"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Gate } from "@/components/Gate";
import { PoliticianCard } from "@/components/PoliticianCard";
import { QuoteCard } from "@/components/QuoteCard";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { RARITY_LABEL, type Card, type Party, type PoliticianCardData, type Rarity } from "@/lib/types";

type Row = {
  copies: number;
  quotes: {
    id: string;
    text: string;
    rarity: Rarity;
    said_on: string | null;
    occasion: string | null;
    source_label: string | null;
    source_url: string | null;
    theme: string | null;
    is_demo: boolean;
    author: { name: string; description: string | null; kind: "candidate" | "other" } | null;
  } | null;
};

type Owned = Card & { kind: "candidate" | "other" };

const RARITY_ORDER: Rarity[] = ["legendary", "rare", "common"];

function QuotesTab() {
  const [cards, setCards] = useState<Owned[] | null>(null);
  const [totals, setTotals] = useState<Record<Rarity, number>>({ common: 0, rare: 0, legendary: 0 });
  const [filter, setFilter] = useState<string>("all");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const supabase = getSupabase();
      const [own, tot] = await Promise.all([
        supabase
          .from("user_cards")
          .select(
            "copies, quotes(id, text, rarity, said_on, occasion, source_label, source_url, theme, is_demo, author:personalities!quotes_personality_id_fkey(name, description, kind))",
          )
          .order("first_obtained_at", { ascending: false }),
        supabase.rpc("collection_totals"),
      ]);
      if (own.error) return setError(errorMessage(own.error));
      const rows = (own.data ?? []) as unknown as Row[];
      setCards(
        rows
          .filter((r) => r.quotes)
          .map((r) => ({
            quote_id: r.quotes!.id,
            text: r.quotes!.text,
            rarity: r.quotes!.rarity,
            author: r.quotes!.author?.name ?? "—",
            author_description: r.quotes!.author?.description ?? null,
            kind: r.quotes!.author?.kind ?? "other",
            said_on: r.quotes!.said_on,
            occasion: r.quotes!.occasion,
            source_label: r.quotes!.source_label,
            source_url: r.quotes!.source_url,
            theme: r.quotes!.theme,
            is_demo: r.quotes!.is_demo,
            copies: r.copies,
          })),
      );
      if (tot.data) {
        const t = { common: 0, rare: 0, legendary: 0 };
        for (const row of tot.data as { rarity: Rarity; total: number }[]) t[row.rarity] = Number(row.total);
        setTotals(t);
      }
    })();
  }, []);

  // Fiches personnalités : progression par auteur
  const authors = useMemo(() => {
    const m = new Map<string, { name: string; kind: string; count: number }>();
    for (const c of cards ?? []) {
      const e = m.get(c.author) ?? { name: c.author, kind: c.kind, count: 0 };
      e.count += 1;
      m.set(c.author, e);
    }
    return [...m.values()].sort((x, y) => (x.kind === y.kind ? x.name.localeCompare(y.name) : x.kind === "candidate" ? -1 : 1));
  }, [cards]);

  if (error) return <p className="notice error center">{error}</p>;
  if (!cards) return <p className="muted center">Chargement de la collection…</p>;

  const owned = (r: Rarity) => cards.filter((c) => c.rarity === r).length;
  const totalAll = totals.common + totals.rare + totals.legendary;
  const shown = cards
    .filter((c) => filter === "all" || c.author === filter)
    .sort((x, y) => RARITY_ORDER.indexOf(x.rarity) - RARITY_ORDER.indexOf(y.rarity));

  return (
    <section>
      <div className="section-head">
        <p className="lead">
          {cards.length} carte{cards.length > 1 ? "s" : ""} sur {totalAll}
        </p>
        <div className="progress">
          <div style={{ width: `${totalAll ? (cards.length / totalAll) * 100 : 0}%` }} />
        </div>
        <div className="rarity-counts">
          {RARITY_ORDER.map((r) => (
            <span key={r} className={`rarity-pill rarity-${r}`}>
              {RARITY_LABEL[r]} {owned(r)}/{totals[r]}
            </span>
          ))}
        </div>
      </div>

      {cards.length === 0 ? (
        <div className="center">
          <p className="muted">Aucune carte pour l&apos;instant. Chaque bonne réponse vous en rapporte une.</p>
          <div className="actions">
            <Link href="/jouer" className="btn primary">Jouer</Link>
            <Link href="/boosters" className="btn">Ouvrir un booster</Link>
          </div>
        </div>
      ) : (
        <>
          <div className="chips">
            <button className={filter === "all" ? "chip active" : "chip"} onClick={() => setFilter("all")}>
              Toutes
            </button>
            {authors.map((a) => (
              <button key={a.name} className={filter === a.name ? "chip active" : "chip"} onClick={() => setFilter(a.name)}>
                {a.name} <small>{a.count}</small>
              </button>
            ))}
          </div>
          <p className="muted small-text center">Touchez une carte pour voir son contexte et sa source.</p>
          <div className="card-grid">
            {shown.map((c) => (
              <QuoteCard key={c.quote_id} card={c} />
            ))}
          </div>
        </>
      )}
    </section>
  );
}

// ---------------------------------------------------------------------------
// Album des personnalités politiques
// ---------------------------------------------------------------------------
type CatalogRow = {
  id: string;
  rarity: Rarity;
  year: number;
  title: string;
  party_label: string | null;
  politician: {
    slug: string;
    name: string;
    image_url: string | null;
    image_credit: string | null;
    image_license: string | null;
    image_source_url: string | null;
    party: Party | null;
  } | null;
};

type Group = { slug: string; name: string; party: Party | null; cards: PoliticianCardData[]; owned: number };

function PoliticiansTab() {
  const [groups, setGroups] = useState<Group[] | null>(null);
  const [parties, setParties] = useState<Party[]>([]);
  const [filter, setFilter] = useState<string>("all");
  const [onlyOwned, setOnlyOwned] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const supabase = getSupabase();
      const [catalog, mine] = await Promise.all([
        supabase
          .from("politician_cards")
          .select(
            "id, rarity, year, title, party_label, politician:politicians(slug, name, image_url, image_credit, image_license, image_source_url, party:parties(*))",
          ),
        supabase.from("user_politician_cards").select("card_id, copies"),
      ]);
      if (catalog.error) return setError(errorMessage(catalog.error));
      if (mine.error) return setError(errorMessage(mine.error));
      const copies = new Map((mine.data ?? []).map((r: { card_id: string; copies: number }) => [r.card_id, r.copies]));
      const byPol = new Map<string, Group>();
      for (const row of (catalog.data ?? []) as unknown as CatalogRow[]) {
        const p = row.politician;
        if (!p) continue;
        const g = byPol.get(p.slug) ?? { slug: p.slug, name: p.name, party: p.party, cards: [], owned: 0 };
        const owned = copies.get(row.id);
        if (owned) g.owned += 1;
        g.cards.push({
          card_id: row.id,
          rarity: row.rarity,
          year: row.year,
          title: row.title,
          party_label: row.party_label,
          name: p.name,
          politician_slug: p.slug,
          party_name: p.party?.name ?? null,
          party_short: p.party?.short_name ?? null,
          party_color: p.party?.color ?? null,
          image_url: p.image_url,
          image_credit: p.image_credit,
          image_license: p.image_license,
          image_source_url: p.image_source_url,
          copies: owned ?? 0,
        });
        byPol.set(p.slug, g);
      }
      const list = [...byPol.values()];
      for (const g of list) g.cards.sort((a, b) => a.year - b.year);
      list.sort((a, b) => (a.party?.sort_order ?? 99) - (b.party?.sort_order ?? 99) || a.name.localeCompare(b.name));
      setGroups(list);
      const ps = new Map<string, Party>();
      for (const g of list) if (g.party) ps.set(g.party.id, g.party);
      setParties([...ps.values()].sort((a, b) => a.sort_order - b.sort_order));
    })();
  }, []);

  if (error) return <p className="notice error center">{error}</p>;
  if (!groups) return <p className="muted center">Chargement de l&apos;album…</p>;

  const all = groups.flatMap((g) => g.cards);
  const ownedCards = all.filter((c) => (c.copies ?? 0) > 0);
  const countBy = (r: Rarity, list: PoliticianCardData[]) => list.filter((c) => c.rarity === r).length;
  const shown = groups.filter((g) => (filter === "all" || g.party?.id === filter) && (!onlyOwned || g.owned > 0));

  return (
    <>
      <div className="section-head">
        <p className="lead">
          {ownedCards.length} carte{ownedCards.length > 1 ? "s" : ""} sur {all.length}
        </p>
        <div className="progress">
          <div style={{ width: `${all.length ? (ownedCards.length / all.length) * 100 : 0}%` }} />
        </div>
        <div className="rarity-counts">
          {RARITY_ORDER.map((r) => (
            <span key={r} className={`rarity-pill rarity-${r}`}>
              {RARITY_LABEL[r]} {countBy(r, ownedCards)}/{countBy(r, all)}
            </span>
          ))}
        </div>
      </div>

      <div className="chips">
        <button className={filter === "all" ? "chip active" : "chip"} onClick={() => setFilter("all")}>
          Tous les partis
        </button>
        {parties.map((p) => (
          <button
            key={p.id}
            className={filter === p.id ? "chip active" : "chip"}
            style={{ ["--party" as string]: p.color }}
            onClick={() => setFilter(p.id)}
          >
            <span className="party-dot" aria-hidden /> {p.short_name}
          </button>
        ))}
        <label className="chip toggle">
          <input type="checkbox" checked={onlyOwned} onChange={(e) => setOnlyOwned(e.target.checked)} /> Mes cartes
        </label>
      </div>
      <p className="muted small-text center">
        Chaque personnalité existe en trois versions : la plus ancienne est légendaire. Touchez une carte obtenue pour
        voir son verso.
      </p>

      {shown.length === 0 && (
        <div className="center">
          <p className="muted">Aucune carte ici pour l&apos;instant.</p>
          <Link href="/boosters" className="btn primary">Ouvrir un booster</Link>
        </div>
      )}

      {shown.map((g) => (
        <section key={g.slug} className="album-row" style={{ ["--party" as string]: g.party?.color ?? "#7a7d85" }}>
          <header>
            <h3>{g.name}</h3>
            {g.party && <span className="album-party">{g.party.name}</span>}
            <span className="album-count">{g.owned}/{g.cards.length}</span>
          </header>
          <div className="album-cards">
            {g.cards.map((c) => (
              <PoliticianCard key={c.card_id} card={c} locked={!c.copies} />
            ))}
          </div>
        </section>
      ))}
    </>
  );
}

function Collection() {
  const [tab, setTab] = useState<"politicians" | "quotes">("politicians");
  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Ma collection</h1>
        <span className="tricolor" aria-hidden />
        <div className="tabs" role="tablist">
          <button role="tab" aria-selected={tab === "politicians"} className={tab === "politicians" ? "active" : ""} onClick={() => setTab("politicians")}>
            Personnalités
          </button>
          <button role="tab" aria-selected={tab === "quotes"} className={tab === "quotes" ? "active" : ""} onClick={() => setTab("quotes")}>
            Citations
          </button>
        </div>
      </div>
      {tab === "politicians" ? <PoliticiansTab /> : <QuotesTab />}
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
