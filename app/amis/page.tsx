"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";
import { Gate } from "@/components/Gate";
import { errorMessage, getSupabase } from "@/lib/supabase";
import type { LeaderRow } from "@/lib/types";

function normalizeFriendInput(raw: string): string {
  const text = raw.trim();
  const fromLink = text.match(/[?&]ajouter=([A-Za-z0-9]+)/i);
  const token = (fromLink ? fromLink[1] : text).replace(/\s+/g, "");
  return token.toUpperCase();
}

function Friends() {
  const { profile } = useAuth();
  const [friendInput, setFriendInput] = useState("");
  const [board, setBoard] = useState<LeaderRow[] | null>(null);
  const [message, setMessage] = useState<{ kind: "ok" | "error"; text: string } | null>(null);
  const [copied, setCopied] = useState<"code" | "link" | null>(null);
  const invited = useRef<string | null>(null);

  const loadBoard = useCallback(async () => {
    const { data, error } = await getSupabase().rpc("friends_leaderboard");
    if (error) setMessage({ kind: "error", text: errorMessage(error) });
    else setBoard(data as LeaderRow[]);
  }, []);

  useEffect(() => {
    if (profile?.username) loadBoard();
  }, [loadBoard, profile?.username]);

  const addFriendCode = useCallback(async (raw: string) => {
    const token = normalizeFriendInput(raw);
    if (token.length < 8) {
      setMessage({ kind: "error", text: "Indiquez un code ami (8 caractères) ou un lien d'invitation." });
      return false;
    }
    const { data, error } = await getSupabase().rpc("add_friend", { p_friend_code: token });
    if (error) {
      setMessage({ kind: "error", text: errorMessage(error) });
      return false;
    }
    const name = (data as { username: string | null }).username ?? "Joueur anonyme";
    setMessage({ kind: "ok", text: `${name} fait maintenant partie de vos amis.` });
    setFriendInput("");
    await loadBoard();
    return true;
  }, [loadBoard]);

  useEffect(() => {
    if (!profile?.username) return;
    const code = new URLSearchParams(window.location.search).get("ajouter");
    if (!code || invited.current === code.toUpperCase()) return;
    invited.current = code.toUpperCase();
    void addFriendCode(code).then((ok) => {
      if (!ok) {
        invited.current = null;
        return;
      }
      const url = new URL(window.location.href);
      url.searchParams.delete("ajouter");
      window.history.replaceState(null, "", `${url.pathname}${url.search}`);
    });
  }, [profile?.username, addFriendCode]);

  async function addFriend(e: React.FormEvent) {
    e.preventDefault();
    await addFriendCode(friendInput);
  }

  async function removeFriend(row: LeaderRow) {
    if (!confirm(`Retirer ${row.username} de vos amis ?`)) return;
    const { error } = await getSupabase().rpc("remove_friend", { p_friend: row.user_id });
    if (error) return setMessage({ kind: "error", text: errorMessage(error) });
    setMessage({ kind: "ok", text: `${row.username} a été retiré de vos amis.` });
    loadBoard();
  }

  async function copy(kind: "code" | "link") {
    if (!profile) return;
    const value = kind === "code" ? profile.friend_code : `${window.location.origin}/amis?ajouter=${profile.friend_code}`;
    await navigator.clipboard?.writeText(value);
    setCopied(kind);
    setTimeout(() => setCopied(null), 2000);
  }

  if (!profile) return <p className="muted center">Chargement du compte…</p>;

  const friends = (board ?? []).filter((row) => !row.is_me);

  return (
    <section className="screen-fit">
      <div className="section-head compact">
        <h1 className="headline">Amis</h1>
        <p className="lead">Code, invitations et classement.</p>
      </div>

      {message && <p className={`notice center ${message.kind === "error" ? "error" : "success"}`}>{message.text}</p>}

      <div className="panel-grid friends-top">
        <div className="panel">
          <h2>Mon code ami</h2>
          <div className="inline-form">
            <span className="friend-code">{profile.friend_code}</span>
            <button className="btn" type="button" onClick={() => copy("code")}>{copied === "code" ? "Copié !" : "Copier"}</button>
            <button className="btn" type="button" onClick={() => copy("link")}>{copied === "link" ? "Lien copié !" : "Lien"}</button>
          </div>
        </div>

        <form className="panel" onSubmit={addFriend}>
          <h2>Ajouter un ami</h2>
          <div className="inline-form">
            <input
              className="input"
              value={friendInput}
              onChange={(e) => setFriendInput(e.target.value)}
              placeholder="Code ou lien"
              aria-label="Code ami ou lien d'invitation"
            />
            <button className="btn primary" type="submit" disabled={normalizeFriendInput(friendInput).length < 8}>
              Ajouter
            </button>
          </div>
        </form>
      </div>

      <div className="split-panels friends-bottom">
        <div className="panel">
          <h2>Mes amis</h2>
          {!board ? (
            <p className="muted">Chargement…</p>
          ) : friends.length === 0 ? (
            <p className="muted">Pas encore d&apos;amis. Partagez votre lien ou collez le leur.</p>
          ) : (
            <ul className="friend-list">
              {friends.map((row) => (
                <li key={row.user_id}>
                  <span>{row.username}</span>
                  <button className="link-btn" onClick={() => removeFriend(row)} aria-label={`Retirer ${row.username}`}>
                    Retirer
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="panel">
          <h2>Classement</h2>
          {!board ? (
            <p className="muted">Chargement…</p>
          ) : (
            <>
              <div className="leaderboard-wrap">
                <table className="leaderboard">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Joueur</th>
                      <th>Points</th>
                      <th className="hide-sm">Cartes</th>
                      <th className="hide-sm">Duels</th>
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
              </div>
              {friends.length === 0 && <p className="muted">Le classement se remplit dès qu&apos;un ami est ajouté.</p>}
            </>
          )}
          <div className="actions">
            <Link href="/jouer?mode=duel" className="btn primary">Défier en duel</Link>
          </div>
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
