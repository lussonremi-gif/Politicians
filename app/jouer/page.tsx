"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";
import { Gate } from "@/components/Gate";
import { Portrait } from "@/components/Portrait";
import { QuoteCard } from "@/components/QuoteCard";
import { errorMessage, getSupabase } from "@/lib/supabase";
import { formatDate, type AnswerResult, type Question } from "@/lib/types";

const QUESTIONS_PER_GAME = 10;

function Game() {
  const { refreshProfile } = useAuth();
  const [session, setSession] = useState<string | null>(null);
  const [question, setQuestion] = useState<Question | null>(null);
  const [result, setResult] = useState<AnswerResult | null>(null);
  const [chosen, setChosen] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadNext = useCallback(async (sessionId: string) => {
    const { data, error } = await getSupabase().rpc("next_question", { p_session: sessionId });
    if (error) throw error;
    setQuestion(data as Question);
    setResult(null);
    setChosen(null);
  }, []);

  const start = useCallback(async () => {
    setBusy(true);
    setError(null);
    try {
      const { data, error } = await getSupabase().rpc("start_game", { p_question_count: QUESTIONS_PER_GAME });
      if (error) throw error;
      setSession(data as string);
      await loadNext(data as string);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }, [loadNext]);

  useEffect(() => {
    start();
  }, [start]);

  async function answer(optionId: string) {
    if (!question || question.done || result || busy) return;
    setBusy(true);
    setChosen(optionId);
    try {
      const { data, error } = await getSupabase().rpc("submit_answer", {
        p_question: question.question_id,
        p_choice: optionId,
      });
      if (error) throw error;
      setResult(data as AnswerResult);
      refreshProfile();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  if (error) {
    return (
      <div className="center">
        <p className="notice error">{error}</p>
        <button className="btn" onClick={start}>Réessayer</button>
      </div>
    );
  }
  if (!question || !session) return <p className="muted center">Préparation de la partie…</p>;

  if (question.done) {
    return (
      <section className="hero">
        <h1 className="headline">Partie terminée</h1>
        <span className="tricolor" aria-hidden />
        <div className="stats">
          <div><strong>{question.correct}/{question.total}</strong><span>bonnes réponses</span></div>
          <div><strong>{question.score.toLocaleString("fr-FR")}</strong><span>points gagnés</span></div>
          <div><strong>{question.max_streak}</strong><span>meilleure série</span></div>
        </div>
        <div className="actions">
          <button className="btn primary" onClick={start} disabled={busy}>Rejouer</button>
          <Link href="/boosters" className="btn">Ouvrir un booster</Link>
          <Link href="/collection" className="btn">Ma collection</Link>
        </div>
      </section>
    );
  }

  const [a, b] = question.options;
  const stateOf = (id: string) => {
    if (!result) return "";
    if (id === result.answer_id) return "is-right";
    if (id === chosen) return "is-wrong";
    return "is-dim";
  };

  return (
    <section className="game">
      <div className="game-status">
        <span>Question {question.position}/{question.total}</span>
        <span>{(result ? question.score + result.points : question.score).toLocaleString("fr-FR")} pts</span>
        <span className={(result?.streak ?? question.streak) >= 3 ? "streak hot" : "streak"}>
          Série : {result?.streak ?? question.streak}
        </span>
      </div>

      <div className="quote-glyph" aria-hidden>“</div>
      <blockquote className="headline quote">« {question.quote} »</blockquote>
      <span className="tricolor" aria-hidden />
      {question.is_demo && <p className="demo-banner">Citation fictive de démonstration</p>}

      <div className="duel">
        {[a, b].map((opt, i) => [
          i === 1 && (
            <div key="or" className="duel-or" aria-hidden>
              <span className="bar" />
              ou
              <span className="bar" />
            </div>
          ),
          <button
            key={opt.id}
            className={`person-card ${stateOf(opt.id)}`}
            onClick={() => answer(opt.id)}
            disabled={!!result || busy}
          >
            <div className="person-photo">
              <Portrait person={opt} />
            </div>
            <div className="person-name">
              {opt.name}
              {opt.description && <small>{opt.description}</small>}
            </div>
          </button>,
        ])}
      </div>

      {result && (
        <div className={`reveal ${result.correct ? "ok" : "ko"}`}>
          <div className="reveal-text">
            <h2>{result.correct ? "Bonne réponse !" : "Raté…"}</h2>
            <p>
              Cette phrase est de <strong>{result.card.author}</strong>
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
              <QuoteCard card={{ ...result.card, new: result.new_card }} />
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
