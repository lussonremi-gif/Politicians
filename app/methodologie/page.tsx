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
      <h2>Neutralité</h2>
      <p>
        Chaque candidat reçoit le même nombre de cartes, les mêmes raretés et le même traitement visuel. Les
        propositions sont affichées dans un ordre aléatoire.
      </p>
      <h2>Cartes de personnalités</h2>
      <p>
        Chaque personnalité existe en trois versions datées. La règle est la même pour tous : la version la plus
        ancienne est légendaire, la suivante rare, et la « Saison 2026 » commune. Les boosters ont les mêmes
        probabilités quel que soit le parti.
      </p>
      <h2>Photos</h2>
      <p>
        Les portraits proviennent de Wikimedia Commons, sous licence libre (domaine public, CC0, CC BY ou CC BY-SA).
        L&apos;auteur, la licence et un lien vers la source figurent au verso de chaque carte.
      </p>
      <h2>Mise à jour</h2>
      <p>La liste des candidats évolue au fil des déclarations de candidature.</p>
      <h2>Données de démonstration</h2>
      <p>
        Pendant la phase de test, le jeu peut contenir des personnalités et des citations <strong>fictives</strong>,
        signalées par la mention « Démo · fictif ». Elles servent uniquement à tester le jeu et ne correspondent à aucune
        déclaration réelle.
      </p>
    </article>
  );
}
