import { RARITIES, type GameCard, type Rarity } from "./types";

/**
 * Photos distinctes des cartes Macron (Wikimedia Commons, licences libres).
 * Le texte sert quand la carte est déjà obtenue ; sinon on reconnaît la carte
 * par son thème et sa rareté, quand cette combinaison est unique.
 */
const MACRON_ART: {
  text?: string;
  rarity?: string;
  theme?: string;
  file: string;
  credit: string;
  license: string;
}[] = [
  {
    text: "Parce que c'est notre projet",
    rarity: "epic",
    theme: "campagnes",
    file: "Emmanuel Macron (11 décembre 2014) (2) (cropped).jpg",
    credit: "OFFICIAL LEWEB PHOTOS",
    license: "CC BY 2.0",
  },
  {
    text: "Nous sommes en guerre",
    rarity: "epic",
    theme: "discours",
    file: "Emmanuel Macron 2020.jpg",
    credit: "U.S. Department of State",
    license: "Domaine public",
  },
  {
    text: "On met un pognon de dingue",
    file: "Emmanuel Macron in Washington - 2018 (26809923797) (cropped).jpg",
    credit: "U.S. Department of State",
    license: "Domaine public",
  },
  {
    text: "Les non-vaccinés",
    file: "Emmanuel Macron (2022-02-07) (cropped).jpg",
    credit: "Presidential Executive Office of Russia",
    license: "CC BY 4.0",
  },
  {
    text: "Je traverse la rue",
    rarity: "uncommon",
    theme: "petites phrases",
    file: "Emmanuel Macron in November 2018 (cropped).jpg",
    credit: "The Kremlin, Moscow",
    license: "CC BY 4.0",
  },
  {
    text: "Je traverse la rue",
    rarity: "common",
    theme: "petites phrases",
    file: "Emmanuel Macron in November 2018 (cropped).jpg",
    credit: "The Kremlin, Moscow",
    license: "CC BY 4.0",
  },
  {
    text: "Je ne céderai rien",
    rarity: "common",
    theme: "discours",
    file: "Emmanuel Macron (32605283887) (cropped).jpg",
    credit: "Jacques Paquier",
    license: "CC BY 2.0",
  },
];

function fileUrl(file: string) {
  return `https://commons.wikimedia.org/wiki/Special:FilePath/${file.replace(/ /g, "_")}?width=640`;
}

function pageUrl(file: string) {
  return `https://commons.wikimedia.org/wiki/File:${file.replace(/ /g, "_")}`;
}

export function asRarity(value: string): Rarity {
  if (value === "uncommon") return "common";
  if ((RARITIES as string[]).includes(value)) return value as Rarity;
  return "common";
}

function artFor(card: GameCard) {
  if (card.name !== "Emmanuel Macron") return null;
  if (card.text) {
    const byText = MACRON_ART.find((a) => a.text && card.text!.startsWith(a.text));
    if (byText) return byText;
  }
  const raw = card.rarity as string;
  return MACRON_ART.find((a) => a.rarity === raw && a.theme === card.theme) ?? null;
}

/** Photo propre à la carte, et rareté sans le niveau « peu commune ». */
export function presentCard<T extends GameCard>(card: T): T {
  const art = artFor(card);
  const rarity = asRarity(card.rarity as string);
  if (!art) return { ...card, rarity };
  const key = art.file.replace(/ /g, "_");
  if (card.image_url?.includes(key)) return { ...card, rarity };
  return {
    ...card,
    rarity,
    image_url: fileUrl(art.file),
    image_credit: art.credit,
    image_license: art.license,
    image_source_url: pageUrl(art.file),
  };
}
