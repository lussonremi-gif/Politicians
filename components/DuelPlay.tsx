"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "@/components/AuthProvider";
import { Confetti } from "@/components/Confetti";
import { Countdown } from "@/components/Countdown";
import { QuoteDuel } from "@/components/QuoteDuel";
import * as sfx from "@/lib/sfx";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { formatDate, type DuelReveal, type DuelState, type DuelSummary } from "@/lib/types";

const RESULT_CLASS: Record<string, string> = { victoire: "win", "défaite": "loss", "égalité": "draw", "en cours": "live" };

function Lobby({ onOpen, embedded = false }: { onOpen: (id: string) => void; embedded?: boolean }) {
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [history, setHistory] = useState<DuelSummary[]>([]);

  useEffect(() => {
    getSupabase()
      .rpc("my_duels", { p_limit: 10 })
      .then(({ data }) => setHistory((data as DuelSummary[]) ?? []));
  }, []);

  async function create() {
    setBusy(true);
    setError(null);
    const { data, error } = await getSupabase().rpc("create_duel", {});
    setBusy(false);
    if (error) return setError(errorMessage(error));
    onOpen((data as { id: string }).id);
  }

  async function join(e: React.FormEvent) {
    e.preventDefault();
    if (!code.trim()) return;
    setBusy(true);
    setError(null);
    const { data, error } = await getSupabase().rpc("join_duel", { p_code: code.trim() });
    setBusy(false);
    if (error) return setError(errorMessage(error));
    onOpen(data as string);
  }

  return (
    <section>
      {!embedded && (
        <div className="section-head">
          <h1 className="headline">Duel</h1>
          <span className="tricolor" aria-hidden />
        </div>
      )}
      <p className="lead">
        1 contre 1 en temps réel : la même série de citations pour les deux joueurs, 15 secondes par réponse. Le
        vainqueur gagne 200 points et une carte.
      </p>

      {error && <p className="notice error center">{error}</p>}

      <div className="panel-grid">
        <div className="panel">
          <h2>Créer un duel</h2>
          <p className="muted">Vous obtenez un code à envoyer à un ami.</p>
          <button className="btn primary" onClick={create} disabled={busy}>
            Créer un duel
          </button>
        </div>
        <form className="panel" onSubmit={join}>
          <h2>Rejoindre un duel</h2>
          <p className="muted">Entrez le code reçu.</p>
          <div className="inline-form">
            <input
              className="input code-input"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="EX : 3FA9C1"
              maxLength={6}
              aria-label="Code du duel"
            />
            <button className="btn primary" type="submit" disabled={busy || code.trim().length < 6}>
              Rejoindre
            </button>
          </div>
        </form>
      </div>

      {history.length > 0 && (
        <div className="panel history">
          <h2>Mes derniers duels</h2>
          <ul>
            {history.map((d) => (
              <li key={d.id}>
                <span className={`result-tag ${RESULT_CLASS[d.result] ?? ""}`}>{d.result}</span>
                <span>contre {d.opponent_name}</span>
                <span className="muted">
                  {d.my_score} – {d.opponent_score}
                </span>
                {d.result === "en cours" && (
                  <button className="btn small" onClick={() => onOpen(d.id)}>
                    Reprendre
                  </button>
                )}
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}

function RevealPanel({ reveal, opponentName, waiting }: { reveal: DuelReveal; opponentName: string; waiting: boolean }) {
  const mine = reveal.mine;
  return (
    <div className={`reveal ${mine?.correct ? "ok" : "ko"}`}>
      <div className="reveal-text">
        <h2>{mine?.correct ? `Bonne réponse ! +${mine.points} pts` : mine?.chosen_id ? "Raté…" : "Temps écoulé"}</h2>
        <p>
          « {reveal.quote} » est de <strong>{reveal.author}</strong>
          {reveal.said_on && <>, le {formatDate(reveal.said_on)}</>}
          {reveal.occasion && <> ({reveal.occasion})</>}.
        </p>
        <p className="source">
          Source :{" "}
          {reveal.source_url ? (
            <a href={reveal.source_url} target="_blank" rel="noopener noreferrer">
              {reveal.source_label ?? "voir la source"} ↗
            </a>
          ) : (
            reveal.source_label ?? "—"
          )}
        </p>
        <p className="muted">
          {reveal.opponent
            ? `${opponentName} : ${reveal.opponent.correct ? `bonne réponse (+${reveal.opponent.points} pts)` : "mauvaise réponse"}`
            : waiting
              ? `En attente de la réponse de ${opponentName}…`
              : null}
        </p>
      </div>
    </div>
  );
}

function DuelRoom({ id, onLeave }: { id: string; onLeave: () => void }) {
  const { refreshProfile } = useAuth();
  const [state, setState] = useState<DuelState | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [chosen, setChosen] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [, setTick] = useState(0);
  const offset = useRef(0);
  const inFlight = useRef(false);

  const refresh = useCallback(async () => {
    if (inFlight.current) return;
    inFlight.current = true;
    const { data, error } = await getSupabase().rpc("duel_state", { p_duel: id });
    inFlight.current = false;
    if (error) return setError(errorMessage(error));
    const s = data as DuelState;
    offset.current = new Date(s.server_now).getTime() - Date.now();
    setState(s);
    if (s.status === "finished" || s.status === "abandoned") refreshProfile();
  }, [id, refreshProfile]);

  useEffect(() => {
    refresh();
    const supabase = getSupabase();
    const channel = supabase
      .channel(`duel-${id}`)
      .on("postgres_changes", { event: "UPDATE", schema: "public", table: "duels", filter: `id=eq.${id}` }, () => refresh())
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [id, refresh]);

  useEffect(() => {
    if (!state || state.status === "finished" || state.status === "abandoned") return;
    let ticks = 0;
    const t = setInterval(() => {
      ticks++;
      setTick((n) => n + 1);
      const now = Date.now() + offset.current;
      const servedAt = state.served_at ? new Date(state.served_at).getTime() : 0;
      const deadline = state.deadline ? new Date(state.deadline).getTime() : 0;
      const awaitingQuestion = state.status === "active" && !state.question && state.my_answered < state.current_position && now >= servedAt;
      const expired = state.status === "active" && deadline > 0 && now > deadline + 300;
      if (awaitingQuestion || expired || ticks % 8 === 0) refresh();
    }, 500);
    return () => clearInterval(t);
  }, [state, refresh]);

  useEffect(() => setChosen(null), [state?.current_position]);

  async function pick(optionId: string) {
    if (!state?.question || chosen) return;
    setChosen(optionId);
    const { data, error } = await getSupabase().rpc("submit_duel_answer", {
      p_duel: id,
      p_position: state.question.position,
      p_choice: optionId,
    });
    if (error) {
      setError(errorMessage(error));
      refresh();
      return;
    }
    const s = data as DuelState;
    offset.current = new Date(s.server_now).getTime() - Date.now();
    if (s.reveal?.mine?.correct) sfx.correct();
    else sfx.wrong();
    setState(s);
  }

  async function abandon() {
    if (state?.status === "active" && !confirm("Abandonner ce duel ? Votre adversaire sera déclaré vainqueur.")) return;
    await getSupabase().rpc("abandon_duel", { p_duel: id });
    if (state?.status === "waiting") onLeave();
    else refresh();
  }

  async function rematch() {
    const { data, error } = await getSupabase().rpc("create_duel", {});
    if (error) return setError(errorMessage(error));
    window.location.href = `/jouer?id=${(data as { id: string }).id}`;
  }

  if (error && !state) {
    return (
      <div className="center">
        <p className="notice error">{error}</p>
        <button className="btn" onClick={onLeave}>Retour</button>
      </div>
    );
  }
  if (!state) return <p className="muted center">Chargement du duel…</p>;

  const opponent = state.opponent_name ?? "Adversaire";
  const now = Date.now() + offset.current;
  const servedAt = state.served_at ? new Date(state.served_at).getTime() : 0;
  const shareUrl = typeof window !== "undefined" ? `${window.location.origin}/jouer?code=${state.code}` : "";

  if (state.status === "waiting") {
    async function share() {
      const text = `Je te défie sur « Qui l'a dit ? » ! Code : ${state!.code}`;
      if (navigator.share) {
        try {
          await navigator.share({ title: "Duel · Qui l'a dit ?", text, url: shareUrl });
          return;
        } catch {
          /* partage annulé : on copie le lien */
        }
      }
      await navigator.clipboard?.writeText(shareUrl);
      setCopied(true);
    }
    return (
      <section className="hero">
        <h1 className="headline">En attente d&apos;un adversaire</h1>
        <span className="tricolor" aria-hidden />
        <p className="lead">Envoyez ce code ou ce lien à un ami. Le duel démarre dès qu&apos;il le rejoint.</p>
        <p className="duel-code" aria-label="Code du duel">{state.code}</p>
        <p className="muted small-text share-url">{shareUrl}</p>
        <div className="actions">
          <button className="btn primary" onClick={share}>{copied ? "Lien copié !" : "Partager le lien"}</button>
          <button className="btn" onClick={abandon}>Annuler</button>
        </div>
        <p className="muted pulse">En attente…</p>
      </section>
    );
  }

  const scoreboard = (
    <div className="scoreboard">
      <div className="me"><span>Vous</span><strong>{state.my_score}</strong></div>
      <div className="vs">
        {state.status === "active" ? `Question ${Math.min(state.current_position, state.question_count)}/${state.question_count}` : "Terminé"}
      </div>
      <div className="opp">
        <span>{opponent}{state.status === "active" && state.opponent_answered >= state.current_position ? " ✓" : ""}</span>
        <strong>{state.opponent_score}</strong>
      </div>
    </div>
  );

  if (state.status === "finished" || state.status === "abandoned") {
    const title = state.winner === "me" ? "Victoire !" : state.winner === "opponent" ? "Défaite" : "Égalité";
    const detail = state.abandoned
      ? state.winner === "me"
        ? `${opponent} a abandonné.`
        : "Vous avez abandonné."
      : state.winner === "me"
        ? "Vous gagnez 200 points bonus et une carte du duel."
        : null;
    return (
      <section className="hero">
        {state.winner === "me" && <Confetti seed={7} count={120} />}
        {scoreboard}
        <h1 className="headline">{title}</h1>
        <span className="tricolor" aria-hidden />
        {detail && <p className="lead">{detail}</p>}
        <p className="muted">Les points marqués pendant le duel ont été ajoutés à votre total.</p>
        <div className="actions">
          <button className="btn primary" onClick={rematch}>Nouveau duel</button>
          <button className="btn" onClick={onLeave}>Retour</button>
          <Link href="/collection" className="btn">Ma collection</Link>
        </div>
      </section>
    );
  }

  return (
    <section className="game">
      {scoreboard}
      {error && <p className="notice error center">{error}</p>}

      {state.question ? (
        <>
          {state.deadline && (
            <Countdown until={state.deadline} totalSeconds={state.answer_seconds} offsetMs={offset.current} onEnd={refresh} />
          )}
          <QuoteDuel
            quote={state.question.quote}
            isDemo={state.question.is_demo}
            options={state.question.options}
            chosenId={chosen}
            disabled={!!chosen}
            onPick={pick}
          />
        </>
      ) : (
        <>
          {now < servedAt && (
            <p className="next-in">
              {state.my_answered === 0 ? "Le duel commence" : "Question suivante"} dans{" "}
              <strong>{Math.max(1, Math.ceil((servedAt - now) / 1000))}</strong>…
            </p>
          )}
          {state.reveal && (
            <RevealPanel
              reveal={state.reveal}
              opponentName={opponent}
              waiting={state.my_answered >= state.current_position}
            />
          )}
        </>
      )}

      <div className="actions">
        <button className="btn small" onClick={abandon}>Abandonner</button>
      </div>
    </section>
  );
}

export function DuelRoot({ embeddedLobby = false }: { embeddedLobby?: boolean }) {
  const router = useRouter();
  const params = useSearchParams();
  const id = params.get("id");
  const code = params.get("code");
  const [joinError, setJoinError] = useState<string | null>(null);

  useEffect(() => {
    if (!code || id) return;
    getSupabase()
      .rpc("join_duel", { p_code: code })
      .then(({ data, error }) => {
        if (error) setJoinError(errorMessage(error));
        else router.replace(`/jouer?id=${data as string}`);
      });
  }, [code, id, router]);

  const leave = () => router.push("/jouer?mode=duel");

  if (id) return <DuelRoom key={id} id={id} onLeave={leave} />;
  if (code && !joinError) return <p className="muted center">Connexion au duel…</p>;
  return (
    <>
      {joinError && <p className="notice error center">{joinError}</p>}
      <Lobby embedded={embeddedLobby} onOpen={(duelId) => router.push(`/jouer?id=${duelId}`)} />
    </>
  );
}
