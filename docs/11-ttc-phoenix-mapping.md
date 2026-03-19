# TTC -> Phoenix Mapping (Implementation Notes)

## Objectif
Reproduire l'experience principale de `/Users/Amir/Desktop/TTC` (reseau social football + recrutement) avec la stack Phoenix de `social_app`.

## Ce qui a ete implemente

### 1) Donnees et metier
- Enrichissement des `users`:
  - role, onboarding_completed, headline, position, age, region, level, availability, bio
  - source_type, verification_status, confidence_score
- Enrichissement des `posts`:
  - competition, opponent, match_minute
  - source_type, verification_status, confidence_score
  - community_type, media_url
- Nouveau pipeline recrutement:
  - table `shortlist_entries` + contexte `SocialApp.Recruitment`
  - ajout/retrait shortlist, progression d'etape, compteurs de stages
- Nouvelle messagerie:
  - tables `message_threads`, `messages` + contexte `SocialApp.Messaging`
  - thread direct (pair unique), envoi de message, compteurs de threads
- Moderation:
  - tables `blocks`, `reports`
- Notifications:
  - ajout `thread_id`
  - types etendus: `shortlist_added`, `message_received`, `system`

### 2) Ecrans LiveView TTC-inspired
- `FeedLive`:
  - dashboard signaux (connexions, conversations, alertes, pipeline)
  - composer enrichi avec metadonnees de preuve
  - actions pipeline par post (add/remove shortlist + stage)
- `MercatoLive` (`/mercato`):
  - recherche + filtres role/region/niveau/disponibilite
- `NetworkLive` (`/reseau`):
  - connexions actives + suggestions + follow/unfollow
- `MessagesLive` (`/messages`):
  - liste de threads, creation thread, conversation, envoi
  - deep links supportes: `?to=<user_id>` et `?thread=<thread_id>`
- `ProfileLive.Show` (`/profile/:username`):
  - carte profil football + actions follow/block/report + contact
- `ProfileLive.Edit` (`/profile/edit`):
  - edition role/profil/preuves
- `NotificationsLive` (`/alertes` et `/notifications`):
  - vue alertes + ouverture vers post/thread/reseau

### 3) Navigation / UX
- Navbar principale alignee TTC:
  - Terrain, Mercato, Reseau, Messages, Alertes, Profil
- Theme football conserve et etendu avec classes pour:
  - dashboard metrics
  - cards directory/network
  - threads/messages
  - pills de statut/pipeline

## Fichiers principaux impactes
- Migration:
  - `priv/repo/migrations/20260308020000_add_ttc_features.exs`
- Contextes:
  - `lib/social_app/recruitment.ex`
  - `lib/social_app/messaging.ex`
  - `lib/social_app/accounts.ex` (directory, block/report, follow notifications)
  - `lib/social_app/posts.ex` (notifications + champs preuves)
  - `lib/social_app/notifications.ex`
- Schemas:
  - `lib/social_app/accounts/user.ex`
  - `lib/social_app/posts/post.ex`
  - `lib/social_app/notifications/notification.ex`
  - `lib/social_app/recruitment/shortlist_entry.ex`
  - `lib/social_app/messaging/thread.ex`
  - `lib/social_app/messaging/message.ex`
  - `lib/social_app/accounts/block.ex`
  - `lib/social_app/accounts/report.ex`
- LiveViews:
  - `lib/social_app_web/live/feed_live.ex`
  - `lib/social_app_web/live/mercato_live.ex`
  - `lib/social_app_web/live/network_live.ex`
  - `lib/social_app_web/live/messages_live.ex`
  - `lib/social_app_web/live/profile_live/show.ex`
  - `lib/social_app_web/live/profile_live/edit.ex`
  - `lib/social_app_web/live/notifications_live.ex`
- Routing/layout/style:
  - `lib/social_app_web/router.ex`
  - `lib/social_app_web/components/layouts/app.html.heex`
  - `assets/app.css`
  - `priv/static/assets/app.css`

## Validation
- `mix format` OK
- `mix compile` OK
- `mix test` OK (123 tests, 0 failures)
- `mix ecto.migrate` OK

## Simplifications volontaires vs TTC
- Pas d'upload media natif complet (champ `media_url` prepare mais workflow simplifie).
- Pas de realtime Firestore-like par collection; realtime via LiveView/PubSub sur events cles.
- Alertes gardees volontairement simples (model notification compact).
