"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { getSupabase, isSupabaseConfigured } from "@/lib/supabase";
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
 * Partie invitée : chaque visiteur reçoit automatiquement un compte anonyme Supabase,
 * qui conserve ses points et sa collection sur cet appareil.
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
    (async () => {
      const supabase = getSupabase();
      const { data } = await supabase.auth.getSession();
      if (!data.session) {
        const { error: signInError } = await supabase.auth.signInAnonymously();
        if (signInError) {
          setError("Impossible de créer une partie invitée : " + signInError.message);
          setReady(true);
          return;
        }
      }
      await refreshProfile();
      setReady(true);
    })();
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
