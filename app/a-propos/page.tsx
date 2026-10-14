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
        <li>Deux noms proposés : un candidat et une autre personnalité connue.</li>
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
        <li>Chaque bonne réponse ajoute la carte de la citation à votre collection.</li>
      </ul>
      <h2>Bientôt</h2>
      <p>Duel en temps réel entre amis, mode chrono, séries thématiques.</p>
    </article>
  );
}
