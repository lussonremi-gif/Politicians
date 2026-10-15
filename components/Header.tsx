"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./AuthProvider";

const NAV = [
  { href: "/jouer", label: "Jouer" },
  { href: "/boosters", label: "Boosters" },
  { href: "/collection", label: "Collection" },
  { href: "/amis", label: "Amis" },
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
            {item.label}
          </Link>
        ))}
        {profile && (
          <Link
            href="/compte"
            className={`points-badge ${pathname.startsWith("/compte") ? "active" : ""}`}
            title={profile.username ? `Compte ${profile.username}` : "Mon compte"}
          >
            {profile.username && <span className="points-user">{profile.username}</span>}
            <span className="points-value">{profile.points.toLocaleString("fr-FR")} pts</span>
          </Link>
        )}
      </nav>
    </header>
  );
}
