"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";
import { Countdown } from "@/components/Countdown";
import { Gate } from "@/components/Gate";
import { CollectibleCard } from "@/components/CollectibleCard";
import { Confetti } from "@/components/Confetti";
import { QuoteDuel } from "@/components/QuoteDuel";
import * as sfx from "@/lib/sfx";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { formatDate, type AnswerResult, type GameMode, type Question } from "@/lib/types";

const QUESTIONS_PER_GAME = 10;
const CHRONO_SECONDS = 60;

type Config = { mode: GameMode; theme: string | null };

function Setup({ initial, onStart, busy }: { initial: Config; onStart: (c: Config) => void; busy: boolean }) {
  const [mode, setMode] = useState<GameMode>(initial.mode);
  const theme = initial.theme;

  return (
    <section className="hero">
      <h1 className="headline">Solo</h1>
      <span className="tricolor" aria-hidden />

      <div className="mode-grid">
        <button className={`mode-card ${mode === "classic" ? "active" : ""}`} onClick={() => setMode("classic")}>
          <span className="mode-emoji" aria-hidden>🎯</span>
          <strong>Classique</strong>
          <span>{QUESTIONS_PER_GAME} citations, le contexte après chaque réponse</span>
        </button>
        <button className={`mode-card ${mode === "chrono" ? "active" : ""}`} onClick={() => setMode("chrono")}>
          <span className="mode-emoji" aria-hidden>⏱️</span>
          <strong>Chrono</strong>
          <span>Un maximum de bonnes réponses en {CHRONO_SECONDS} secondes</span>
        </button>
      </div>

      <div className="actions">
        <button className="btn primary" disabled={busy} onClick={() => onStart({ mode, theme })}>
          {busy ? "Préparation…" : "Lancer la partie"}
        </button>
      </div>
    </section>
  );
}

