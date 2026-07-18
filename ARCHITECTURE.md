# Neon Loop Architecture

## Status

This document describes the implemented **Milestone 0 — Project Foundation** and **Milestone 1 — Combat Lab** architecture. It remains deliberately smaller than the complete vertical-slice architecture in `GameSpecifications.md`. Milestone 2 and later systems are named only to preserve ownership boundaries; their gameplay behavior is not implemented.

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

The browser playtest uses a source-controlled Godot 4.7 Web export preset with thread support disabled, so the generated build can run on ordinary GitHub Pages without cross-origin-isolation headers. GitHub Actions creates and deploys the generated artifact; exported binaries are not committed to the gameplay source tree.

`GameRun` is the configured launch scene. The active display configuration belongs in `project.godot`; individual gameplay scenes must not independently redefine the internal viewport contract.

## Runtime composition

The intended composition root is:

```text
GameRun
|- RunDirector
|- PatrolController
|- CombatDirector
|- RewardDirector
|- CombatLabController
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
- `res://scenes/actors/jax.tscn`
- `res://scenes/actors/street_punk.tscn`
- `res://scenes/effects/combat_feedback.tscn`
- `res://scenes/interactables/coin_cluster.tscn`

Their composition/presentation scripts live at:

- `res://scripts/run/game_run.gd`
- `res://scripts/stages/downtown_loop.gd`
- `res://scripts/stages/downtown_backdrop.gd`
- `res://scripts/stages/debug_lane_markers.gd`
- `res://scripts/stages/route_markers.gd`
- `res://scripts/ui/game_hud.gd`
- `res://scripts/ui/debug_overlay.gd`
- `res://scripts/run/combat_lab_controller.gd`
- `res://scripts/actors/actor_controller.gd`
- `res://scripts/combat/combat_director.gd`
- `res://scripts/rewards/reward_director.gd`
- `res://scripts/effects/combat_feedback.gd`
- `res://scripts/interactables/coin_cluster.gd`

`res://scripts/stages/` is an intentional, narrow addition to the recommended
directory list: it owns only the fixed stage's replaceable presentation and
debug-marker drawing.

`GameRun` owns assembly only. It is the place to connect explicit cross-owner signals when later milestones require them; it must not grow into a second implementation of each child system.

The tree above is the implemented Milestone 1 composition. The revised specification also requires this later run-scoped relationship:

