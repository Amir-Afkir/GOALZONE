# App Guide For AI Agents

## Scope

This file applies to the Phoenix app in `social_app/`.

Use it together with:

- [`/Users/Amir/Desktop/Reseau social/AGENTS.md`](/Users/Amir/Desktop/Reseau%20social/AGENTS.md)
- [`/Users/Amir/Desktop/Reseau social/social_app/README.md`](/Users/Amir/Desktop/Reseau%20social/social_app/README.md)

## First Files To Open

For most tasks, start here:

1. [`/Users/Amir/Desktop/Reseau social/social_app/lib/social_app_web/router.ex`](/Users/Amir/Desktop/Reseau%20social/social_app/lib/social_app_web/router.ex)
2. matching LiveView/controller
3. matching template/component
4. [`/Users/Amir/Desktop/Reseau social/social_app/assets/app.css`](/Users/Amir/Desktop/Reseau%20social/social_app/assets/app.css)
5. matching test file

## File-By-File Conventions

### `lib/social_app/`

- This is business logic first.
- Prefer changing contexts here before pushing logic into LiveViews.
- If data shape changes, inspect matching schema and migration.

### `lib/social_app_web/router.ex`

- Treat as the source of truth for page entry points and auth boundaries.
- When changing a page, verify whether it is behind `require_authenticated_user`.

### `lib/social_app_web/live/`

- Keep LiveViews thin.
- Prefer orchestration, assigns, and event wiring here.
- Avoid embedding business rules that belong in contexts.

### `lib/social_app_web/live/feed_live/components.ex`

- This file is large and high-impact.
- Before editing, identify whether the change is:
  - structure/markup
  - copy/text
  - routing link
  - action wiring
- For layout issues on `/`, inspect this file together with `layouts/app.html.heex`, `layouts/root.html.heex`, and `assets/app.css`.

### `lib/social_app_web/components/layouts/`

- `root.html.heex`: global document shell
- `app.html.heex`: in-app shell
- Layout bugs usually come from interaction between these files and `assets/app.css`, not from LiveView alone.

### `assets/app.css`

- This is the global stylesheet.
- Avoid duplicate selector blocks for the same page structure.
- When changing `/`, prefer a single source of truth for:
  - `.app-main-feed`
  - `.feed-scene`
  - `.feed-layout`
  - `.feed-main-column`
  - feed sidebars
- If you introduce a new page-specific section, keep its selectors grouped together.

### `assets/app.js`

- Only lightweight browser behavior belongs here.
- Do not move business logic into client JS.

### `test/social_app/`

- Context and domain behavior tests live here.
- If you change business logic, add or update tests here first.

### `test/social_app_web/`

- LiveView, controller, and auth behavior tests live here.
- For page changes, verify whether an existing LiveView test should be updated.

## Recommended Task Flows

### Page behavior

Route -> LiveView -> component markup -> CSS -> test

### Data behavior

Context -> schema -> migration -> test -> LiveView usage

### Auth behavior

Router -> `user_auth.ex` -> LiveView/controller -> test

## Local Docs

Use these when the task touches frontend or TTC-inspired behavior:

- frontend spec: [`/Users/Amir/Desktop/Reseau social/social_app/docs/10-goalzone-ai-frontend-spec.md`](/Users/Amir/Desktop/Reseau%20social/social_app/docs/10-goalzone-ai-frontend-spec.md)
- implementation mapping: [`/Users/Amir/Desktop/Reseau social/social_app/docs/11-ttc-phoenix-mapping.md`](/Users/Amir/Desktop/Reseau%20social/social_app/docs/11-ttc-phoenix-mapping.md)

## Low-Signal Areas

Usually ignore unless explicitly needed:

- `_build/`
- `deps/`
- `tmp/`
- `test-results/`

## Working Rule

When implementation and docs diverge, state it explicitly and treat code as the current behavior unless the task is to restore the documented intent.
