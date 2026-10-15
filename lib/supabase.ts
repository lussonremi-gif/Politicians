import { createBrowserClient } from "@supabase/ssr";
import type { Session, SupabaseClient } from "@supabase/supabase-js";

// Projet Supabase « Politicians ». L'URL et la clé publishable sont publiques par nature
// (elles sont envoyées à chaque navigateur) : la sécurité repose sur la RLS et les fonctions Postgres.
// Les variables d'environnement permettent de pointer vers un autre projet (ex. une branche de test).
const DEFAULT_URL = "https://kycouzwgzxmpnhzywrrh.supabase.co";
const DEFAULT_KEY = "sb_publishable__PgAYkv6qV3ihWrALzUtHg_3a8Ih9XC";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_URL;
const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || DEFAULT_KEY;

export const isSupabaseConfigured = Boolean(url && key);

let client: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (!url || !key) {
    throw new Error("Supabase n'est pas configuré (NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY).");
  }
  if (!client) client = createBrowserClient(url, key);
  return client;
}

const BACKUP_KEY = "qui-la-dit-session";

type Tokens = { access_token: string; refresh_token: string };

/** Garde une copie de la session : si le cookie disparaît au rafraîchissement, on restaure le même compte. */
export function rememberSession(session: Pick<Session, "access_token" | "refresh_token">) {
  if (typeof window === "undefined") return;
  const backup: Tokens = { access_token: session.access_token, refresh_token: session.refresh_token };
  window.localStorage.setItem(BACKUP_KEY, JSON.stringify(backup));
}

function parseTokens(raw: string | null): Tokens | null {
  if (!raw) return null;
  try {
    const json = raw.startsWith("base64-") ? decodeBase64Url(raw.slice("base64-".length)) : raw;
    const parsed = JSON.parse(json) as Partial<Tokens>;
    if (!parsed.access_token || !parsed.refresh_token) return null;
    return { access_token: parsed.access_token, refresh_token: parsed.refresh_token };
  } catch {
    return null;
  }
}

function decodeBase64Url(value: string): string {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/");
  const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function readCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const all = document.cookie.split("; ").flatMap((part) => {
    const eq = part.indexOf("=");
    if (eq === -1) return [];
    const key = part.slice(0, eq);
    const value = part.slice(eq + 1);
    try {
      return [[decodeURIComponent(key), decodeURIComponent(value)] as const];
    } catch {
      return [[key, value] as const];
    }
  });
  const direct = all.find(([key]) => key === name);
  if (direct) return direct[1];
  const chunks: string[] = [];
  for (let i = 0; ; i++) {
    const chunk = all.find(([key]) => key === `${name}.${i}`);
    if (!chunk) break;
    chunks.push(chunk[1]);
  }
  return chunks.length > 0 ? chunks.join("") : null;
}

function readCookieSession(): Tokens | null {
  let ref = "kycouzwgzxmpnhzywrrh";
  try {
    ref = new URL(url).hostname.split(".")[0] || ref;
  } catch {
    /* garde le projet par défaut */
  }
  return parseTokens(readCookie(`sb-${ref}-auth-token`));
}

function readBackup(): Tokens | null {
  if (typeof window === "undefined") return null;
  return parseTokens(window.localStorage.getItem(BACKUP_KEY));
}

async function restore(tokens: Tokens | null): Promise<boolean> {
  if (!tokens) return false;
  const { data, error } = await getSupabase().auth.setSession(tokens);
  if (error || !data.session) return false;
  rememberSession(data.session);
  return true;
}

let pendingSession: Promise<void> | null = null;

/**
 * Une seule création de compte anonyme par onglet.
 * On réutilise d'abord la session déjà stockée, pour qu'un rafraîchissement
 * ne remplace pas le joueur par un nouveau compte vide.
 */
export function ensureSession(): Promise<void> {
  if (!pendingSession) {
    pendingSession = bootstrap().catch((error) => {
      pendingSession = null;
      throw error;
    });
  }
  return pendingSession;
}

async function bootstrap() {
  const supabase = getSupabase();
  const { data } = await supabase.auth.getSession();
  if (data.session) {
    rememberSession(data.session);
    return;
  }
  if (await restore(readCookieSession())) return;
  if (await restore(readBackup())) return;
  const { data: created, error } = await supabase.auth.signInAnonymously();
  if (error || !created.session) throw error ?? new Error("session vide");
  rememberSession(created.session);
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
    "time is up": "Temps écoulé !",
    "duel not found": "Duel introuvable : vérifiez le code.",
    "duel unavailable": "Ce duel a déjà commencé ou est terminé.",
    "question closed": "Trop tard pour cette question.",
    "friend not found": "Aucun joueur avec ce code ami.",
    "cannot add yourself": "C'est votre propre code ami.",
    "profiles_username_unique": "Ce pseudo est déjà pris.",
    "username_format": "Pseudo invalide : 2 à 20 caractères (lettres, chiffres, espace, _ . -).",
  };
  for (const [k, v] of Object.entries(map)) if (raw.includes(k)) return v;
  return raw;
}
