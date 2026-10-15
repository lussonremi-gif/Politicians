"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";

const USERNAME_PATTERN = /^[\p{L}\p{N}_ .\-]{2,20}$/u;

function Account() {
  const { profile, refreshProfile } = useAuth();
  const [username, setUsername] = useState(profile?.username ?? "");
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ kind: "ok" | "error"; text: string } | null>(null);
  const [copied, setCopied] = useState(false);
  const [ownedCards, setOwnedCards] = useState<number | null>(null);

  useEffect(() => {
    setUsername(profile?.username ?? "");
  }, [profile?.username]);

  useEffect(() => {
    getSupabase()
      .rpc("my_album")
      .then(({ data }) => {
        const rows = (data as { copies: number }[] | null) ?? [];
        setOwnedCards(rows.filter((r) => r.copies > 0).length);
      });
  }, [profile?.id, profile?.points]);

  if (!profile) return <p className="muted center">Chargement du compte…</p>;

  async function saveUsername(e: React.FormEvent) {
    e.preventDefault();
    const next = username.trim();
    if (!USERNAME_PATTERN.test(next)) {
      setMessage({ kind: "error", text: "Pseudo invalide : 2 à 20 caractères (lettres, chiffres, espace, _ . -)." });
      return;
    }
    setSaving(true);
    const { error } = await getSupabase().from("profiles").update({ username: next }).eq("id", profile!.id);
    setSaving(false);
    if (error) return setMessage({ kind: "error", text: errorMessage(error) });
    setMessage({ kind: "ok", text: "Pseudo enregistré." });
    await refreshProfile();
  }

  async function copyCode() {
    await navigator.clipboard?.writeText(profile!.friend_code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  const winRate =
    profile.duels_played > 0 ? Math.round((profile.duels_won / profile.duels_played) * 100) : null;

  return (
    <section className="screen-fit">
      <div className="section-head compact">
        <h1 className="headline">Mon compte</h1>
      </div>

      {message && <p className={`notice center ${message.kind === "error" ? "error" : "success"}`}>{message.text}</p>}

      <div className="panel-grid account-grid">
        <form className="panel" onSubmit={saveUsername}>
          <h2>Pseudo</h2>
          <div className="inline-form">
            <input
              className="input"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Votre pseudo"
              maxLength={20}
              aria-label="Pseudo"
            />
            <button className="btn primary" type="submit" disabled={saving}>
              Enregistrer
            </button>
          </div>
        </form>

        <div className="panel">
          <h2>Points</h2>
          <p className="account-points">{profile.points.toLocaleString("fr-FR")}</p>
          <p className="muted small-text">
            {profile.total_points_earned.toLocaleString("fr-FR")} gagnés · <Link href="/boosters">boosters</Link>
          </p>
        </div>

        <div className="panel">
          <h2>Code ami</h2>
          <div className="inline-form">
            <span className="friend-code">{profile.friend_code}</span>
            <button className="btn" type="button" onClick={copyCode}>
              {copied ? "Copié !" : "Copier"}
            </button>
          </div>
          <p className="muted small-text" style={{ marginTop: 8 }}>
            Amis et classement → <Link href="/amis">Amis</Link>
          </p>
        </div>
      </div>

      <div className="panel account-stats">
        <h2>Stats de jeu</h2>
        <div className="stats">
          <div>
            <strong>{profile.games_played}</strong>
            <span>parties solo</span>
          </div>
          <div>
            <strong>{profile.duels_played}</strong>
            <span>duels joués</span>
          </div>
          <div>
            <strong>{profile.duels_won}</strong>
            <span>duels gagnés{winRate !== null ? ` · ${winRate} %` : ""}</span>
          </div>
          <div>
            <strong>{ownedCards ?? "—"}</strong>
            <span>cartes obtenues</span>
          </div>
        </div>
        <div className="actions">
          <Link href="/collection" className="btn">
            Collection
          </Link>
          <Link href="/amis" className="btn">
            Amis
          </Link>
          <Link href="/boosters" className="btn primary">
            Boosters
          </Link>
        </div>
      </div>
    </section>
  );
}

export default function ComptePage() {
  return (
    <Gate>
      <Account />
    </Gate>
  );
}
