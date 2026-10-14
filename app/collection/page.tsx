"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Gate } from "@/components/Gate";
import { QuoteCard } from "@/components/QuoteCard";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { RARITY_LABEL, type Card, type Rarity } from "@/lib/types";

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

function Collection() {
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
        <h1 className="headline">Ma collection</h1>
        <span className="tricolor" aria-hidden />
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

export default function CollectionPage() {
  return (
    <Gate>
      <Collection />
    </Gate>
  );
}
