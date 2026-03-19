# GoalZone App

Application Phoenix LiveView du projet.

## App Root

Ce dossier `social_app/` est le vrai root technique du code:

- `mix.exs` vit ici
- les commandes `mix` doivent etre lancees ici
- le repo Git de l'application est ici

## Architecture Rapide

### Entrees importantes

- routeur: [`lib/social_app_web/router.ex`](/Users/Amir/Desktop/Reseau%20social/social_app/lib/social_app_web/router.ex)
- layout global: [`lib/social_app_web/components/layouts/app.html.heex`](/Users/Amir/Desktop/Reseau%20social/social_app/lib/social_app_web/components/layouts/app.html.heex)
- layout racine: [`lib/social_app_web/components/layouts/root.html.heex`](/Users/Amir/Desktop/Reseau%20social/social_app/lib/social_app_web/components/layouts/root.html.heex)
- styles globaux: [`assets/app.css`](/Users/Amir/Desktop/Reseau%20social/social_app/assets/app.css)
- JS navigateur: [`assets/app.js`](/Users/Amir/Desktop/Reseau%20social/social_app/assets/app.js)

### Couches du projet

- `lib/social_app/`: logique metier
- `lib/social_app_web/`: web, LiveView, composants, controllers
- `assets/`: CSS + JS leger
- `priv/repo/migrations/`: schema SQL
- `test/`: tests applicatifs et web

## Domaines metier

- `Accounts`: users, auth, follows, blocks, reports
- `Posts`: posts, comments, likes
- `Feed`: assemblage du feed
- `Messaging`: threads et messages
- `Notifications`: alertes utilisateur
- `Recruitment`: shortlist / pipeline

## Pages et modules web

- `/`: `FeedLive`
- `/mercato`: `MercatoLive`
- `/reseau`: `NetworkLive`
- `/messages`: `MessagesLive`
- `/alertes`: `NotificationsLive`
- `/profile/:username`: `ProfileLive.Show`

## Lire le code efficacement

### Pour modifier une page

1. ouvrir `lib/social_app_web/router.ex`
2. trouver le LiveView ou controller
3. ouvrir le composant HEEX associe
4. verifier `assets/app.css`
5. ouvrir les tests correspondants dans `test/social_app_web/`

### Pour modifier la logique metier

1. ouvrir le contexte dans `lib/social_app/`
2. ouvrir les schemas relies
3. ouvrir les tests dans `test/social_app/`

## Commandes utiles

Depuis `social_app/`:

```bash
mix deps.get
mix assets.setup
mix assets.build
mix ecto.create
mix ecto.migrate
mix test
mix phx.server
```

Pour un build production:

```bash
mix assets.deploy
```

## Dossiers a faible signal

En general, ne pas commencer par:

- `_build/`
- `deps/`
- `tmp/`
- `test-results/`

## Docs liees

- overview repo: [`../docs/00-repo-map.md`](/Users/Amir/Desktop/Reseau%20social/docs/00-repo-map.md)
- architecture globale: [`../docs/02-architecture-globale.md`](/Users/Amir/Desktop/Reseau%20social/docs/02-architecture-globale.md)
- app agent guide: [`AGENTS.md`](/Users/Amir/Desktop/Reseau%20social/social_app/AGENTS.md)
- frontend spec: [`docs/10-goalzone-ai-frontend-spec.md`](/Users/Amir/Desktop/Reseau%20social/social_app/docs/10-goalzone-ai-frontend-spec.md)
- TTC mapping: [`docs/11-ttc-phoenix-mapping.md`](/Users/Amir/Desktop/Reseau%20social/social_app/docs/11-ttc-phoenix-mapping.md)
- refactor guide: [`docs/12-refonte-code-sans-regression.md`](/Users/Amir/Desktop/Reseau%20social/social_app/docs/12-refonte-code-sans-regression.md)
