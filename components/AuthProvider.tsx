"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { ensureSession, getSupabase, isSupabaseConfigured, rememberSession } from "@/lib/supabase";
import type { Profile } from "@/lib/types";

type AuthState = {
  ready: boolean;
  error: string | null;
  profile: Profile | null;
  refreshProfile: () => Promise<void>;
  setPoints: (points: number) => void;
};

const AuthContext = createContext<AuthState>({
  ready: false,
  error: null,
  profile: null,
  refreshProfile: async () => {},
  setPoints: () => {},
});

/**
 * Compte lié à cet appareil. La session est relue au chargement : un rafraîchissement
 * ne crée un nouveau joueur que s'il n'existe encore aucune session.
 */
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);

  const refreshProfile = useCallback(async () => {
    const supabase = getSupabase();
    const { data: userData } = await supabase.auth.getUser();
    if (!userData.user) return;
    const { data } = await supabase.from("profiles").select("*").eq("id", userData.user.id).maybeSingle();
    if (data) setProfile(data as Profile);
  }, []);

  useEffect(() => {
    if (!isSupabaseConfigured) {
      setError("Supabase n'est pas configuré : renseignez NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY.");
      setReady(true);
      return;
    }
    let cancelled = false;
    const supabase = getSupabase();
    const { data: subscription } = supabase.auth.onAuthStateChange((event, session) => {
      if (session && (event === "INITIAL_SESSION" || event === "SIGNED_IN" || event === "TOKEN_REFRESHED")) {
        rememberSession(session);
      }
    });
    (async () => {
      try {
        await ensureSession();
        if (!cancelled) await refreshProfile();
      } catch (err) {
        if (!cancelled) {
          const detail = err instanceof Error ? err.message : "réessayez dans un instant";
          setError("Impossible d'ouvrir le compte sur cet appareil : " + detail);
        }
      } finally {
        if (!cancelled) setReady(true);
      }
    })();
    return () => {
      cancelled = true;
      subscription.subscription.unsubscribe();
    };
  }, [refreshProfile]);

  const setPoints = useCallback((points: number) => {
    setProfile((p) => (p ? { ...p, points } : p));
  }, []);

  return (
    <AuthContext.Provider value={{ ready, error, profile, refreshProfile, setPoints }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
