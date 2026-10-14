import Link from "next/link";

export default function Home() {
  return (
    <section className="hero">
      <div className="quote-glyph" aria-hidden>“</div>
      <h1 className="headline">« Qui l&apos;a dit ? »</h1>
      <span className="tricolor" aria-hidden />
      <p className="lead">
        Une citation, deux noms, un seul bon. Découvrez les candidats à la présidentielle 2027 à travers leurs propres
        mots, et collectionnez les cartes.
      </p>
      <div className="actions">
        <Link href="/jouer" className="btn primary">
          Jouer une partie
        </Link>
        <Link href="/duel" className="btn">
          Défier un ami
        </Link>
        <Link href="/collection" className="btn">
          Ma collection
        </Link>
      </div>

      <ol className="loop">
        <li><strong>Jouer</strong><span>Une citation, deux noms</span></li>
        <li><strong>Gagner</strong><span>Points, rapidité, séries</span></li>
        <li><strong>Ouvrir</strong><span>Des boosters de cartes</span></li>
        <li><strong>Collectionner</strong><span>Commune, rare, légendaire</span></li>
        <li><strong>Apprendre</strong><span>Date, occasion, source</span></li>
      </ol>

      <p className="muted small-text">Modes classique et chrono, séries par thème, duels en temps réel et classement entre amis.</p>
    </section>
  );
}
