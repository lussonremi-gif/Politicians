"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./AuthProvider";

const NAV = [
  { href: "/jouer", label: "Jouer", icon: "🎯" },
  { href: "/boosters", label: "Boosters", icon: "🎁" },
  { href: "/collection", label: "Collection", icon: "🃏" },
  { href: "/amis", label: "Amis", icon: "👥" },
];

/** Partage le lien du jeu (feuille de partage du téléphone, sinon copie dans le presse-papiers). */
function ShareButton() {
  const [copied, setCopied] = useState(false);
  async function share() {
    const url = window.location.origin;
    const data = { title: "Qui l'a dit ?", text: "Une vraie citation, deux personnalités : qui l'a dit ?", url };
    try {
      if (navigator.share) {
        await navigator.share(data);
        return;
      }
    } catch {
      /* partage annulé : on copie le lien */
    }
    await navigator.clipboard?.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }
  return (
    <button className="share-btn" onClick={share} aria-label="Partager le jeu">
      <span aria-hidden>🔗</span>
      <span className="share-label">{copied ? "Lien copié !" : "Partager"}</span>
    </button>
  );
}

export function Header() {
  const pathname = usePathname();
  const { profile } = useAuth();

  return (
    <header className="site-header">
      <Link href="/" className="brand" aria-label="Accueil">
        <span className="brand-bubble">Qui l&apos;a dit&nbsp;?</span>
        <span className="brand-sub">
          Présidentielle <span className="blue">20</span>
          <span className="red">27</span>
        </span>
      </Link>
      {/* Sur téléphone, cette barre devient une barre d'onglets en bas de l'écran */}
      <nav className="site-nav">
        {NAV.map((item) => (
          <Link key={item.href} href={item.href} className={pathname.startsWith(item.href) ? "nav-pill active" : "nav-pill"}>
            <span className="nav-icon" aria-hidden>{item.icon}</span> <span className="nav-label">{item.label}</span>
          </Link>
        ))}
      </nav>
      <div className="header-tools">
        <ShareButton />
        {profile && (
          <Link
            href="/boosters"
            className="points-badge"
            title={profile.username ? `Compte ${profile.username}` : "Compte de cet appareil"}
          >
            {profile.username && <span className="points-user">{profile.username}</span>}
            <span aria-hidden>🪙</span> {profile.points.toLocaleString("fr-FR")}
          </Link>
        )}
      </div>
    </header>
  );
}
