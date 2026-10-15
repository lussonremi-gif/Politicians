"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./AuthProvider";

const NAV = [
  { href: "/jouer", label: "Jouer", icon: "🎯" },
  { href: "/boosters", label: "Boosters", icon: "🎁" },
  { href: "/collection", label: "Collection", icon: "🃏" },
  { href: "/amis", label: "Amis", icon: "👥" },
];

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
      <nav className="site-nav">
        {NAV.map((item) => (
          <Link key={item.href} href={item.href} className={pathname.startsWith(item.href) ? "nav-pill active" : "nav-pill"}>
            <span aria-hidden>{item.icon}</span> {item.label}
          </Link>
        ))}
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
      </nav>
    </header>
  );
}
