# Neon Loop Architecture

## Status

This document describes the implemented **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, and **Milestone 2 — Player Intervention** architecture. It remains deliberately smaller than the complete vertical-slice architecture in `GameSpecifications.md`. Milestone 3 and later systems are named only to preserve ownership boundaries; their gameplay behavior is not implemented.

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

Milestone 2 retains the native 640 x 360 canvas and adaptive Web sizing. `DisplayController` owns presentation-only fullscreen requests, F11 when it reaches the game, fullscreen-only Escape handling, landscape detection, and safe-area snapshots. `GameHUD` supplies the primary visible fullscreen control and applies conservative safe-area insets to edge-critical controls. The standard Godot Web shell still prevents keyboard zoom shortcuts while its canvas is focused and mobile pinch conflicts with canvas touch ownership; fullscreen is the documented presentation-scale alternative. A future higher-resolution pixel-art pass is recommended if final typography and production sprite detail outgrow 640 x 360, but Milestone 2 does not migrate the internal resolution.

`GameRun` is the configured launch scene. The active display configuration belongs in `project.godot`; individual gameplay scenes must not independently redefine the internal viewport contract.

## Runtime composition

The intended composition root is:

```text
GameRun
|- RunDirector
|- PatrolController
|- CombatDirector
|- RewardDirector
|- FireHydrantController
|- CombatLabController
|- CardSystem
|- SynergySystem
|- DisplayController
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
- `res://scenes/interactables/fire_hydrant.tscn`

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
- `res://scripts/interactables/fire_hydrant.gd`
- `res://scripts/interventions/fire_hydrant_controller.gd`
- `res://scripts/ui/display_controller.gd`

`res://scripts/stages/` is an intentional, narrow addition to the recommended
directory list: it owns only the fixed stage's replaceable presentation and
debug-marker drawing.

`GameRun` owns assembly only. It is the place to connect explicit cross-owner signals when later milestones require them; it must not grow into a second implementation of each child system.

The tree above is the implemented Milestone 2 composition. The revised specification also requires this later run-scoped relationship:

