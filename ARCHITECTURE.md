# Neon Loop Architecture

## Status

This document describes the **Milestone 0 — Project Foundation** architecture. It is deliberately smaller than the complete vertical-slice architecture in `GameSpecifications.md`. Later systems are named here only to establish ownership; their gameplay behavior is not implemented.

The rationale for the revised downstream boundaries is recorded in `docs/decisions/0001-run-engagement-escalation-and-randomness.md`.

## Architectural principles

- Composition over deep inheritance
- Typed GDScript
- Narrow scene and script ownership
- Gameplay logic separated from presentation
- Explicit signals or typed calls between owners
- Data-driven gameplay content in future custom Resources
- Run-scoped deterministic named random streams for future gameplay draws
- Stable content ordering before future random selection
- No unnecessary global state
- Inspectable development behavior

## Display foundation

The game is designed at an internal resolution of **640 x 360** with a **16:9** aspect ratio. The project uses nearest-neighbour canvas texture filtering and integer-friendly scaling so placeholder and future pixel art remain crisp at whole-number display multiples. Letterboxing is preferable to distorting the design aspect ratio.

`GameRun` is the configured launch scene. The active display configuration belongs in `project.godot`; individual gameplay scenes must not independently redefine the internal viewport contract.

## Runtime composition

The intended composition root is:

```text
GameRun
|- RunDirector
|- PatrolController
|- CombatDirector
|- RewardDirector
|- CardSystem
|- SynergySystem
|- DowntownLoop
|- Camera2D
|- GameHUD
`- DebugOverlay
```

Canonical scene locations:

- `res://scenes/game/game_run.tscn`
- `res://scenes/stages/downtown_loop.tscn`
- `res://scenes/ui/game_hud.tscn`
- `res://scenes/debug/debug_overlay.tscn`

Their composition/presentation scripts live at:

- `res://scripts/run/game_run.gd`
- `res://scripts/stages/downtown_loop.gd`
- `res://scripts/stages/downtown_backdrop.gd`
- `res://scripts/stages/debug_lane_markers.gd`
- `res://scripts/stages/route_markers.gd`
- `res://scripts/ui/game_hud.gd`
- `res://scripts/ui/debug_overlay.gd`

`res://scripts/stages/` is an intentional, narrow addition to the recommended
directory list: it owns only the fixed stage's replaceable presentation and
debug-marker drawing.

`GameRun` owns assembly only. It is the place to connect explicit cross-owner signals when later milestones require them; it must not grow into a second implementation of each child system.

The tree above is the implemented Milestone 0 composition. The revised specification also requires this later run-scoped relationship:

```text
RunDirector
`- RunRandomStreams
```

`RunRandomStreams` is not instantiated or implemented in Milestone 0. When Milestone 3 introduces it, it is a child component owned by `RunDirector`, lives only for that run, and is not an Autoload.

## Scene ownership

### `GameRun`

- Composes the run-scoped systems, stage, camera, HUD, and debug presentation.
- Keeps all run-scoped state in the scene tree rather than a run singleton.
- Contains no Milestone 0 combat or progression loop.

### `DowntownLoop`

- Owns the fixed placeholder nighttime street presentation.
- Owns the three lane guide visuals and their visibility operation.
- Owns placeholder route nodes and spawn markers.
- Provides stage containers for future scene instances. `Interactables`, `CrewContainer`, `EnemyContainer`, and `EffectsContainer` currently hold clearly temporary drawn or labelled nonfunctional visuals; `LootContainer` and the spawn markers hold no runtime content.
- Does not own actor AI, combat, rewards, cards, or run progression.

The lane guides are development visualization, not lane movement logic. Route markers are visual placeholders, not a patrol implementation.

### `GameHUD`

- Reserves presentation regions for the minimap, Heat and timer, crew status, equipment and synergies, district cards, interventions, and extraction.
- May forward future input requests through signals.
- Does not own authoritative Heat, time, inventory, card, extraction, or crew state.

### `DebugOverlay`

- Owns development-only diagnostic presentation and debug controls.
- Handles the `F1` development key to toggle its own visibility.
- Emits a typed `lane_visibility_requested(bool)` request from its lane button or `F2` shortcut.
- Does not take ownership of stage or combat state: `GameRun` forwards the request and `DowntownLoop` remains the sole owner of lane-marker visibility.
- Must be hidden or disabled for release behavior in a later production milestone.

## Core system shells

Each Milestone 0 system extends `Node`, defines its matching `class_name`, and exposes only a typed responsibility description. No shell schedules encounters, advances time, mutates Heat, moves actors, selects rewards, resolves cards, or calculates synergies yet.

| Class | Path | Future authoritative ownership |
| --- | --- | --- |
| `RunDirector` | `res://scripts/run/run_director.gd` | Run state, timer, tactical Heat, irreversible Night Pressure, route progression, scheduling, safe extraction/boss thresholds, outcomes, multiplier, authoritative seed, and run-scoped random streams |
| `PatrolController` | `res://scripts/patrol/patrol_controller.gd` | Route sequence, travel, route modification, encounter pauses, rerouting |
| `CombatDirector` | `res://scripts/combat/combat_director.gd` | Active encounter, combatants, teams, coordination, completion, reward request, and deterministic spawn/enemy-variant draws |
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Reward tables, choice generation, presentation requests, selected reward application, authoritative coin ledger, at-most-once cluster resolution, manual streak bonus, and deterministic reward/equipment draws |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Draw pile, hand, discard pile, placement validation, resolution, and deterministic card draws |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Tag aggregation, thresholds, derived modifiers, activation events |

The descriptions above are ownership boundaries from the specification, not claims that the behavior exists in Milestone 0.

