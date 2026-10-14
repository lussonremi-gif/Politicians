# « Qui l'a dit ? » · Présidentielle 2027

Jeu de cartes en ligne : une citation, deux noms, un seul bon. Chaque bonne réponse rapporte des points et une carte ;
les points ouvrent des boosters pour compléter sa collection. Le verso de chaque carte donne le contexte et la source.

**Stack :** Next.js (App Router) déployé sur **Vercel**, **Supabase** pour la base Postgres, l'authentification
(comptes invités anonymes) et la logique de jeu (fonctions SQL).

## Ce que contient la v1

| Écran | Route | Contenu |
|---|---|---|
| Accueil | `/` | Présentation et boucle de jeu |
| Partie | `/jouer` | Choix du mode (classique 10 citations ou chrono 60 s) et du thème, contexte après chaque réponse |
| Duel | `/duel` | Créer un duel (code + lien à partager), rejoindre, partie en temps réel, résultat, historique |
| Amis | `/amis` | Pseudo, code ami, ajout d'amis, classement entre amis |
| Collection | `/collection` | Album des personnalités politiques (3 versions par personnalité, cartes manquantes grisées, filtre par parti) et collection de citations |
| Boosters | `/boosters` | Personnalités (classique, premium, par parti) et citations (par thème) ; ouverture animée, plus spectaculaire selon la rareté |
| À propos / Méthodologie | `/a-propos`, `/methodologie` | Règles du jeu et règles éditoriales |

Pas encore fait : comptes avec e-mail (la partie invitée est liée au navigateur), défi asynchrone entre amis.

## Backend Supabase

Projet Supabase : **Politicians** (`kycouzwgzxmpnhzywrrh`, eu-west-1). Les migrations de `supabase/migrations/`
y sont appliquées, ainsi que les données de démo de `supabase/seed.sql`.

| Migration | Contenu |
|---|---|
| `…000000_init.sql` | Personnalités, citations, profils, collection, parties solo (classique, chrono 60 s, par thème), boosters |
| `…000100_duels.sql` | Duels 1 contre 1 en temps réel (code d'invitation, même série pour les deux joueurs, 15 s par réponse, abandons) |
| `…000200_social.sql` | Pseudo, code ami, liste d'amis, classement entre amis |
| `…000300_editorial.sql` | Rôles éditoriaux (contributeur, vérificateur, admin), validation des citations, tableau de neutralité |
| `…000400_storage.sql` | Bucket public `portraits` (écriture réservée aux éditeurs) |
| `…000500_politician_cards.sql` | Partis, personnalités, versions de cartes (année, intitulé, rareté), boosters de personnalités et par parti |
| `…000600_booster_active.sql` | Boosters désactivables (masqués de la boutique) |

Contenu de la collection : `supabase/seed_politicians.sql` (10 partis, 12 personnalités, 36 cartes). Règle de rareté
identique pour tous : la version la plus ancienne est légendaire, la suivante rare, « Saison 2026 » commune.
Photos : fichiers Wikimedia Commons sous licence libre, avec auteur et licence au verso de la carte. **À vérifier par
l'équipe éditoriale avant le lancement** (crédits marqués « Wikimedia Commons » à compléter avec le nom de l'auteur,
intitulés des versions). Le droit à l'image des personnes représentées reste à valider juridiquement, surtout si des
boosters deviennent payants.

### API (fonctions appelées via `supabase.rpc(...)`)

| Domaine | Fonctions |
|---|---|
| Partie solo | `start_game(p_question_count, p_theme, p_mode)`, `next_question(p_session)`, `submit_answer(p_question, p_choice)`, `list_themes()` |
| Collection et boosters | `collection_totals()`, `open_booster(p_slug)` ; lecture directe de `user_cards`, `booster_types` |
| Duel | `create_duel(p_theme, p_question_count)` → `{id, code}`, `join_duel(p_code)`, `duel_state(p_duel)`, `submit_duel_answer(p_duel, p_position, p_choice)`, `abandon_duel(p_duel)`, `my_duels()` |
| Amis | `add_friend(p_friend_code)`, `remove_friend(p_friend)`, `friends_leaderboard()` ; le pseudo se modifie avec `update profiles set username` |
| Éditorial | `verify_quote(p_quote, p_verified)`, vues `quotes_to_verify` et `candidate_balance` |

**Duel en temps réel :** le client s'abonne en Realtime aux changements de sa ligne `duels`
(`supabase.channel(...).on("postgres_changes", { table: "duels", filter: "id=eq.<id>" })`) et rappelle `duel_state`
à chaque changement ou à l'échéance `deadline`. Le serveur fait avancer le duel quand les deux joueurs ont répondu ou
que le temps est écoulé ; la bonne réponse n'est révélée qu'après sa propre réponse. Le vainqueur gagne 200 points et
une carte du duel. En cas d'abandon, ce bonus n'est accordé que si plus de la moitié du duel a été jouée.

