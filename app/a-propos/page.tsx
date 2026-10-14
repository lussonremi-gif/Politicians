export const metadata = { title: "À propos · Qui l'a dit ?" };

export default function About() {
  return (
    <article className="prose">
      <h1 className="headline">À propos</h1>
      <span className="tricolor" aria-hidden />
      <p className="lead">
        « Qui l&apos;a dit ? » est un jeu de cartes en ligne qui fait découvrir les candidats à la présidentielle 2027 à
        travers leurs propres citations.
      </p>
      <h2>Le principe</h2>
      <ul>
        <li>Une citation affichée à l&apos;écran.</li>
        <li>Deux personnalités politiques proposées, avec leur photo.</li>
        <li>Un seul choix, une seule bonne réponse.</li>
        <li>Après chaque réponse, le contexte de la citation : date, occasion, source.</li>
      </ul>
      <h2>La boucle de jeu</h2>
      <p>Jouer → gagner des points → ouvrir un booster → collectionner → apprendre → rejouer.</p>
      <h2>Le barème (version de test)</h2>
      <ul>
        <li>100 points par bonne réponse.</li>
        <li>Bonus de rapidité : jusqu&apos;à 50 points, dégressif sur 15 secondes.</li>
        <li>Série : ×1,5 dès 3 bonnes réponses d&apos;affilée, ×2 dès 5.</li>
        <li>Chaque bonne réponse ajoute la carte (la personnalité et sa citation) à votre collection.</li>
      </ul>
      <h2>Les cartes</h2>
      <p>
        Une carte = une personnalité + une de ses citations. Les mêmes cartes servent au jeu et à la collection. Leur
        rareté dépend du retentissement de la phrase : commune, peu commune, rare, épique, légendaire et mythique (« Je
        vous ai compris ! », « La République, c&apos;est moi ! »…).
      </p>
      <h2>Les modes de jeu</h2>
      <ul>
        <li><strong>Classique</strong> : 10 citations, avec le contexte après chaque réponse.</li>
        <li><strong>Chrono</strong> : un maximum de bonnes réponses en 60 secondes.</li>
        <li><strong>Thèmes</strong> : débats d&apos;entre-deux-tours, grands discours, campagnes, petites phrases.</li>
        <li>
          <strong>Duel</strong> : 1 contre 1 en temps réel, la même série pour les deux joueurs, 15 secondes par réponse.
          Le vainqueur gagne 200 points et une carte.
        </li>
        <li><strong>Amis</strong> : ajoutez vos amis avec leur code et comparez vos scores.</li>
      </ul>
    </article>
  );
}
