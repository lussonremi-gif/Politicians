import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(url && key);

let client: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (!url || !key) {
    throw new Error("Supabase n'est pas configuré (NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY).");
  }
  if (!client) client = createBrowserClient(url, key);
  return client;
}

/** Traduit les erreurs levées par les fonctions Postgres en messages lisibles. */
export function errorMessage(err: unknown): string {
  const raw = err && typeof err === "object" && "message" in err ? String((err as { message: unknown }).message) : String(err);
  const map: Record<string, string> = {
    "not enough points": "Pas assez de points pour ce booster.",
    "no playable quotes": "Aucune citation vérifiée n'est encore disponible.",
    "empty booster": "Ce booster ne contient encore aucune carte.",
    "already answered": "Vous avez déjà répondu à cette question.",
    "not authenticated": "Connexion en cours, réessayez dans un instant.",
  };
  for (const [k, v] of Object.entries(map)) if (raw.includes(k)) return v;
  return raw;
}
