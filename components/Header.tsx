"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./AuthProvider";

const NAV = [
  { href: "/jouer", label: "Jouer" },
  { href: "/collection", label: "Collection" },
  { href: "/boosters", label: "Boosters" },
  { href: "/amis", label: "Amis" },
  { href: "/a-propos", label: "À propos" },
  { href: "/methodologie", label: "Méthodologie" },
];

export function Header() {
  const pathname = usePathname();
  const { profile } = useAuth();

  return (
    <header className="site-header">
      <Link href="/" className="brand" aria-label="Accueil">
        <span className="brand-title">
          Présidentielle <span className="blue">20</span>
          <span className="red">27</span>
        </span>
        <span className="tricolor small" aria-hidden />
      </Link>
      <nav className="site-nav">
        {NAV.map((item) => (
          <Link key={item.href} href={item.href} className={pathname === item.href ? "active" : undefined}>
            {item.label}
          </Link>
        ))}
        {profile && (
          <span className="points-badge" title={profile.username ? `Compte ${profile.username}` : "Compte de cet appareil"}>
            {profile.username ? `${profile.username} · ` : ""}
            {profile.points.toLocaleString("fr-FR")} pts
          </span>
        )}
      </nav>
    </header>
  );
}
