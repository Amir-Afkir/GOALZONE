# GOALZONE - AI Frontend Spec
### Reference document for frontend development with AI assistance

**Product:** GoalZone  
**Type:** Football scouting social network  
**Purpose:** Provide a precise UI/UX + frontend system reference so an AI can generate consistent code without redesigning the product.  
**Status:** Source of truth for frontend implementation

---

# 1. Mission

GoalZone is a **football scouting social network** for:

- players (U15-U23)
- coaches
- scouts
- agents

The platform is not a casual social app.  
It is a **career-oriented football product**.

The frontend must communicate:

- serious scouting credibility
- premium product quality
- modern SaaS clarity
- football identity
- fast onboarding toward first action

The UI should feel like a mix of:

- **LinkedIn** -> network structure
- **Hudl / Wyscout** -> scouting logic
- **Stripe / Linear** -> UI polish and clarity
- **Nike Football / EA Sports FC** -> sports energy and visual identity

---

# 2. Primary UX Goals

Every frontend decision must support these 3 outcomes:

1. **Publish first highlight quickly**
2. **Discover and follow mercato**
3. **Build network in the first session**

Core desired actions:

- publish
- follow
- explore

Do not add UI that distracts from those actions.

---

# 3. Non-Negotiable Rules

## 3.1 Preserve the product identity
Do not redesign GoalZone into another product style.

Keep:

- dark green stadium atmosphere
- yellow accent
- football vocabulary
- 3-column network layout
- premium scouting tone

## 3.2 Do not gamify
Avoid:

- cartoon visuals
- playful badges everywhere
- childish gradients
- loud animations
- arcade-style UI

## 3.3 Do not overcomplicate
Prefer:

- clean hierarchy
- modular components
- short text
- minimal friction
- obvious CTA structure

---

# 4. Layout System

GoalZone uses a **3-column desktop layout**.

## Desktop structure

```txt
| Left Sidebar | Main Feed | Right Sidebar |
```

### Recommended widths

- Left Sidebar: `240px`
- Main Feed: `minmax(640px, 720px)`
- Right Sidebar: `320px`

### Desktop container

- max-width: `1440px`
- horizontal padding: `24px`
- gap between columns: `24px`

## Tablet behavior

- Right sidebar may move below main feed
- Left sidebar remains visible if space allows
- Keep composer visible early

## Mobile behavior

- Left sidebar becomes bottom navigation
- Right sidebar content collapses under feed or into cards
- Coach IA remains accessible but must not block core CTA
- Composer must remain high in the page

---

# 5. Page Architecture

## Main home/feed page = `Terrain`

### Existing structure to preserve

```txt
Sidebar
Feed tabs
Composer
Empty state or feed posts
Mercato suggestions
Right suggestions
Coach IA
```

### Recommended visual order in main feed

```txt
1. Feed tabs
2. Composer
3. Compact onboarding / empty state
4. Suggested mercato or first cards
5. Feed content
```

## Cross-page product flow

GoalZone's core page flow must stay readable across the app:

```txt
Terrain -> Mercato -> Reseau -> Messages
```

Meaning:

- `Terrain` = publish and enter the product quickly
- `Mercato` = discover opportunities and qualify targets
- `Reseau` = convert interesting profiles into active connections
- `Messages` = move a connection toward a concrete next step

Each page should feel distinct, but they must clearly belong to the same product system.

## Page pattern roles

### `Terrain` = action-first feed page

This page is the primary activation surface.

It should prioritize:

- immediate publishing
- simple feed controls
- clear discovery of first opportunities
- fast understanding of the product

Its pattern is:

```txt
Toolbar
Composer
Onboarding or first useful content
Feed stream
```

### `Mercato` = editorial board page

This page is the strongest internal reference for structured central-column hierarchy.

It should prioritize:

- strong page promise
- one clear primary CTA and one supporting CTA
- search / filter / board rhythm
- highly scannable opportunity cards

Its pattern is:

```txt
Title ribbon or compact hero
Intro action shell
Search and filters
Results board
```

### `Reseau` = relational activation page

This page should not behave like a flat directory.

It should prioritize:

