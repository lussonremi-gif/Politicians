"use client";

/**
 * Effets sonores synthétisés avec la Web Audio API (aucun fichier audio).
 * Les sons ne démarrent qu'après une action de l'utilisateur (règle des navigateurs).
 */

let ctx: AudioContext | null = null;
let muted = false;

try {
  muted = typeof window !== "undefined" && window.localStorage.getItem("sfx-muted") === "1";
} catch {
  /* stockage indisponible */
}

function audio(): AudioContext | null {
  if (muted || typeof window === "undefined") return null;
  try {
    if (!ctx) {
      const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Ctor) return null;
      ctx = new Ctor();
    }
    if (ctx.state === "suspended") void ctx.resume();
    return ctx;
  } catch {
    return null;
  }
}

export function isMuted() {
  return muted;
}

export function setMuted(value: boolean) {
  muted = value;
  try {
    window.localStorage.setItem("sfx-muted", value ? "1" : "0");
  } catch {
    /* stockage indisponible */
  }
}

function noiseBuffer(a: AudioContext, seconds: number) {
  const buffer = a.createBuffer(1, Math.floor(a.sampleRate * seconds), a.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
  return buffer;
}

function tone(type: OscillatorType, from: number, to: number, start: number, duration: number, volume: number) {
  const a = audio();
  if (!a) return;
  const t = a.currentTime + start;
  const osc = a.createOscillator();
  const gain = a.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(from, t);
  osc.frequency.exponentialRampToValueAtTime(Math.max(1, to), t + duration);
  gain.gain.setValueAtTime(0.0001, t);
  gain.gain.exponentialRampToValueAtTime(volume, t + Math.min(0.03, duration / 4));
  gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
  osc.connect(gain).connect(a.destination);
  osc.start(t);
  osc.stop(t + duration + 0.05);
}

function noise(start: number, duration: number, volume: number, fromHz: number, toHz: number, rise = false) {
  const a = audio();
  if (!a) return;
  const t = a.currentTime + start;
  const src = a.createBufferSource();
  src.buffer = noiseBuffer(a, duration + 0.1);
  const filter = a.createBiquadFilter();
  filter.type = "bandpass";
  filter.Q.value = 1.2;
  filter.frequency.setValueAtTime(fromHz, t);
  filter.frequency.exponentialRampToValueAtTime(toHz, t + duration);
  const gain = a.createGain();
  if (rise) {
    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(volume, t + duration * 0.95);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration + 0.05);
  } else {
    gain.gain.setValueAtTime(volume, t);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
  }
  src.connect(filter).connect(gain).connect(a.destination);
  src.start(t);
  src.stop(t + duration + 0.1);
}

/** Montée de tension pendant que le booster se charge. */
export function riser(seconds: number, intensity: number) {
  tone("sawtooth", 70, 260 + intensity * 120, 0, seconds, 0.03 + intensity * 0.012);
  tone("sine", 140, 520 + intensity * 200, 0, seconds, 0.04);
  noise(0, seconds, 0.05 + intensity * 0.03, 300, 4000 + intensity * 1500, true);
}

/** Déchirure / explosion du booster. */
export function burst() {
  noise(0, 0.5, 0.35, 5000, 300);
  tone("sine", 160, 40, 0, 0.6, 0.35);
}

/** Impact sourd (apparition du parti). */
export function thud() {
  tone("sine", 140, 45, 0, 0.35, 0.4);
  noise(0, 0.15, 0.12, 1200, 200);
}

/** Petit clic de machine à écrire. */
export function tick() {
  tone("square", 1700 + Math.random() * 400, 1200, 0, 0.025, 0.012);
}

/** Révélation de la carte, plus ou moins spectaculaire selon la rareté (0 à 5). */
export function reveal(rank: number) {
  tone("sine", 110, 35, 0, 0.8 + rank * 0.25, 0.3 + rank * 0.05);
  noise(0, 0.6 + rank * 0.1, 0.12 + rank * 0.04, 6000, 400);
  if (rank >= 2) {
    // Accord scintillant
    const notes = rank >= 5 ? [523, 659, 784, 1047, 1319, 1568] : rank >= 4 ? [523, 659, 784, 1047, 1319] : [659, 784, 988];
    notes.forEach((f, i) => tone("triangle", f, f, 0.05 + i * 0.07, 1.2 + rank * 0.2, 0.05));
  }
  if (rank >= 4) {
    // Fanfare grave
    tone("sawtooth", 65, 65, 0.1, 1.4, 0.05);
    tone("sawtooth", 98, 98, 0.1, 1.4, 0.04);
  }
}

/** Bonne réponse / mauvaise réponse (modes Solo et Multi). */
export function correct() {
  [660, 880, 1320].forEach((f, i) => tone("triangle", f, f, i * 0.07, 0.25, 0.08));
}

export function wrong() {
  tone("sawtooth", 220, 110, 0, 0.35, 0.06);
}
