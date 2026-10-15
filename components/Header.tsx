"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./AuthProvider";
import { InviteQr } from "./InviteQr";

const NAV = [
  { href: "/jouer", label: "Jouer" },
  { href: "/boosters", label: "Boosters" },
  { href: "/collection", label: "Collection" },
  { href: "/amis", label: "Amis" },
];

/** Icônes de la barre d'onglets (téléphone uniquement ; sur ordinateur, seul le libellé s'affiche). */
function NavIcon({ name }: { name: string }) {
  const paths: Record<string, React.ReactNode> = {
    "/jouer": <path d="M8 5.5v13l11-6.5z" />,
    "/boosters": (
      <>
        <rect x="5" y="3" width="14" height="18" rx="2.5" />
        <path d="M5 8h14M12 11v6M9 14h6" />
      </>
    ),
    "/collection": (
      <>
        <rect x="3" y="6" width="11" height="15" rx="2" />
        <path d="M8 3h11a2 2 0 0 1 2 2v13" />
      </>
    ),
    "/amis": (
      <>
        <circle cx="9" cy="8" r="3.2" />
        <path d="M3 20c.6-3.6 3-5.5 6-5.5s5.4 1.9 6 5.5" />
        <circle cx="17" cy="9" r="2.5" />
        <path d="M16.5 14.6c2.4.2 4 1.8 4.5 4.6" />
      </>
    ),
  };
  return (
    <svg className="nav-icon" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      {paths[name]}
    </svg>
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
            <NavIcon name={item.href} /> <span className="nav-label">{item.label}</span>
          </Link>
        ))}
      </nav>
      <div className="header-tools">
        <InviteQr />
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
      </div>
    </header>
  );
}
