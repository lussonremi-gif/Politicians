/** Six niveaux de rareté, selon le retentissement de la citation. */
export type Rarity = "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic";

export const RARITIES: Rarity[] = ["common", "uncommon", "rare", "epic", "legendary", "mythic"];

export const RARITY_LABEL: Record<Rarity, string> = {
  common: "Commune",
  uncommon: "Peu commune",
  rare: "Rare",
  epic: "Épique",
  legendary: "Légendaire",
  mythic: "Mythique",
};

export const RARITY_RANK: Record<Rarity, number> = { common: 0, uncommon: 1, rare: 2, epic: 3, legendary: 4, mythic: 5 };

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
  party_short?: string | null;
  party_color?: string | null;
  image_focus?: string | null;
  kind?: "politician" | "personality";
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

/** Carte du jeu et de la collection : une personnalité + une de ses citations. */
export type GameCard = {
  card_id: string;
  text: string | null; // null dans l'album tant que la carte n'est pas obtenue
  rarity: Rarity;
  theme: string | null;
  said_on: string | null;
  occasion: string | null;
  source_label: string | null;
  source_url: string | null;
  politician_id: string;
  politician_slug: string;
  name: string;
  role: string | null;
  image_url: string | null;
  image_credit: string | null;
  image_license: string | null;
  image_source_url: string | null;
  image_focus?: string | null;
  fallback_image_url?: string | null;
  party_name: string | null;
  party_short: string | null;
  party_color: string | null;
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
  card: GameCard;
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
  kind: "quotes" | "politicians";
  party_id: string | null;
  active: boolean;
  weights: Partial<Record<Rarity, number>> | null;
  tag: string | null;
  party?: Party | null;
};

export type Party = {
  id: string;
  slug: string;
  name: string;
  short_name: string;
  color: string;
  sort_order: number;
};

/** Carte reçue dans un booster. */
export type OpenedCard = GameCard & { type: "card" };

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