## Deferred escalation contract

`RunDirector` will be the sole authority for two separate values:

- **Heat** is a tactical district-alert value clamped from 0 through 100. It controls immediate encounter composition, elite availability, danger, and ordinary reward quality, and may be changed by finite player-facing effects.
- **Night Pressure** is non-negative, monotonically increasing run progression. It advances through eligible active simulation time and exactly-once encounter completion, controls long-term enemy/spawn scaling and major progression, and can reset only when the run ends or restarts.

Extraction and boss thresholds belong to Night Pressure, not Heat. Once crossed, thresholds latch and cannot be reopened or cleared by cooling. `RunDirector` must queue a boss crossed at an unsafe moment and begin it at the next valid transition boundary. If an extraction threshold and the boss threshold are crossed by the same authoritative update, the boss wins unless extraction was already confirmed before that update.

Heat reduction is deliberately finite. Shop cooling requires finite stock or an explicit per-run purchase limit in addition to meaningful cost, and Subway Reroute consumes a finite charge or consumable that does not regenerate merely with time. Cards, shops, and reroutes may reduce Heat but must never reduce Night Pressure, clear a queued boss, or recreate a spent progression window. None of this escalation behavior exists in Milestone 0.

## Deferred coin-cluster contract

Coin clusters are optional ambient interactions introduced with the Milestone 1 Combat Lab, not Milestone 0 loot. `RewardDirector` owns the authoritative coin ledger, each cluster's resolution state, and the manual-collection streak. Combat may request a coin reward and presentation may display a cluster, but neither may directly credit the ledger.

Manual click and the approximately 2.5-second timeout must converge on one authoritative at-most-once resolution. Either path credits the full base value exactly once. Only a successful manual resolution advances the approximately 3-second streak and may add the data-driven bonus, capped at 10% of that cluster's base value; auto-collection grants no manual bonus. The future cluster presentation may live under `LootContainer`, but that stage container remains empty and non-authoritative in Milestone 0.

Milestone 1 uses fixed authored base coin values. Once Milestone 3 introduces randomized rewards, coin-value and general reward selection consume `rewards`, equipment choices consume `equipment`, and presentation-only burst patterns consume `cosmetic` so visual changes cannot alter reward outcomes.

## Deferred deterministic randomness contract

Every future run has one authoritative integer seed owned by `RunDirector`. Its run-scoped `RunRandomStreams` child derives stable, versioned sub-seeds and maintains one deterministic generator for each required stream:

- `encounters`
- `spawns`
- `rewards`
- `equipment`
- `cards`
- `enemy_variants`
- `cosmetic`

The derivation algorithm and random-schema version must be platform-stable and documented. Gameplay owners receive only their declared stream and must not use unseeded global random calls. Before any gameplay selection, candidates must be filtered deterministically and sorted by stable content ID; scene-tree insertion order, dictionary iteration order, and presentation order are not valid ordering contracts.

The `cosmetic` stream is isolated: adding cosmetic draws must not change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. `RunRandomStreams` chooses no content itself and owns no presentation. No seed or stream runtime exists in Milestone 0.

## Deferred equipment and synergy contract

The vertical slice uses three generic equipment slots and at least nine data-driven equipment definitions. Each primary synergy—Knockback, Bleed, and Tech—must have at least three valid two-item activation combinations, and the catalogue must contain at least two items that bridge different primary synergy categories. `SynergySystem` will evaluate tags and thresholds without hard-coding equipment IDs; the exact nine-item catalogue and its current combination counts are recorded in `CONTENT_CATALOG.md`. No equipment Resource or synergy calculation exists in Milestone 0.

## Dependency direction

```text
Player input
    -> GameHUD / DebugOverlay (presentation and intent)
    -> GameRun wiring (future signal connections)
    -> run-scoped systems (future authority)
    -> stage/actor presentation (future results)
```

Presentation may observe authoritative state, but authoritative gameplay code must not depend on concrete HUD controls. Stage containers may host actors later, but the stage must not implement actor behavior.

## Autoload policy

Milestone 0 adds no Neon Loop gameplay Autoloads. The existing `_mcp_game_helper` entry belongs to the Godot AI/MCP development plugin and is not run state or shipped gameplay architecture. Future `AppState` or `SaveService` Autoloads are allowed by the specification only when their milestones require them and their reason is documented. The active run must never be managed as a singleton, and the future `RunRandomStreams` component must remain owned by its `RunDirector` rather than becoming an Autoload.

## Deferred architecture

These are intentionally absent until their owning milestones:

- Actor scenes, state machines, targeting, attacks, damage, and lane navigation
- Interactable behavior and intervention effects
- Encounter scheduling, tactical Heat, irreversible Night Pressure, safe latched thresholds, extraction, run outcomes, and summaries
- Authoritative run seed and the seven isolated, run-scoped deterministic random streams
- Coin-cluster spawning, at-most-once collection resolution, coin ledger, and manual streak bonus
- The nine equipment Resources, reward resolution, and synergy calculation/combination previews
- District card Resources, hand/deck state, drag-and-drop, and route modification
- Finite cooling purchases and reroute charges, save services, progression, shops, bosses, and procedural generation

Any change that crosses these scope boundaries should first update `IMPLEMENTATION_PLAN.md` and confirm the requested milestone.

## Foundation verification

The Godot 4.7 project-main launch resolves to runtime root `/GameRun`. A 640 x 360 capture confirms the composed stage and HUD, and the debug input path was exercised through repeated `F1` visibility changes plus `F2` lane hiding/restoration while the overlay was hidden. Game and editor logs were clean after relaunch. Evidence: `res://docs/screenshots/milestone_0_foundation.png`.
