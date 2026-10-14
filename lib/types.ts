export type Rarity = "common" | "rare" | "legendary";

export const RARITY_LABEL: Record<Rarity, string> = {
  common: "Commune",
  rare: "Rare",
  legendary: "Légendaire",
};

export type Profile = {
  id: string;
  username: string | null;
  friend_code: string;
  duels_played: number;
  duels_won: number;
  points: number;
  total_points_earned: number;
  best_streak: number;
  games_played: number;
};

export type Option = {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
};

export type GameMode = "classic" | "chrono";

export type Question =
  | {
      done: false;
      mode: GameMode;
      ends_at: string | null;
      question_id: string;
      position: number;
      total: number;
      quote: string;
      is_demo: boolean;
      score: number;
      streak: number;
      options: [Option, Option];
    }
  | { done: true; mode: GameMode; total: number; score: number; correct: number; max_streak: number };

export type Theme = { theme: string; quote_count: number };

/** Recto + verso d'une carte. */
export type Card = {
  quote_id: string;
  text: string;
  rarity: Rarity;
  author: string;
  author_description: string | null;
  said_on: string | null;
  occasion: string | null;
  source_label: string | null;
  source_url: string | null;
  theme: string | null;
  is_demo: boolean;
  new?: boolean;
  copies?: number;
};

export type AnswerResult = {
  correct: boolean;
  answer_id: string;
  points: number;
  speed_bonus: number;
  multiplier: number;
  streak: number;
  new_card: boolean;
  card: Card;
};

export type BoosterType = {
  slug: string;
  name: string;
  description: string | null;
  price: number;
  card_count: number;
  weight_common: number;
  weight_rare: number;
  weight_legendary: number;
  theme: string | null;
  personality_id: string | null;
  sort_order: number;
};

export function formatDate(d: string | null): string | null {
  if (!d) return null;
  return new Date(d + "T12:00:00").toLocaleDateString("fr-FR", { day: "numeric", month: "long", year: "numeric" });
}

export type DuelReveal = {
  position: number;
  quote: string;
  answer_id: string;
  author: string;
  said_on: string | null;
  occasion: string | null;
  source_label: string | null;
  source_url: string | null;
  mine: { chosen_id: string | null; correct: boolean; points: number } | null;
  opponent: { correct: boolean; points: number } | null;
};

export type DuelState = {
  id: string;
  code: string;
  status: "waiting" | "active" | "finished" | "abandoned";
  me: 1 | 2;
  opponent_name: string | null;
  has_opponent: boolean;
  question_count: number;
  answer_seconds: number;
  current_position: number;
  served_at: string | null;
  deadline: string | null;
  server_now: string;
  my_score: number;
  opponent_score: number;
  my_answered: number;
  opponent_answered: number;
  question: { position: number; quote: string; is_demo: boolean; options: [Option, Option] } | null;
  reveal: DuelReveal | null;
  winner: "me" | "opponent" | null;
  abandoned: boolean;
};

export type DuelSummary = {
  id: string;
  status: string;
  created_at: string;
  opponent_name: string;
  my_score: number;
  opponent_score: number;
  result: string;
};

export type LeaderRow = {
  user_id: string;
  username: string;
  total_points_earned: number;
  best_streak: number;
  cards: number;
  duels_won: number;
  is_me: boolean;
};
