import Link from "next/link";

export default function Home() {
  return (
    <section className="hero">
      <div className="quote-glyph" aria-hidden>“</div>
      <h1 className="headline">« Qui l&apos;a dit ? »</h1>
      <span className="tricolor" aria-hidden />
      <p className="lead">
        Une vraie citation, deux personnalités politiques : qui l&apos;a dit ? Des phrases cultes de la Ve République
        aux petites phrases d&apos;aujourd&apos;hui, gagnez les cartes et complétez votre collection.
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
        <li><strong>Collectionner</strong><span>De commune à mythique</span></li>
        <li><strong>Apprendre</strong><span>Date, occasion, source</span></li>
      </ol>

      <p className="muted small-text">Modes classique et chrono, séries par thème, duels en temps réel et classement entre amis.</p>
    </section>
  );
}
