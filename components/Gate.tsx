"use client";

import { useAuth } from "./AuthProvider";

/** Attend la session invitée avant d'afficher le contenu qui dépend de Supabase. */
export function Gate({ children }: { children: React.ReactNode }) {
  const { ready, error } = useAuth();
  if (!ready) return <p className="muted center">Chargement…</p>;
  if (error) return <p className="notice error center">{error}</p>;
  return <>{children}</>;
}