```text
RunDirector
`- RunRandomStreams
```

`RunRandomStreams` is not instantiated or implemented in Milestone 2. When Milestone 3 introduces it, it is a child component owned by `RunDirector`, lives only for that run, and is not an Autoload.

## Scene ownership

### `GameRun`

- Composes the run-scoped systems, Combat Lab, Fire Hydrant authority, display integration, stage, camera, HUD, debug presentation, and combat feedback.
- Keeps all run-scoped state in the scene tree rather than a run singleton.
- Connects typed combat/reward/intervention/display signals to presentation without calculating damage, rewards, cooldowns, target validity, or actor decisions.
- Contains no encounter scheduling, patrol progression, Heat/Night Pressure behavior, or later run loop.

### `DowntownLoop`

- Owns the fixed placeholder nighttime street presentation.
- Owns the three lane guide visuals and their visibility operation.
- Owns placeholder route nodes and spawn markers.
- Provides stage containers for runtime scene instances. `CrewContainer`, `EnemyContainer`, `EffectsContainer`, and `LootContainer` host the Combat Lab actors, feedback, and temporary coin clusters; `Interactables` hosts the functional but presentation-only Fire Hydrant world scene.
- Does not own actor AI, combat, rewards, cards, or run progression.

The lane guides are development visualization, not lane movement logic. Route markers are visual placeholders, not a patrol implementation.

### `GameHUD`

- Presents Combat Lab elapsed time, Jax health/state/target, coin total, manual streak, authoritative Hydrant readiness/cooldown, onboarding, sound-unlock status, landscape guidance, and fullscreen state while preserving the foundation regions for later systems.
- Uses a larger native-scale typography hierarchy, thicker panel/meter framing, and compact presentation labels so the fixed 640 x 360 HUD remains readable when integer-scaled to common 16:9 displays without globally scaling over the combat canvas.
- The displayed Heat, equipment/synergy, card, extraction, and route values remain non-authoritative placeholders. The Fire Hydrant panel is live but remains non-authoritative.
- Forwards Hydrant activation/preview and fullscreen intent through typed signals.
- Does not own authoritative Heat, time, inventory, card, extraction, or crew state.

### `DebugOverlay`

- Owns development-only diagnostic presentation and debug controls.
- Handles the `F1` development key to toggle its own visibility.
- Emits a typed `lane_visibility_requested(bool)` request from its lane button or `F2` shortcut.
- Does not take ownership of stage or combat state: `GameRun` forwards the request and `DowntownLoop` remains the sole owner of lane-marker visibility.
- Must be hidden or disabled for release behavior in a later production milestone.

### Actors and automatic combat

`ActorController` composes `ActorStateMachine`, `HealthComponent`, `AttackController`, an active-phase logical hitbox, and replaceable `ActorVisual` presentation. `ActorDefinition` and `AttackDefinition` Resources hold authored Jax, Street Punk, and basic-attack tuning. The actor state machine exposes the required idle, patrol, acquisition, approach, windup, active, recovery, stun, knockback, incapacitated, and dead states.

`CombatDirector` remains the combat authority. It owns stable actor registration, opposing-team target validity, deterministic nearest-target acquisition, attack-position reservations, damage resolution, combat-local hit-stop, synchronous dead-target invalidation, and reservation cleanup. Milestone 2 adds stable live-enemy circle queries and a typed environmental-hit seam used by the Hydrant; it reuses ordinary health and knockback contracts rather than bypassing actors. `AttackPositionRegistry` exposes six reachable positions spanning the three authored lane centers. Actors never own reward, intervention, or UI state.

### Combat-safe space

`CombatSpaceDefinition` is the one authored Downtown Loop combat-space contract. Its inclusive actor-origin rectangle is X 164 through 456 and Y 194 through 258, with lane centers at Y 194, 226, and 258. `CombatDirector` passes the same typed Resource to actors and reservations; the Combat Lab uses it for spawns and coin placement; actors use it for approach, knockback, and recovery clamping; and debug lane markers render it. The right edge accounts for the active actor silhouette plus the maximum conservative mobile safe-area inset. This removes the duplicated wider bounds that allowed long fights and replacement spawns to creep under HUD panels while preserving visible displacement within the safe space.

### `CombatLabController`

- Starts Jax and five Street Punks without direct character control.
- Uses a fixed authored lane/column sequence and no random draws.
- Replaces defeated enemies after a short fixed delay and resets the authored lab round if Jax is incapacitated.
- Requests exactly one fixed-value coin award for a rewarding defeated actor and none for an explicitly rewardless actor.
- Places generous coin targets outside the authored Hydrant interaction exclusion so coin and intervention input cannot compete.
- Does not schedule encounters, advance a route, mutate escalation, or implement a full run.

### Combat and reward presentation

`CombatFeedback` observes resolved events and owns code-drawn hit sparks, damage numbers, death/spawn/water effects, and deterministic reusable placeholder PCM tones. It builds the small audio set before the run starts, registers Web sample playback up front, and exposes a one-shot gesture-unlock cue; it cannot change combat outcomes. `CoinCluster` is a generous mouse/touch `Area2D` under `LootContainer`; it forwards intent and presents a pulse, pointer, and click/tap countdown but never credits coins itself.

### Fire Hydrant intervention

`FireHydrantController` is the run-scoped Milestone 2 authority. A `FireHydrantTuning` Resource owns its 112-pixel circle, 18 damage, fixed leftward 300-force/0.30-second knockback, 8-second cooldown, and feedback timings. The controller validates live registered enemies in stable registration order, rejects no-target and cooldown requests, locks before resolving callbacks to prevent duplicate activation, applies damage/knockback through `CombatDirector`, and owns cooldown progression. It emits typed snapshots/results only.

The `FireHydrant` world scene and `GameHUD` are presentation and input surfaces. Both forward the same activation intent, and the world preview reads the exact tuning Resource used by authority. The world scene owns hover/tap bounds, highlighting, the range drawing, authored placeholder hydrant/water art, and local presentation timers. Neither can choose targets, apply damage, or consume cooldown. The environmental source ID is a clean future compatibility seam for Wet/combo continuation without implementing a status-effect or combo system in Milestone 2.

## Core system shells

The original run-scoped owners remain composed under `GameRun`. `CombatDirector`, `FireHydrantController`, `CombatLabController`, and the narrow coin-ledger portion of `RewardDirector` are implemented; `RunDirector`, `PatrolController`, `CardSystem`, and `SynergySystem` remain typed shells. No owner schedules encounters, advances route progression, mutates Heat/Night Pressure, resolves cards/equipment, or calculates synergies yet.

| Class | Path | Future authoritative ownership |
| --- | --- | --- |
| `RunDirector` | `res://scripts/run/run_director.gd` | Run state, timer, tactical Heat, irreversible Night Pressure, route progression, scheduling, safe extraction/boss thresholds, outcomes, multiplier, authoritative seed, and run-scoped random streams |
| `PatrolController` | `res://scripts/patrol/patrol_controller.gd` | Route sequence, travel, route modification, encounter pauses, rerouting |
| `CombatDirector` | `res://scripts/combat/combat_director.gd` | Implemented actor combat and environmental-hit authority; future encounter completion, reward request, and deterministic spawn/enemy-variant draws |
| `FireHydrantController` | `res://scripts/interventions/fire_hydrant_controller.gd` | Implemented Hydrant target validation, area resolution, damage/knockback request, rejection, and cooldown |
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Reward tables, choice generation, presentation requests, selected reward application, authoritative coin ledger, at-most-once cluster resolution, manual streak bonus, and deterministic reward/equipment draws |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Draw pile, hand, discard pile, placement validation, resolution, and deterministic card draws |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Tag aggregation, thresholds, derived modifiers, activation events |

The descriptions above are complete future ownership boundaries. Only the Milestone 1 combat/coin-ledger and Milestone 2 Fire Hydrant/display portions described earlier are implemented.

## Deferred escalation contract

`RunDirector` will be the sole authority for two separate values:

- **Heat** is a tactical district-alert value clamped from 0 through 100. It controls immediate encounter composition, elite availability, danger, and ordinary reward quality, and may be changed by finite player-facing effects.
- **Night Pressure** is non-negative, monotonically increasing run progression. It advances through eligible active simulation time and exactly-once encounter completion, controls long-term enemy/spawn scaling and major progression, and can reset only when the run ends or restarts.

Extraction and boss thresholds belong to Night Pressure, not Heat. Once crossed, thresholds latch and cannot be reopened or cleared by cooling. `RunDirector` must queue a boss crossed at an unsafe moment and begin it at the next valid transition boundary. If an extraction threshold and the boss threshold are crossed by the same authoritative update, the boss wins unless extraction was already confirmed before that update.

Heat reduction is deliberately finite. Shop cooling requires finite stock or an explicit per-run purchase limit in addition to meaningful cost, and Subway Reroute consumes a finite charge or consumable that does not regenerate merely with time. Cards, shops, and reroutes may reduce Heat but must never reduce Night Pressure, clear a queued boss, or recreate a spent progression window. None of this escalation behavior exists in Milestone 2.

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

The `cosmetic` stream is isolated: adding cosmetic draws must not change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. `RunRandomStreams` chooses no content itself and owns no presentation. No seed or stream runtime exists in Milestone 2.

## Deferred equipment and synergy contract

The vertical slice uses three generic equipment slots and at least nine data-driven equipment definitions. Each primary synergy—Knockback, Bleed, and Tech—must have at least three valid two-item activation combinations, and the catalogue must contain at least two items that bridge different primary synergy categories. `SynergySystem` will evaluate tags and thresholds without hard-coding equipment IDs; the exact nine-item catalogue and its current combination counts are recorded in `CONTENT_CATALOG.md`. No equipment Resource or synergy calculation exists in Milestone 2.

## Dependency direction

```text
Player input
    -> GameHUD / FireHydrant / DebugOverlay (presentation and intent)
    -> GameRun wiring (typed signal connections)
    -> run-scoped systems (authority)
    -> stage/actor presentation (results)
```

Presentation may observe authoritative state, but authoritative gameplay code must not depend on concrete HUD controls. Stage containers host actors, but the stage does not implement actor behavior.

## Autoload policy

Milestone 2 adds no Neon Loop gameplay Autoloads. The existing `_mcp_game_helper` entry belongs to the Godot AI/MCP development plugin and is not run state or shipped gameplay architecture. Future `AppState` or `SaveService` Autoloads are allowed by the specification only when their milestones require them and their reason is documented. The active run must never be managed as a singleton, and the future `RunRandomStreams` component must remain owned by its `RunDirector` rather than becoming an Autoload.

## Deferred architecture

These are intentionally absent until their owning milestones:

- Call Backup, Subway Reroute, complete Wet/status effects, and combo-meter behavior
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

## Player Intervention verification

Milestone 2 technical verification is complete. The five discoverable suites passed **46/46 tests and 694 assertions with no failures**: the preserved Milestone 1 result is 30 tests/348 assertions and the Milestone 2 combat-space/intervention result is 16 tests/346 assertions. Coverage verifies the Hydrant's typed tuning, inclusive authoritative circle, deterministic damage, strong fixed-direction knockback, dead/invalid exclusion, no-target and cooldown rejection, same-tick deduplication, cooldown completion/reactivation, shared preview radius, HUD state mapping, combat-safe movement/reservations/knockback, repeated replacement cleanup, and unchanged coin at-most-once accounting.

The uninterrupted runtime soak reached **315.3046 seconds** with 113 enemies spawned, 98 defeated, five active enemies, six live actors, and six live reservations. All actor origins remained inside X 164–456 and Y 194–258 on lanes Y 194/226/258. The coin ledger ended at 3,920, exactly 98 rewarding defeats multiplied by the authored 40-coin base, with no duplicate or lost timeout accounting. Repeated replacement spawning and Jax round recovery did not drift combat beneath the left HUD.

Godot 4.7 editor and local Windows/Web export checks launched directly into `/GameRun`, exercised Hydrant, coin, Help, visible fullscreen, Escape, `F1`, and `F2` paths, and inspected fresh logs without task-introduced parser errors, runtime errors, warnings, or browser-console messages. The small generated Combat Lab sound set is constructed before play; Web cold and warm loads show one immediate sound-unlock affordance, and one ordinary gesture enables sound without pausing or resetting combat. Repeated visible-control fullscreen entry/exit and Escape were stable. The in-app browser retained F11 rather than delivering it to the canvas; the game handles F11 when delivered and otherwise leaves the browser's normal F11 path intact. Representative mobile-landscape presentation retained 16:9 letterboxing and safe insets, while portrait showed the landscape recommendation.

The standard generated Godot Web shell continued to block ordinary browser zoom while the canvas had focus. Fullscreen is therefore the useful presentation-scale alternative for this milestone; a custom accessible shell remains future presentation work. Visual evidence is stored at `res://docs/screenshots/milestone_2_player_intervention.png`. No Milestone 2 build was published or deployed. The owner-recorded Milestone 1 Human Validation Gate remains an owner qualitative result distinct from every technical check above.