```text
RunDirector
`- RunRandomStreams
```

`RunRandomStreams` is not instantiated or implemented in Milestone 1. When Milestone 3 introduces it, it is a child component owned by `RunDirector`, lives only for that run, and is not an Autoload.

## Scene ownership

### `GameRun`

- Composes the run-scoped systems, Combat Lab, stage, camera, HUD, debug presentation, and combat feedback.
- Keeps all run-scoped state in the scene tree rather than a run singleton.
- Connects typed combat/reward signals to presentation without calculating damage, rewards, or actor decisions.
- Contains no encounter scheduling, patrol progression, Heat/Night Pressure behavior, or later run loop.

### `DowntownLoop`

- Owns the fixed placeholder nighttime street presentation.
- Owns the three lane guide visuals and their visibility operation.
- Owns placeholder route nodes and spawn markers.
- Provides stage containers for runtime scene instances. `CrewContainer`, `EnemyContainer`, `EffectsContainer`, and `LootContainer` host the Milestone 1 lab actors, feedback, and temporary coin clusters; `Interactables` retains only its clearly labelled nonfunctional placeholder.
- Does not own actor AI, combat, rewards, cards, or run progression.

The lane guides are development visualization, not lane movement logic. Route markers are visual placeholders, not a patrol implementation.

### `GameHUD`

- Presents Combat Lab elapsed time, Jax health/state/target, coin total, and manual streak while preserving the foundation regions for later systems.
- Uses a larger native-scale typography hierarchy, thicker panel/meter framing, and compact presentation labels so the fixed 640 x 360 HUD remains readable when integer-scaled to common 16:9 displays without globally scaling over the combat canvas.
- The displayed Heat, equipment/synergy, card, intervention, extraction, and route values remain non-authoritative placeholders.
- May forward future input requests through signals.
- Does not own authoritative Heat, time, inventory, card, extraction, or crew state.

### `DebugOverlay`

- Owns development-only diagnostic presentation and debug controls.
- Handles the `F1` development key to toggle its own visibility.
- Emits a typed `lane_visibility_requested(bool)` request from its lane button or `F2` shortcut.
- Does not take ownership of stage or combat state: `GameRun` forwards the request and `DowntownLoop` remains the sole owner of lane-marker visibility.
- Must be hidden or disabled for release behavior in a later production milestone.

### Actors and automatic combat

`ActorController` composes `ActorStateMachine`, `HealthComponent`, `AttackController`, an active-phase logical hitbox, and replaceable `ActorVisual` presentation. `ActorDefinition` and `AttackDefinition` Resources hold authored Jax, Street Punk, and basic-attack tuning. The actor state machine exposes the required idle, patrol, acquisition, approach, windup, active, recovery, stun, knockback, incapacitated, and dead states.

`CombatDirector` is the Milestone 1 combat authority. It owns stable actor registration, opposing-team target validity, deterministic nearest-target acquisition, attack-position reservations, damage resolution, combat-local hit-stop, synchronous dead-target invalidation, and reservation cleanup. `AttackPositionRegistry` exposes six reachable positions spanning the three authored lane centers. Actors clamp to the combat bounds and never own reward or UI state.

### `CombatLabController`

- Starts Jax and five Street Punks without direct character control.
- Uses a fixed authored lane/column sequence and no random draws.
- Replaces defeated enemies after a short fixed delay and resets the authored lab round if Jax is incapacitated.
- Requests exactly one fixed-value coin award for a rewarding defeated actor and none for an explicitly rewardless actor.
- Does not schedule encounters, advance a route, mutate escalation, or implement a full run.

### Combat and reward presentation

`CombatFeedback` observes resolved events and owns code-drawn hit sparks, damage numbers, death/spawn effects, and deterministic reusable placeholder PCM tones. It cannot change combat outcomes. `CoinCluster` is a generous `Area2D` click target under `LootContainer`; it forwards intent and presents the countdown but never credits coins itself.

## Core system shells

The original run-scoped owners remain composed under `GameRun`. `CombatDirector` and the narrow Milestone 1 portion of `RewardDirector` are implemented; `RunDirector`, `PatrolController`, `CardSystem`, and `SynergySystem` remain typed shells. No owner schedules encounters, advances route progression, mutates Heat/Night Pressure, resolves cards/equipment, or calculates synergies yet.

| Class | Path | Future authoritative ownership |
| --- | --- | --- |
| `RunDirector` | `res://scripts/run/run_director.gd` | Run state, timer, tactical Heat, irreversible Night Pressure, route progression, scheduling, safe extraction/boss thresholds, outcomes, multiplier, authoritative seed, and run-scoped random streams |
| `PatrolController` | `res://scripts/patrol/patrol_controller.gd` | Route sequence, travel, route modification, encounter pauses, rerouting |
| `CombatDirector` | `res://scripts/combat/combat_director.gd` | Active encounter, combatants, teams, coordination, completion, reward request, and deterministic spawn/enemy-variant draws |
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Reward tables, choice generation, presentation requests, selected reward application, authoritative coin ledger, at-most-once cluster resolution, manual streak bonus, and deterministic reward/equipment draws |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Draw pile, hand, discard pile, placement validation, resolution, and deterministic card draws |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Tag aggregation, thresholds, derived modifiers, activation events |

The descriptions above are complete future ownership boundaries. Only the Milestone 1 combat and coin-ledger portions described earlier are implemented.

## Deferred escalation contract

`RunDirector` will be the sole authority for two separate values:

- **Heat** is a tactical district-alert value clamped from 0 through 100. It controls immediate encounter composition, elite availability, danger, and ordinary reward quality, and may be changed by finite player-facing effects.
- **Night Pressure** is non-negative, monotonically increasing run progression. It advances through eligible active simulation time and exactly-once encounter completion, controls long-term enemy/spawn scaling and major progression, and can reset only when the run ends or restarts.

Extraction and boss thresholds belong to Night Pressure, not Heat. Once crossed, thresholds latch and cannot be reopened or cleared by cooling. `RunDirector` must queue a boss crossed at an unsafe moment and begin it at the next valid transition boundary. If an extraction threshold and the boss threshold are crossed by the same authoritative update, the boss wins unless extraction was already confirmed before that update.

