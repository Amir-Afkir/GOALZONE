# SocialApp (Phoenix skeleton)

Structure manuelle d'un projet Phoenix LiveView alignee sur la doc du projet.

## Contexte

Cette arborescence a ete generee sans `mix phx.new` car `mix`/`elixir` ne sont pas installes sur la machine.

## Modules metier inclus

- `SocialApp.Accounts`
- `SocialApp.Posts`
- `SocialApp.Feed`
- `SocialApp.Notifications`

## Modules web inclus

- `SocialAppWeb.Endpoint`
- `SocialAppWeb.Router`
- LiveViews: feed, post detail, notifications
- `SocialAppWeb.Presence`

## Migrations incluses

- users
- posts
- follows (PK composite + contrainte anti auto-follow)
- likes (unique user/post)
- comments
- notifications

## Quand Elixir est disponible

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Puis ouvrir [http://localhost:4000](http://localhost:4000).
# GOALZONE
