export const metadata = { title: "Méthodologie · Qui l'a dit ?" };

export default function Methodology() {
  return (
    <article className="prose">
      <h1 className="headline">Méthodologie</h1>
      <span className="tricolor" aria-hidden />
      <h2>Citations exactes et sourcées</h2>
      <p>
        Chaque citation renvoie à une source d&apos;origine vérifiable : vidéo, interview, discours ou publication.
        Aucune citation n&apos;est inventée ni sortie de son contexte. Seules les citations dont la source a été
        contrôlée sont jouables.
      </p>
      <h2>Rareté des cartes</h2>
      <p>
        La rareté d&apos;une carte reflète le retentissement de la citation (reprises, notoriété, place dans
        l&apos;histoire politique), pas un jugement sur la personne ou sur ses idées. Les deux personnalités proposées
        sont affichées dans un ordre aléatoire.
      </p>
      <h2>Photos</h2>
      <p>
        Les portraits proviennent de Wikimedia Commons, sous licence libre (domaine public, CC0, CC BY ou CC BY-SA).
        L&apos;auteur, la licence et un lien vers la source figurent au verso de chaque carte.
      </p>
      <h2>Mise à jour</h2>
      <p>De nouvelles cartes sont ajoutées au fil de l&apos;actualité, après vérification de leur source.</p>
    </article>
  );
}
