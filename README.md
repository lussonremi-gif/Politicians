# « Qui l'a dit ? » · Présidentielle 2027

Jeu de cartes en ligne : une citation, deux noms, un seul bon. Chaque bonne réponse rapporte des points et une carte ;
les points ouvrent des boosters pour compléter sa collection. Le verso de chaque carte donne le contexte et la source.

**Stack :** Next.js (App Router) déployé sur **Vercel**, **Supabase** pour la base Postgres, l'authentification
(comptes invités anonymes) et la logique de jeu (fonctions SQL).

## Ce que contient la v1

| Écran | Route | Contenu |
|---|---|---|
| Accueil | `/` | Présentation et boucle de jeu |
| Partie | `/jouer` | 10 citations, deux propositions, révélation du contexte, points, séries |
| Collection | `/collection` | Cartes possédées, progression par rareté, filtre par personnalité, verso au clic |
| Boosters | `/boosters` | Classique, premium, thématiques et par candidat, ouverture animée |
| À propos / Méthodologie | `/a-propos`, `/methodologie` | Règles du jeu et règles éditoriales |

Pas encore fait : duel en temps réel, mode chrono, défi entre amis, comptes avec e-mail.

### Sécurité anti-triche
Le client ne connaît jamais la bonne réponse avant d'avoir répondu : la table `quotes` n'est lisible que pour les
cartes déjà possédées (RLS), et tout passe par des fonctions Postgres `security definer` :

- `start_game(n)` : tire n citations vérifiées de candidats et leur adversaire (le « piège » éditorial
  `decoy_personality_id` s'il existe, sinon une autre personnalité au hasard)
- `next_question(session)` : renvoie la question et l'horodate côté serveur (pour le bonus de rapidité)
- `submit_answer(question, choix)` : vérifie la réponse, calcule les points, ajoute la carte, renvoie le contexte
- `open_booster(slug)` : débite les points et tire les cartes selon les probabilités du booster

Le joueur ne peut modifier que son `username` ; les points ne changent que via ces fonctions.

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
3. **SQL Editor** : exécuter `supabase/migrations/20261014000000_init.sql`, puis `supabase/seed.sql` pour les données de démo.
   Avec la CLI : `supabase link --project-ref <ref>` puis `supabase db push`.
4. Récupérer l'URL du projet et la clé `anon` (Project Settings → API).

### 2. En local
```bash
cp .env.example .env.local   # renseigner les deux variables
npm install
npm run dev                  # http://localhost:3000
```

### 3. Vercel
1. Importer le dépôt GitHub sur [vercel.com/new](https://vercel.com/new) (framework détecté : Next.js).
2. Ajouter les variables d'environnement `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
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