function Game() {
  const { refreshProfile } = useAuth();
  const [config, setConfig] = useState<Config>({ mode: "classic", theme: null });
  const [session, setSession] = useState<string | null>(null);
  const [question, setQuestion] = useState<Question | null>(null);
  const [result, setResult] = useState<AnswerResult | null>(null);
  const [chosen, setChosen] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const advanceTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => {
    if (advanceTimer.current) clearTimeout(advanceTimer.current);
  }, []);

  const loadNext = useCallback(async (sessionId: string) => {
    try {
      const { data, error } = await getSupabase().rpc("next_question", { p_session: sessionId });
      if (error) throw error;
      setQuestion(data as Question);
      setResult(null);
      setChosen(null);
      if ((data as Question).done) refreshProfile();
    } catch (e) {
      setError(errorMessage(e));
    }
  }, [refreshProfile]);

  const start = useCallback(async (c: Config) => {
    setConfig(c);
    setBusy(true);
    setError(null);
    try {
      const { data, error } = await getSupabase().rpc("start_game", {
        p_question_count: QUESTIONS_PER_GAME,
        p_theme: c.theme,
        p_mode: c.mode,
      });
      if (error) throw error;
      setSession(data as string);
      await loadNext(data as string);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }, [loadNext]);

  function backToSetup() {
    setSession(null);
    setQuestion(null);
    setResult(null);
    setError(null);
  }

  async function answer(optionId: string) {
    if (!session || !question || question.done || result || busy) return;
    setBusy(true);
    setChosen(optionId);
    try {
      const { data, error } = await getSupabase().rpc("submit_answer", {
        p_question: question.question_id,
        p_choice: optionId,
      });
      if (error) throw error;
      const res = data as AnswerResult;
      setResult(res);
      if (res.correct) sfx.correct();
      else sfx.wrong();
      // En chrono, on enchaîne sans s'arrêter sur le contexte
      if (question.mode === "chrono") {
        advanceTimer.current = setTimeout(() => loadNext(session), 700);
      } else {
        refreshProfile();
      }
    } catch (e) {
      const msg = errorMessage(e);
      if (msg === "Temps écoulé !") await loadNext(session);
      else setError(msg);
    } finally {
      setBusy(false);
    }
  }

  if (error) {
    return (
      <div className="center">
        <p className="notice error">{error}</p>
        <button className="btn" onClick={backToSetup}>Retour</button>
      </div>
    );
  }

  if (!session || !question) return <Setup initial={config} onStart={start} busy={busy} />;

  if (question.done) {
    const chrono = question.mode === "chrono";
    return (
      <section className="hero">
        <h1 className="headline">{chrono ? "Temps écoulé !" : "Partie terminée"}</h1>
        <span className="tricolor" aria-hidden />
        <div className="stats">
          <div>
            <strong>{question.correct}{chrono ? "" : `/${question.total}`}</strong>
            <span>bonnes réponses{chrono ? ` sur ${question.total}` : ""}</span>
          </div>
          <div><strong>{question.score.toLocaleString("fr-FR")}</strong><span>points gagnés</span></div>
          <div><strong>{question.max_streak}</strong><span>meilleure série</span></div>
        </div>
        <div className="actions">
          <button className="btn primary" onClick={() => start(config)} disabled={busy}>Rejouer</button>
          <button className="btn" onClick={backToSetup}>Changer de mode</button>
          <Link href="/boosters" className="btn">Ouvrir un booster</Link>
        </div>
      </section>
    );
  }

  const chrono = question.mode === "chrono";
  const streak = result?.streak ?? question.streak;

  return (
    <section className={`game ${result && !result.correct ? "shake-wrong" : ""}`}>
      {result?.correct && <Confetti key={question.question_id} seed={question.position} count={chrono ? 30 : 80} />}
      {result?.correct && <span className="points-pop" key={`p-${question.question_id}`}>+{result.points}</span>}
      <div className="game-status">
        <span>{chrono ? `Chrono · question ${question.position}` : `Question ${question.position}/${question.total}`}</span>
        <span>{(result ? question.score + result.points : question.score).toLocaleString("fr-FR")} pts</span>
        <span className={streak >= 3 ? "streak hot" : "streak"}>{streak >= 3 ? "🔥" : "⚡"} Série : {streak}</span>
      </div>
      {chrono && question.ends_at && (
        <Countdown until={question.ends_at} totalSeconds={CHRONO_SECONDS} onEnd={() => loadNext(session)} />
      )}

      <QuoteDuel
        quote={question.quote}
        isDemo={question.is_demo}
        options={question.options}
        answerId={result?.answer_id}
        chosenId={chosen}
        disabled={!!result || busy}
        onPick={answer}
      />

      {result && chrono && (
        <p className={`flash ${result.correct ? "ok" : "ko"}`}>
          {result.correct ? `+${result.points} pts` : `Raté : ${result.card.name}`}
        </p>
      )}

      {result && !chrono && (
        <div className={`reveal ${result.correct ? "ok" : "ko"}`}>
          <div className="reveal-text">
            <h2>{result.correct ? "Bonne réponse !" : "Raté…"}</h2>
            <p>
              Cette phrase est de <strong>{result.card.name}</strong>
              {result.card.said_on && <>, le {formatDate(result.card.said_on)}</>}
              {result.card.occasion && <> ({result.card.occasion})</>}.
            </p>
            {result.correct && (
              <p className="gain">
                +{result.points} pts
                {result.speed_bonus > 0 && <span> · bonus rapidité +{result.speed_bonus}</span>}
                {result.multiplier > 1 && <span> · série ×{result.multiplier}</span>}
              </p>
            )}
            {result.correct && (
              <p className="muted">{result.new_card ? "Nouvelle carte ajoutée à votre collection." : "Carte déjà possédée : un exemplaire de plus."}</p>
            )}
            <p className="source">
              Source :{" "}
              {result.card.source_url ? (
                <a href={result.card.source_url} target="_blank" rel="noopener noreferrer">
                  {result.card.source_label ?? "voir la source"} ↗
                </a>
              ) : (
                result.card.source_label ?? "—"
              )}
            </p>
            <button className="btn primary" onClick={() => loadNext(session)} autoFocus>
              {question.position === question.total ? "Voir le résultat" : "Question suivante"}
            </button>
          </div>
          {result.correct && (
            <div className="reveal-card">
              <CollectibleCard card={{ ...result.card, new: result.new_card }} />
              <span className="muted small-text">Touchez la carte pour la retourner</span>
            </div>
          )}
        </div>
      )}
    </section>
  );
}

export default function PlayPage() {
  return (
    <Gate>
      <Game />
    </Gate>
  );
}
