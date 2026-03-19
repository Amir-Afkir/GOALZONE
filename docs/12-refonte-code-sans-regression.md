# 12 - Refonte Code Sans Regression

## But

Refondre le code de `social_app/` pour le rendre:

- plus lisible
- plus stable
- plus facile a faire evoluer
- plus performant a comportement egal

La regle maitre: **aucun changement de resultat final visible ou metier**.

Le produit, les routes, les interactions et les contrats de donnees doivent rester identiques, sauf correction explicite d'un bug documente.

## Definition de "sans regression"

La refonte est consideree correcte si:

- les memes routes restent disponibles
- les memes actions utilisateur produisent les memes effets
- les memes regles metier restent vraies
- les memes cas de test passent
- aucune degradation sensible de perf n'est introduite
- aucun conteneur de layout, contrat LiveView ou structure CSS critique n'est casse

## Non-Objectifs

Ce document ne couvre pas:

- une refonte produit
- un redesign
- un changement d'architecture runtime
- l'introduction d'un framework front additionnel
- une migration prematuree vers une abstraction plus complexe

## Principes De Refactor

1. **La couche qui sait fait le travail**
- `lib/social_app/`: logique metier
- `lib/social_app_web/`: orchestration web, rendu, events
- `assets/app.css`: layout, surface, etats visuels
- `assets/app.js`: seulement ce que LiveView/CSS ne peuvent pas faire proprement

2. **Le code devient plus simple ou ne change pas**
- si une refonte ajoute des couches sans clarifier le systeme, elle est refusee

3. **Une seule source de verite par sujet**
- une seule API metier pour une action
- une seule strategie de layout pour une page
- une seule definition structurelle pour un composant CSS critique

4. **Le comportement est protege avant la simplification**
- ajouter ou durcir les tests avant de deplacer de la logique

5. **Mesurer avant d'optimiser**
- aucune optimisation speculative

## Zones Prioritaires

### 1. Contextes metier

Objectif:

- rendre les API de contexte stables, explicites et testables

Problemes a eliminer:

- logique metier dispersee dans les LiveViews
- requetes Ecto dupliquees
- helpers prives flous ou generiques
- noms non metier

Cible:

- chaque use case passe par un contexte clair
- les fonctions publiques lisent comme des verbes metier
- les requetes importantes vivent dans un seul endroit

### 2. LiveViews

Objectif:

- garder les LiveViews minces

Problemes a eliminer:

- callbacks `mount`, `handle_event`, `handle_info` trop longs
- derivation repetee d'assigns
- logique de transformation de donnees dans `render`
- couplage fort entre UI et logique metier

Cible:

- LiveView = chargement, assigns, wiring d'events
- contexte = logique
- composant = rendu

### 3. HEEX et composants

Objectif:

- rendre les templates declaratifs et rapides a lire

Problemes a eliminer:

- branches trop complexes dans le markup
- duplication de sections proches
- composants trop generiques ou trop "smart"

Cible:

- composants UI explicites
- peu de logique inline
- sections clairement separables

### 4. CSS global

Objectif:

- supprimer la dette de cascade et les doublons

Problemes a eliminer:

- doubles definitions du meme selecteur
- melange layout / surface / decor dans le meme bloc
- overrides successifs qui masquent le vrai systeme
- scroll document et scroll interne melanges

Cible:

- une seule definition structurelle par composant/page
- layout decide une fois
- classes groupees par zone fonctionnelle
- decor global separe du layout local

### 5. JS navigateur

Objectif:

- garder un JS minimal et justifie

Problemes a eliminer:

- logique qui devrait rester en LiveView
- contournements JS d'un probleme CSS
- comportement non testable ou non localisable

Cible:

- hooks legers
- zero logique metier
- zero duplication de regles avec le serveur

## Regles De Conception

### Nommage

- un nom doit exprimer une intention metier ou UI reelle
- interdire les noms vagues: `data`, `item`, `thing`, `utils`, `helpers`
- preferer `list_feed_items/2` a `get_items/2`

### Fonctions

- petites
- deterministes si possible
- peu d'arguments
- retour explicite
- pas de branches inutiles

### Modules

- un module = une responsabilite
- si un module exige plusieurs titres de section pour etre compris, il est trop gros

### Abstractions

- aucune abstraction sans au moins deux usages reels ou une simplification nette
- pas de genericite anticipee

### Commentaires

- commenter le **pourquoi**
- ne jamais commenter l'evidence

## Strategie D'Execution

### Phase 1 - Cartographie

Pour chaque zone:

- identifier le point d'entree
- identifier la couche responsable
- lister les doublons
- lister les tests existants
- noter les divergences doc / code

Sortie attendue:

- une carte simple de dependances par feature

### Phase 2 - Protection

Avant refactor:

- ajouter les tests manquants sur le comportement critique
- figer les contrats utiles
- verifier les pages a fort impact:
  - `/`
  - `/messages`
  - `/profile/:username`

### Phase 3 - Simplification locale

Refactor par blocs petits et isoles:

1. contexte
2. LiveView associe
3. composant associe
4. CSS associe
5. tests

Interdiction:

- mega refactor transverse sans garde-fous

### Phase 4 - Nettoyage

Apres chaque bloc:

- supprimer code mort
- supprimer styles morts
- supprimer helpers devenus inutiles
- supprimer branches legacy non utilisees

### Phase 5 - Verification

Verifier:

- tests
- comportements critiques
- routes
- perf neutre ou meilleure
- absence de regression visuelle evidente

## Ordre Recommande Dans Ce Repo

1. `lib/social_app/`
2. `test/social_app/`
3. `lib/social_app_web/live/`
4. `lib/social_app_web/live/*/components.ex`
5. `lib/social_app_web/components/layouts/`
6. `assets/app.css`
7. `test/social_app_web/`

Raison:

- on stabilise d'abord le metier
- ensuite l'orchestration
- ensuite le rendu
- ensuite la presentation

## Regles Specifiques A Ce Projet

### Feed `/`

- ne pas melanger scroll document et scroll interne
- ne pas dupliquer les blocs CSS structurels du feed
- separer clairement:
  - layout
  - decor
  - surface des cartes
  - etats interactifs

### Layouts

- `root.html.heex` = shell document global
- `app.html.heex` = shell applicatif
- une page LiveView ne doit pas reprogrammer le shell global via du CSS implicite

### Ecto

- precharger seulement ce qui est lu
- mettre les invariants critiques en DB quand c'est legitime
- garder les requetes lisibles

### LiveView

- pas de requetes dans le template
- pas de logique metier dans les `handle_event`
- pas d'assigns derives recalcules partout

## Checklist De Revue

Avant de considerer un refactor comme acceptable:

1. Le comportement est-il identique ?
2. Le code a-t-il moins de chemins de lecture ?
3. La logique vit-elle dans la bonne couche ?
4. Une duplication a-t-elle ete supprimee ?
5. Le module ou le fichier est-il plus court ou plus clair ?
6. Les noms sont-ils metier et precis ?
7. Les tests protegent-ils la regression ?
8. Le CSS a-t-il une seule source de verite pour la structure ?
9. Y a-t-il du code ou des styles morts a supprimer ?
10. La perf est-elle au moins neutre ?

## Definition Of Done

Une refonte est terminee quand:

- le diff est plus simple que le systeme precedent
- les tests critiques passent
- aucun comportement final n'a change
- les zones mortes ont ete retirees
- un nouveau contributeur peut localiser la feature rapidement

## Regle Finale

Le meilleur refactor n'est pas celui qui impressionne.

C'est celui qui fait disparaitre de la complexite reelle, sans inventer de complexite nouvelle.