- identifying who to connect with now
- distinguishing suggestions from existing relationships
- helping the user move from connection to conversation
- keeping the next action obvious

Its recommended pattern is:

```txt
Compact hero
Relationship dashboard
Profiles to connect now
Active network
Bridge to messages
```

### `Messages` = conversion page

This page exists to continue momentum started on `Reseau`.

It should prioritize:

- clear thread hierarchy
- strong next-step language
- low-friction follow-up actions

## Current implementation mismatch

At the time of writing, `/reseau` is functionally useful but does not yet fully match the intended page pattern above.

Current gap:

- the page behaves more like a simple directory list
- the central hierarchy is weaker than on `/mercato`
- suggestions and active connections are not visually differentiated enough
- the transition from `Reseau` to `Messages` is not strong enough in the main content area

This mismatch should be treated as a frontend refactor target, not as the desired long-term product standard.

---

# 6. Design Tokens

## 6.1 Colors

### Background

```txt
--gz-bg-primary: #051A0D;
--gz-bg-secondary: #0A1F1A;
--gz-bg-tertiary: #0B2B1F;
```

### Surfaces

```txt
--gz-surface-glass: rgba(10, 31, 26, 0.60);
--gz-surface-glass-strong: rgba(10, 31, 26, 0.78);
--gz-surface-muted: rgba(255, 255, 255, 0.03);
```

### Accent

```txt
--gz-accent-primary: #E6FB04;
--gz-accent-primary-soft: rgba(230, 251, 4, 0.14);
--gz-accent-primary-glow: rgba(230, 251, 4, 0.22);
```

### Text

```txt
--gz-text-primary: #F8FAFC;
--gz-text-secondary: #A1A1AA;
--gz-text-muted: #71717A;
--gz-text-dark-on-accent: #111111;
```

### Borders

```txt
--gz-border-subtle: rgba(230, 251, 4, 0.10);
--gz-border-default: rgba(255, 255, 255, 0.08);
--gz-border-strong: rgba(230, 251, 4, 0.18);
```

### Status / support

Use very sparingly:

```txt
--gz-success: #22C55E;
--gz-warning: #F59E0B;
--gz-danger: #EF4444;
```

Do not let support colors dominate the interface.

---

## 6.2 Typography

### Headings

Purpose:

- navigation
- section titles
- hero / empty state titles

Style:

- uppercase
- condensed
- bold / extra-bold

Recommended fonts:

- `Inter Tight`
- `Oswald`

Examples:

- TERRAIN
- TALENTS
- LE TERRAIN ATTEND

### Body / UI text

Purpose:

- labels
- descriptions
- stats
- placeholders
- cards

Recommended fonts:

- `Inter`
- `Geist`
- `SF Pro Display`

Rules:

- prioritize readability
- avoid decorative fonts
- keep line-height comfortable

---

## 6.3 Font Sizes

```txt
--gz-text-xs: 12px;
--gz-text-sm: 14px;
--gz-text-base: 16px;
--gz-text-lg: 18px;
--gz-text-xl: 20px;
--gz-text-2xl: 28px;
--gz-text-3xl: 40px;
--gz-text-4xl: 56px;
```

### Typical usage

- Sidebar labels: `14px uppercase`
- Body copy: `16px`
- Card metadata: `12px-14px`
- Section titles: `20px-28px`
- Empty state headline: `40px+`

---

## 6.4 Spacing Scale

```txt
--gz-space-1: 4px;
--gz-space-2: 8px;
--gz-space-3: 12px;
--gz-space-4: 16px;
--gz-space-5: 20px;
--gz-space-6: 24px;
--gz-space-8: 32px;
--gz-space-10: 40px;
--gz-space-12: 48px;
--gz-space-16: 64px;
```

Rules:

- use 8px rhythm where possible
- cards should breathe
- avoid dense clusters of buttons

---

## 6.5 Radius

```txt
--gz-radius-sm: 10px;
--gz-radius-md: 14px;
--gz-radius-lg: 18px;
--gz-radius-xl: 22px;
--gz-radius-pill: 9999px;
```

Usage:

- buttons: `12px-14px`
- cards: `18px`
- main panels: `22px`
- pills / filters: `9999px`

---

