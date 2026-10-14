"use client";

import { useState } from "react";
import { useAuth } from "./AuthProvider";
import { errorMessage, getSupabase } from "@/lib/supabase";

const USERNAME_PATTERN = /^[\p{L}\p{N}_ .\-]{2,20}$/u;

/** Première ouverture : un pseudo, puis le jeu. */
export function RequireAccount({ children }: { children: React.ReactNode }) {
  const { ready, error, profile, refreshProfile } = useAuth();
  const [username, setUsername] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  if (!ready) return <p className="muted center">Chargement…</p>;
  if (error) return <p className="notice error center">{error}</p>;
  if (!profile) return <p className="muted center">Chargement du compte…</p>;
  if (profile.username) return <>{children}</>;

  const profileId = profile.id;

  async function create(e: React.FormEvent) {
    e.preventDefault();
    const next = username.trim();
    if (!USERNAME_PATTERN.test(next)) {
      setMessage("2 à 20 caractères : lettres, chiffres, espace, _ . -");
      return;
    }
    setSaving(true);
    const { error: saveError } = await getSupabase().from("profiles").update({ username: next }).eq("id", profileId);
    setSaving(false);
    if (saveError) return setMessage(errorMessage(saveError));
    await refreshProfile();
  }

  return (
    <section className="account-gate">
      <form className="panel account-setup" onSubmit={create}>
        <p className="brand-title">
          Présidentielle <span className="blue">20</span><span className="red">27</span>
        </p>
        <h1 className="headline">Choisissez un pseudo</h1>
        <p className="muted">C&apos;est votre compte. Ensuite vous pouvez jouer et défier un ami.</p>
        {message && <p className="notice error">{message}</p>}
        <div className="inline-form">
          <input
            className="input"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Votre pseudo"
            maxLength={20}
            autoFocus
            aria-label="Pseudo"
            required
          />
          <button className="btn primary" type="submit" disabled={saving || username.trim().length < 2}>
            {saving ? "…" : "Entrer"}
          </button>
        </div>
      </form>
    </section>
  );
}
