"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import type { LeaderRow } from "@/lib/types";

function Friends() {
  const { profile, refreshProfile } = useAuth();
  const [username, setUsername] = useState(profile?.username ?? "");
  const [friendCode, setFriendCode] = useState("");
  const [board, setBoard] = useState<LeaderRow[] | null>(null);
  const [message, setMessage] = useState<{ kind: "ok" | "error"; text: string } | null>(null);
  const [copied, setCopied] = useState(false);

  const loadBoard = useCallback(async () => {
    const { data, error } = await getSupabase().rpc("friends_leaderboard");
    if (error) setMessage({ kind: "error", text: errorMessage(error) });
    else setBoard(data as LeaderRow[]);
  }, []);

  useEffect(() => {
    loadBoard();
  }, [loadBoard]);

  useEffect(() => {
    setUsername(profile?.username ?? "");
  }, [profile?.username]);

  async function saveUsername(e: React.FormEvent) {
    e.preventDefault();
    if (!profile) return;
    const { error } = await getSupabase()
      .from("profiles")
      .update({ username: username.trim() || null })
      .eq("id", profile.id);
    if (error) return setMessage({ kind: "error", text: errorMessage(error) });
    setMessage({ kind: "ok", text: "Pseudo enregistré." });
    refreshProfile();
    loadBoard();
  }

  async function addFriend(e: React.FormEvent) {
    e.preventDefault();
    const { data, error } = await getSupabase().rpc("add_friend", { p_friend_code: friendCode.trim() });
    if (error) return setMessage({ kind: "error", text: errorMessage(error) });
    const name = (data as { username: string | null }).username ?? "Joueur anonyme";
    setMessage({ kind: "ok", text: `${name} fait maintenant partie de vos amis.` });
    setFriendCode("");
    loadBoard();
  }

  async function removeFriend(row: LeaderRow) {
    if (!confirm(`Retirer ${row.username} de vos amis ?`)) return;
    const { error } = await getSupabase().rpc("remove_friend", { p_friend: row.user_id });
    if (error) return setMessage({ kind: "error", text: errorMessage(error) });
    loadBoard();
  }

  async function copyCode() {
    if (!profile) return;
    await navigator.clipboard?.writeText(profile.friend_code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <section>
      <div className="section-head">
        <h1 className="headline">Amis</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">Ajoutez vos amis avec leur code et comparez vos scores.</p>
      </div>

      {message && <p className={`notice center ${message.kind === "error" ? "error" : "success"}`}>{message.text}</p>}

      <div className="panel-grid">
        <form className="panel" onSubmit={saveUsername}>
          <h2>Mon pseudo</h2>
          <p className="muted">C&apos;est le nom que voient vos amis et vos adversaires.</p>
          <div className="inline-form">
            <input
              className="input"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Votre pseudo"
              maxLength={20}
              aria-label="Pseudo"
            />
            <button className="btn primary" type="submit">Enregistrer</button>
          </div>
        </form>

        <div className="panel">
          <h2>Mon code ami</h2>
          <p className="muted">À donner à vos amis pour qu&apos;ils vous ajoutent.</p>
          <div className="inline-form">
            <span className="friend-code">{profile?.friend_code ?? "…"}</span>
            <button className="btn" type="button" onClick={copyCode}>{copied ? "Copié !" : "Copier"}</button>
          </div>
        </div>

        <form className="panel" onSubmit={addFriend}>
          <h2>Ajouter un ami</h2>
          <p className="muted">Entrez le code ami qu&apos;il vous a donné.</p>
          <div className="inline-form">
            <input
              className="input code-input"
              value={friendCode}
              onChange={(e) => setFriendCode(e.target.value.toUpperCase())}
              placeholder="EX : 8F2A91C4"
              maxLength={8}
              aria-label="Code ami"
            />
            <button className="btn primary" type="submit" disabled={friendCode.trim().length < 8}>Ajouter</button>
          </div>
        </form>
      </div>

      <div className="panel">
        <h2>Classement entre amis</h2>
        {!board ? (
          <p className="muted">Chargement…</p>
        ) : (
          <>
            <table className="leaderboard">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Joueur</th>
                  <th>Points gagnés</th>
                  <th className="hide-sm">Cartes</th>
                  <th className="hide-sm">Meilleure série</th>
                  <th className="hide-sm">Duels gagnés</th>
                  <th aria-label="Actions" />
                </tr>
              </thead>
              <tbody>
                {board.map((r, i) => (
                  <tr key={r.user_id} className={r.is_me ? "me" : undefined}>
                    <td>{i + 1}</td>
                    <td>{r.username}{r.is_me && " (vous)"}</td>
                    <td>{r.total_points_earned.toLocaleString("fr-FR")}</td>
                    <td className="hide-sm">{r.cards}</td>
                    <td className="hide-sm">{r.best_streak}</td>
                    <td className="hide-sm">{r.duels_won}</td>
                    <td>
                      {!r.is_me && (
                        <button className="link-btn" onClick={() => removeFriend(r)} aria-label={`Retirer ${r.username}`}>
                          Retirer
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {board.length <= 1 && <p className="muted">Pas encore d&apos;amis : partagez votre code ami pour commencer.</p>}
          </>
        )}
        <div className="actions">
          <Link href="/multi" className="btn primary">Défier un ami en multi</Link>
        </div>
      </div>
    </section>
  );
}

export default function FriendsPage() {
  return (
    <Gate>
      <Friends />
    </Gate>
  );
}