## 6.6 Shadows and Glow

```txt
--gz-shadow-soft: 0 8px 30px rgba(0, 0, 0, 0.28);
--gz-shadow-panel: 0 12px 40px rgba(0, 0, 0, 0.35);
--gz-glow-accent: 0 0 0 1px rgba(230,251,4,0.10), 0 0 18px rgba(230,251,4,0.12);
```

Rules:

- shadows must stay soft
- glow must stay subtle
- avoid neon overload

---

## 6.7 Blur / Glass

```txt
--gz-blur-card: 20px;
--gz-blur-soft: 12px;
```

Glass panels should use:

- translucent dark surface
- subtle border
- blur
- soft shadow

---

# 7. Grid and Composition Rules

## 7.1 Horizontal rhythm

- Left aligned major blocks
- Consistent gaps between columns
- Cards align to clean vertical rails

## 7.2 Content hierarchy

Always prioritize:

1. primary action
2. supporting action
3. context / explanation

## 7.3 Visual density

GoalZone should feel:

- premium
- calm
- intentional

Never:

- cramped
- overloaded
- noisy

---

# 8. Core Components

## 8.1 Sidebar

### Contains

- GoalZone logo
- subtitle: `RESEAU SOCIAL FOOTBALL`
- navigation
- primary publish button
- account card

### Navigation items

- TERRAIN
- MERCATO
- RESEAU
- MESSAGES
- ALERTES
- PROFIL

### Active nav state

- yellow accent
- subtle glow
- darker surface
- left highlight bar or stronger border

### Primary CTA

Text:

```txt
Publier
```

or

```txt
Publier un highlight
```

This is a support CTA, not the strongest action on the page.
The composer in the feed remains the true primary action.

---

## 8.2 Feed Tabs

Tabs:

- Pour vous
- Abonnes
- Mercato
- Opportunites

Style:

- pill shape
- dark glass background
- active state in yellow or yellow outline/glow

Do not over-style.
These tabs should feel like **Linear / SaaS controls**, not flashy chips.

---

## 8.3 Feed Composer

### Role

The composer is the **most important conversion component** on the page.

### Must communicate

"Post your first highlight now."

### Structure

```txt
Avatar
Input
Action pills
```

### Recommended placeholder

```txt
Publie ton highlight...
```

Secondary hint example:

```txt
but, passe cle, arret, dribble
```

### Action pills

- Action
- Video
- Analyse
- Photo

Rules:

- same family style
- touch-friendly
- consistent spacing
- subtle hover/focus glow

### Composer interaction

- slight expansion on focus
- visible focus ring
- no large animation

---

## 8.4 Empty State / Onboarding Block

### Role

Motivate action without blocking the feed.

### Rules

- keep compact
- keep copy short
- avoid "dead page" feeling
- support first highlight and follow actions

### Good structure

Headline:

```txt
LE TERRAIN ATTEND TON PREMIER MOUVEMENT
```

Supporting text:

```txt
Publie ton premier highlight et commence a construire ton reseau.
```

CTA hierarchy:

1. Publier un highlight
2. Explorer / Suivre des mercato

Avoid long paragraphs.

---

## 8.5 Talent Suggestions

### Role

Make the platform feel alive and useful immediately.

### Structure of a talent card

- avatar
- player name
- age
- position
- club
- 1-2 stats
- follow button

### Suggested stats

- Vitesse
- Passe
- Finition
- Vision
- Endurance

Do not overload the card with too many metrics.

---

## 8.6 Right Sidebar

### Contains

- suggestions to follow
- supporting player discovery
- optional scouting helper content

### Rules

- secondary importance
- clean cards
- must not overpower the feed
- should support following behavior

---

## 8.7 Coach IA

### Role

A product guide, not a tooltip.

### Goals

- reduce activation friction
- guide new users to first actions
- remain subtle

### Recommended content

- Publish your first highlight
- Follow 5 mercato
- Activate your network

### Rules

- compact
- dismissible
- visible but not dominant
- should not duplicate the entire onboarding copy

---

# 9. Motion and Interaction Rules

## General motion principles

Animations must feel:

- professional
- subtle
- responsive

Avoid:

