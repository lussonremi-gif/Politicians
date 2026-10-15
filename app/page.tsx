import Link from "next/link";

const MODES = [
  { href: "/jouer", icon: "🎯", title: "Jouer", text: "Solo ou duel : trouvez qui a parlé.", color: "blue" },
  { href: "/boosters", icon: "🎁", title: "Boosters", text: "Ouvrez des packs et visez la carte mythique.", color: "gold" },
  { href: "/collection", icon: "🃏", title: "Collection", text: "Toutes les phrases cultes, de commune à mythique.", color: "ink" },
  { href: "/amis", icon: "👥", title: "Amis", text: "Classement et défis entre potes.", color: "red" },
];

export default function Home() {
  return (
    <section className="home">
      <div className="home-hero">
        <p className="home-kicker">Le jeu des citations politiques</p>
        <h1 className="home-title">
          Qui l&apos;a <span className="squiggle">dit</span>&nbsp;?
        </h1>
        <div className="home-bubble">
          <span className="home-bubble-quote">« La République, c&apos;est moi&nbsp;! »</span>
          <span className="home-bubble-q">Mélenchon ou de Gaulle&nbsp;?</span>
        </div>
        <p className="lead">
          Une vraie citation, deux personnalités : à vous de trouver qui l&apos;a dite. Chaque bonne réponse vous fait
          gagner la carte.
        </p>
        <div className="actions">
          <Link href="/jouer" className="btn primary big">
            Jouer maintenant
          </Link>
        </div>
      </div>

      <div className="mode-tiles">
        {MODES.map((m) => (
          <Link key={m.href} href={m.href} className={`mode-tile tile-${m.color}`}>
            <span className="mode-icon" aria-hidden>{m.icon}</span>
            <strong>{m.title}</strong>
            <span>{m.text}</span>
          </Link>
        ))}
      </div>
    </section>
  );
}