Heat reduction is deliberately finite. Shop cooling requires finite stock or an explicit per-run purchase limit in addition to meaningful cost, and Subway Reroute consumes a finite charge or consumable that does not regenerate merely with time. Cards, shops, and reroutes may reduce Heat but must never reduce Night Pressure, clear a queued boss, or recreate a spent progression window. None of this escalation behavior exists in Milestone 1.

## Coin-cluster ownership

Coin clusters are optional ambient interactions implemented only for the Milestone 1 Combat Lab. `RewardDirector` owns the authoritative coin ledger, each cluster's resolution state, and the manual-collection streak. Combat requests an authored award and presentation displays a cluster, but neither may directly credit the ledger.

Manual click and the approximately 2.5-second timeout converge on one authoritative at-most-once resolution. Either path credits the full base value exactly once. Only a successful manual resolution advances the approximately 3-second streak and may add the data-driven bonus, capped at 10% of that cluster's base value; auto-collection grants no manual bonus. The presentation lives under `LootContainer`, remains non-authoritative, and is offset outside the immediate melee silhouette.

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

The `cosmetic` stream is isolated: adding cosmetic draws must not change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. `RunRandomStreams` chooses no content itself and owns no presentation. No seed or stream runtime exists in Milestone 1.

## Deferred equipment and synergy contract

The vertical slice uses three generic equipment slots and at least nine data-driven equipment definitions. Each primary synergy—Knockback, Bleed, and Tech—must have at least three valid two-item activation combinations, and the catalogue must contain at least two items that bridge different primary synergy categories. `SynergySystem` will evaluate tags and thresholds without hard-coding equipment IDs; the exact nine-item catalogue and its current combination counts are recorded in `CONTENT_CATALOG.md`. No equipment Resource or synergy calculation exists in Milestone 1.

## Dependency direction

```text
Player input
    -> GameHUD / DebugOverlay (presentation and intent)
    -> GameRun wiring (typed signal connections)
    -> run-scoped systems (authority)
    -> stage/actor presentation (results)
```

Presentation may observe authoritative state, but authoritative gameplay code must not depend on concrete HUD controls. Stage containers host actors, but the stage does not implement actor behavior.

## Autoload policy

Milestone 1 adds no Neon Loop gameplay Autoloads. The existing `_mcp_game_helper` entry belongs to the Godot AI/MCP development plugin and is not run state or shipped gameplay architecture. Future `AppState` or `SaveService` Autoloads are allowed by the specification only when their milestones require them and their reason is documented. The active run must never be managed as a singleton, and the future `RunRandomStreams` component must remain owned by its `RunDirector` rather than becoming an Autoload.

## Deferred architecture

These are intentionally absent until their owning milestones:

- Interactable behavior and intervention effects
- Encounter scheduling, tactical Heat, irreversible Night Pressure, safe latched thresholds, extraction, run outcomes, and summaries
- Authoritative run seed and the seven isolated, run-scoped deterministic random streams
- The nine equipment Resources, reward resolution, and synergy calculation/combination previews
- District card Resources, hand/deck state, drag-and-drop, and route modification
- Finite cooling purchases and reroute charges, save services, progression, shops, bosses, and procedural generation

Any change that crosses these scope boundaries should first update `IMPLEMENTATION_PLAN.md` and confirm the requested milestone.

## Foundation verification

The Godot 4.7 project-main launch resolves to runtime root `/GameRun`. A 640 x 360 capture confirms the composed stage and HUD, and the debug input path was exercised through repeated `F1` visibility changes plus `F2` lane hiding/restoration while the overlay was hidden. Game and editor logs were clean after relaunch. Evidence: `res://docs/screenshots/milestone_0_foundation.png`.

## Combat Lab verification

Milestone 1 technical verification launches the configured project directly to `/GameRun`, exercises a five-enemy automatic fight beyond 60 seconds, confirms repeated death/replacement cleanup and live-only targets/reservations, verifies all live actor positions stay within the authored lanes and battlefield bounds, exercises `F1` and `F2`, and inspects fresh game/editor logs. Deterministic combat, director, and reward suites cover damage, health, state/timing edges, reservations, target invalidation, repeated cleanup, click/timeout races, streak expiry/exclusion, rounding, and the 10% cap. Human Validation Gate ownership remains exclusively with the project owner.