- bouncy overshoot everywhere
- exaggerated entrance animations
- game-like motion

## Allowed interactions

- hover glow
- focus ring
- slight elevation on hover
- pill transition
- soft fade / slide on load

## Coach IA

May use:

- subtle breathing pulse
- very light float

## Composer

May use:

- slight scale or shadow increase on focus

---

# 10. Accessibility Rules

- meet strong dark-mode contrast
- touch targets minimum `40px`, ideally `44px`
- keyboard accessible buttons and controls
- visible focus states
- semantic HTML
- no text too small on mobile
- avoid text over complex background without strong overlay

---

# 11. Background and Atmosphere Rules

GoalZone should visually evoke:

- a football stadium at night
- center field perspective
- floodlights glow
- depth behind the UI

Background should remain:

- subtle
- blurred
- secondary to content

The background is not the hero.
The UI and content remain the hero.

---

# 12. Tailwind Mapping

## Colors

Example mapping:

```js
colors: {
  gz: {
    bg: "#051A0D",
    surface: "rgba(10,31,26,0.78)",
    accent: "#E6FB04",
    text: "#F8FAFC",
    muted: "#A1A1AA",
    border: "rgba(230,251,4,0.12)"
  }
}
```

## Radius

```js
borderRadius: {
  sm: "10px",
  md: "14px",
  lg: "18px",
  xl: "22px",
  pill: "9999px"
}
```

## Shadows

```js
boxShadow: {
  "gz-soft": "0 8px 30px rgba(0,0,0,0.28)",
  "gz-panel": "0 12px 40px rgba(0,0,0,0.35)",
  "gz-glow": "0 0 0 1px rgba(230,251,4,0.10), 0 0 18px rgba(230,251,4,0.12)"
}
```

## Blur

```js
backdropBlur: {
  xs: "2px",
  sm: "4px",
  md: "12px",
  lg: "20px"
}
```

---

# 13. Suggested React Component Tree

```txt
GoalzoneLayout
|- Sidebar
|  |- Logo
|  |- NavList
|  |- PublishButton
|  `- AccountCard
|- MainFeed
|  |- FeedTabs
|  |- FeedComposer
|  |- EmptyStateCard
|  |- MercatoRow
|  `- FeedList
`- RightSidebar
   |- SuggestionsCard
   |- SuggestedPlayerList
   `- CoachAssistant
```

---

# 14. Copywriting Tone

Copy must be:

- short
- direct
- premium
- football-specific

Good examples:

- Publie ton highlight
- Suivre des mercato
- Explorer le reseau
- Active ton reseau

Avoid vague generic social copy.

---

# 15. AI Coding Instructions

When an AI generates frontend code for GoalZone, it must follow these rules:

## 15.1 Improve, do not reinvent

If a codebase already exists:

- preserve layout
- preserve identity
- preserve component structure
- only polish and improve

## 15.2 Prioritize the composer

The composer is the most important UI element for activation.
Make it visually clear and easy to use.

## 15.3 Empty states must stay compact

Do not create giant hero blocks that make the platform feel empty.

## 15.4 Keep the right sidebar secondary

Do not let it visually compete with the main feed.

## 15.5 Use the accent color with intention

Yellow is for:

- active elements
- CTA
- focus
- highlights

Do not flood the interface with yellow.

---

# 16. Reference Prompt for AI

Use this when asking an AI to code or improve GoalZone UI:

```txt
You are improving an existing GoalZone frontend, not redesigning it from scratch.

Preserve:
- 3-column layout
- dark green football stadium identity
- yellow accent
- premium scouting tone
- existing component structure

Only improve:
- spacing
- hierarchy
- CTA visibility
- composer clarity
- onboarding compactness
- talent discovery cards
- subtle motion polish

Do not rewrite the whole page.
Do not change the product identity.
Do not introduce playful or gaming UI.
Keep the interface serious, premium, sporty, and SaaS-clean.
```

---

# 17. Final Product Statement

GoalZone should feel like:

```txt
LinkedIn
+
Hudl
+
Stripe
+
Nike Football
```

The final frontend must look like a **football career console**, not a generic social feed.

It must be:

- premium
- professional
- immersive
- football-native
- activation-focused