**Rôles éditoriaux :** ajouter une ligne dans `editors` (`user_id`, `role`) depuis le dashboard. Un contributeur
propose des citations non vérifiées ; seul un vérificateur peut les valider (`verify_quote` exige une date et une
source). `candidate_balance` donne le nombre de cartes par candidat et par rareté pour contrôler la neutralité.

Types TypeScript à jour : `npx supabase gen types typescript --project-id kycouzwgzxmpnhzywrrh > lib/database.types.ts`.

### Sécurité anti-triche
Le client ne connaît jamais la bonne réponse avant d'avoir répondu : la table `quotes` n'est lisible que pour les
cartes déjà possédées (RLS), et tout passe par des fonctions Postgres `security definer` :

- `start_game(n)` : tire n citations vérifiées de candidats et leur adversaire (le « piège » éditorial
  `decoy_personality_id` s'il existe, sinon une autre personnalité au hasard)
- `next_question(session)` : renvoie la question et l'horodate côté serveur (pour le bonus de rapidité)
- `submit_answer(question, choix)` : vérifie la réponse, calcule les points, ajoute la carte, renvoie le contexte
- `open_booster(slug)` : débite les points et tire les cartes selon les probabilités du booster

Le joueur ne peut modifier que son `username` ; les points ne changent que via ces fonctions. Les tables
`game_questions`, `duel_questions` et `duel_answers` n'ont volontairement aucune policy : elles ne sont accessibles
qu'à travers les fonctions.

### Barème v1 (à valider avec l'équipe)
- 100 pts par bonne réponse, + jusqu'à 50 pts de bonus de rapidité (dégressif sur 15 s)
- ×1,5 dès 3 bonnes réponses d'affilée, ×2 dès 5
- 300 pts offerts à l'arrivée (de quoi ouvrir un premier booster)
- Boosters : classique 300 pts / 3 cartes (70/25/5 %), premium 800 pts / 5 cartes (50/38/12 %), thématiques 400 pts

Le barème se règle dans `supabase/migrations/…_init.sql` (fonction `submit_answer`), les prix et probabilités dans
la table `booster_types`.

## Mise en route

### 1. Supabase
1. Créer un projet sur [supabase.com](https://supabase.com).
2. **Authentication → Sign In / Providers → activer « Allow anonymous sign-ins »** (indispensable pour la partie invitée).
3. Le projet **Politicians** est déjà prêt. Pour un nouveau projet : exécuter dans l'ordre les fichiers de
   `supabase/migrations/`, puis `supabase/seed.sql` (ou `supabase link --project-ref <ref>` puis `supabase db push`).
4. Récupérer l'URL du projet et la clé `anon` (Project Settings → API).

### 2. En local
```bash
cp .env.example .env.local   # renseigner les deux variables
npm install
npm run dev                  # http://localhost:3000
```

### 3. Vercel
1. Importer le dépôt GitHub sur [vercel.com/new](https://vercel.com/new) (framework détecté : Next.js).
2. Aucune variable n'est obligatoire : l'URL et la clé publique du projet Supabase « Politicians » sont dans
   `lib/supabase.ts`. Les variables `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_ANON_KEY` permettent de viser
   un autre projet (elles sont lues au moment du build : redéployer après les avoir modifiées).
3. Déployer. Chaque push sur la branche principale redéploie automatiquement.

## Données et règles éditoriales

⚠️ **`supabase/seed.sql` ne contient que des personnalités et des citations fictives** (« Camille Exemple »,
« Louis Fictif »…), marquées `is_demo = true` et affichées avec la mention « Démo · fictif ». Aucune citation n'est
inventée puis attribuée à une personne réelle.

Pour passer au contenu réel :
```sql
delete from public.personalities where is_demo;   -- supprime aussi les citations et boosters démo liés
```
puis insérer les personnalités (`kind = 'candidate'` ou `'other'` ; `image_url` facultatif, sinon un monogramme est
affiché) et les citations avec `said_on`, `occasion`, `source_label`, `source_url`, `theme`, `rarity`.
**Seules les citations `verified = true` sont jouables** : ne passer ce champ à `true` qu'après vérification de la
source d'origine (renseigner `verified_by`).

Neutralité : prévoir le même nombre de cartes et la même répartition de raretés pour chaque candidat.
Photos : n'utiliser que des images dont les droits sont acquis (par exemple stockées dans Supabase Storage et
référencées par `image_url`).

## Structure
```
app/                 pages (accueil, jouer, collection, boosters, à propos, méthodologie)
components/          Header, AuthProvider (session invitée), QuoteCard (carte recto/verso), Portrait
lib/                 client Supabase, types
supabase/migrations  schéma, RLS et fonctions de jeu
supabase/seed.sql    données fictives de démonstration + boosters
```
