# Neon Loop Architecture

## Status

This document describes the implemented **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, **Milestone 2 — Player Intervention**, and **Milestone 3 — Complete Run Structure** architecture. It remains deliberately smaller than the complete vertical-slice architecture in `GameSpecifications.md`: Milestone 4 and later equipment, synergy, card, content, progression, persistence, and final-boss systems remain deferred.

The rationale for the revised downstream boundaries is recorded in `docs/decisions/0001-run-engagement-escalation-and-randomness.md`.

## Architectural principles

- Composition over deep inheritance
- Typed GDScript
- Narrow scene and script ownership
- Gameplay logic separated from presentation
- Explicit signals or typed calls between owners
- Data-driven gameplay content in custom Resources
- Run-scoped deterministic named random streams for gameplay draws
- Stable content ordering before random selection
- No unnecessary global state
- Inspectable development behavior

## Display foundation

The game is designed at an internal resolution of **640 x 360** with a **16:9** aspect ratio. The project uses nearest-neighbour canvas texture filtering and integer-friendly scaling so placeholder and future pixel art remain crisp at whole-number display multiples. Letterboxing is preferable to distorting the design aspect ratio.

The browser playtest uses a source-controlled Godot 4.7 Web export preset with thread support disabled, so the generated build can run on ordinary GitHub Pages without cross-origin-isolation headers. GitHub Actions creates and deploys the generated artifact; exported binaries are not committed to the gameplay source tree.

Milestone 3 retains the native 640 x 360 canvas and adaptive Web sizing. `DisplayController` owns presentation-only fullscreen requests, F11 when it reaches the game, fullscreen-only Escape handling, landscape detection, and safe-area snapshots. `GameHUD` supplies the primary visible fullscreen control and applies conservative safe-area insets to edge-critical controls. The standard Godot Web shell still prevents keyboard zoom shortcuts while its canvas is focused and mobile pinch conflicts with canvas touch ownership; fullscreen is the documented presentation-scale alternative. A future higher-resolution pixel-art pass is recommended if final typography and production sprite detail outgrow 640 x 360, but Milestone 3 does not migrate the internal resolution.

`GameRun` is the configured launch scene. The active display configuration belongs in `project.godot`; individual gameplay scenes must not independently redefine the internal viewport contract.

## Runtime composition

The intended composition root is:

```text
GameRun
|- RunDirector
|  `- RunRandomStreams
|- PatrolController
|- CombatDirector
|- RewardDirector
|- FireHydrantController
|- RunCoolingController
|- RunEncounterController
|- RunFlowController
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
- `res://scripts/run/run_director.gd`
- `res://scripts/run/run_random_streams.gd`
- `res://scripts/run/run_cooling_controller.gd`
- `res://scripts/run/run_flow_controller.gd`
- `res://scripts/patrol/patrol_controller.gd`
- `res://scripts/encounters/run_encounter_controller.gd`
- `res://scripts/stages/downtown_loop.gd`
- `res://scripts/stages/downtown_backdrop.gd`
- `res://scripts/stages/debug_lane_markers.gd`
- `res://scripts/stages/route_markers.gd`
- `res://scripts/ui/game_hud.gd`
- `res://scripts/ui/debug_overlay.gd`
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

The tree above is the implemented Milestone 3 composition. `RunRandomStreams` is instantiated as a direct child of `RunDirector`, is reset for each run, and is never an Autoload.

## Scene ownership

### `GameRun`

- Composes the run-scoped systems, encounter runtime, Fire Hydrant authority, display integration, stage, camera, HUD, debug presentation, and combat feedback.
- Keeps all run-scoped state in the scene tree rather than a run singleton.
- Connects typed run/patrol/encounter/combat/reward/intervention/display signals without calculating their owned results.
- Begins and restarts composed runs, synchronously clears run-owned actors, reservations, rewards, thresholds, timers, cooling stock, and random-stream state, and forwards presentation intent to the correct authority.

### `DowntownLoop`

- Owns the fixed placeholder nighttime street presentation.
- Owns the three lane guide visuals and their visibility operation.
- Owns replaceable route-node and spawn-marker presentation; `PatrolController` owns route progress.
- Provides stage containers for runtime scene instances. `CrewContainer`, `EnemyContainer`, `EffectsContainer`, and `LootContainer` host the Combat Lab actors, feedback, and temporary coin clusters; `Interactables` hosts the functional but presentation-only Fire Hydrant world scene.
- Does not own actor AI, combat, rewards, cards, or run progression.

The lane guides and route markers are development visualization, not movement or patrol authority.

### `GameHUD`

- Presents authoritative run state, route progress, Heat/tier, Night Pressure, timer, extraction, cooling, summary, Jax health/state/target, coin total, manual streak, Hydrant readiness/cooldown, onboarding, sound-unlock status, landscape guidance, and fullscreen state.
- Uses a larger native-scale typography hierarchy, thicker panel/meter framing, and compact presentation labels so the fixed 640 x 360 HUD remains readable when integer-scaled to common 16:9 displays without globally scaling over the combat canvas.
- Equipment/synergy and district-card regions remain honest future placeholders. Every live value is observed from its owning system.
- Forwards run actions, Hydrant activation/preview, Help, and fullscreen intent through typed signals.
- Does not own authoritative Heat, Night Pressure, time, cooling, rewards, extraction, cards, or crew state.

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

### `RunEncounterController`

- Owns encounter start/completion identity, scaled Street Punk spawns, stable lane selection, per-encounter and global concurrency caps, and transition-safe cleanup.
- Applies the `RunDirector` health, damage, and spawn-budget scales to fresh encounter actors without moving combat calculations into run state.
- Reports one typed completion notification per encounter token; `RunDirector` independently rejects duplicate or retried completion IDs.
- Requests standard reward preparation after completion and leaves authoritative accounting to `RewardDirector`.
- Uses current Street Punk presentation for all Milestone 3 encounter roles; later enemy/elite/final-boss content is deliberately absent.

### Combat and reward presentation

`CombatFeedback` observes resolved events and owns code-drawn hit sparks, damage numbers, death/spawn/water effects, and deterministic reusable placeholder PCM tones. It builds the small audio set before the run starts, registers Web sample playback up front, and exposes a one-shot gesture-unlock cue; it cannot change combat outcomes. `CoinCluster` is a generous mouse/touch `Area2D` under `LootContainer`; it forwards intent and presents a pulse, pointer, and click/tap countdown but never credits coins itself.

### Fire Hydrant intervention

`FireHydrantController` is the run-scoped Milestone 2 authority. A `FireHydrantTuning` Resource owns its 112-pixel circle, 18 damage, fixed leftward 300-force/0.30-second knockback, 8-second cooldown, and feedback timings. The controller validates live registered enemies in stable registration order, rejects no-target and cooldown requests, locks before resolving callbacks to prevent duplicate activation, applies damage/knockback through `CombatDirector`, and owns cooldown progression. It emits typed snapshots/results only.

The `FireHydrant` world scene and `GameHUD` are presentation and input surfaces. Both forward the same activation intent, and the world preview reads the exact tuning Resource used by authority. The world scene owns hover/tap bounds, highlighting, the range drawing, authored placeholder hydrant/water art, and local presentation timers. Neither can choose targets, apply damage, or consume cooldown. The environmental source ID is a clean future compatibility seam for Wet/combo continuation without implementing a status-effect or combo system in Milestone 2.

## Run-system ownership

Milestone 3 implements the complete run-structure authorities while preserving the narrower combat and intervention owners. `CardSystem` and `SynergySystem` remain typed shells because their gameplay belongs to later milestones.

| Class | Path | Authoritative ownership |
| --- | --- | --- |
| `RunDirector` | `res://scripts/run/run_director.gd` | State-transition graph, eligible run time, Heat, irreversible Night Pressure, threshold latches/precedence, outcomes, summary record, run seed, and scaling calculations |
| `RunRandomStreams` | `res://scripts/run/run_random_streams.gd` | Seven isolated deterministic stream states and stable-ID selection |
| `PatrolController` | `res://scripts/patrol/patrol_controller.gd` | Authored route sequence, segment progress, encounter pauses, safe boundaries, and finite reroute progression |
| `RunEncounterController` | `res://scripts/encounters/run_encounter_controller.gd` | Encounter lifecycle, deterministic spawn/lane selection, scaled actor creation, concurrency caps, and completion notification |
| `RunCoolingController` | `res://scripts/run/run_cooling_controller.gd` | Finite Subway charges and finite priced shop-cooling stock |
| `RunFlowController` | `res://scripts/run/run_flow_controller.gd` | Typed coordination between run, patrol, encounter, reward, cooling, and presentation intent |
| `CombatDirector` | `res://scripts/combat/combat_director.gd` | Actor combat, environmental hits, stable targeting/reservations, and complete run-owned combat cleanup |
| `FireHydrantController` | `res://scripts/interventions/fire_hydrant_controller.gd` | Hydrant target validation, area resolution, rejection, and cooldown |
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Standard reward selection/accounting, coin ledger, at-most-once clusters, and manual streak |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Deferred Milestone 5 card authority shell |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Deferred Milestone 4 synergy authority shell |

## Run lifecycle

`RunDirector` permits only explicit edges and rejects invalid or duplicate transitions. The implemented lifecycle is:

```text
INITIALIZING -> INTRO -> PATROLLING <-> ENCOUNTER_ACTIVE -> REWARD_SELECTION
                                      REWARD_SELECTION -> PATROLLING / SHOP
                                      SHOP -> PATROLLING
PATROLLING / REWARD_SELECTION -> EXTRACTION_AVAILABLE -> EXTRACTING -> RUN_SUMMARY
safe boundary with queued boss -> BOSS_INTRO -> BOSS_ACTIVE -> VICTORY -> RUN_SUMMARY
active run states -> DEFEAT -> RUN_SUMMARY
eligible active states <-> PAUSED
RUN_SUMMARY -> INITIALIZING (clean same-seed or new-seed restart)
```

The run timer and Night Pressure time gain advance only while `is_eligible_active_time()` is true. Intro, pause, reward selection, shop, extraction transition, boss intro, terminal states, and summary do not advance either value. `RunDirector` coordinates state but does not absorb patrol, encounter, combat, reward, or UI details.

## Heat and Night Pressure

`RunDirector` is the sole authority for two separate values:

- **Heat** is a tactical district-alert value clamped from 0 through 100. It controls immediate encounter composition, elite availability, danger, and ordinary reward quality, and may be changed by finite player-facing effects.
- **Night Pressure** is non-negative, monotonically increasing run progression. It advances through eligible active simulation time and exactly-once encounter completion, controls long-term enemy/spawn scaling and major progression, and can reset only when the run ends or restarts.

Extraction and boss thresholds belong to Night Pressure, not Heat. Once crossed, thresholds latch and cannot be reopened or cleared by cooling. `RunDirector` must queue a boss crossed at an unsafe moment and begin it at the next valid transition boundary. If an extraction threshold and the boss threshold are crossed by the same authoritative update, the boss wins unless extraction was already confirmed before that update.

Heat uses exact tiers 0: 0–19, 1: 20–39, 2: 40–59, 3: 60–79, 4: 80–99, and 5: 100. Its Resource controls immediate spawn additions, enemy damage, elite eligibility, reward quality, reward multiplier, and HUD presentation. Night Pressure gains 0.25 per eligible active second plus exactly-once completion gains of 6 (standard) or 10 (elite-flagged). Its Resource scales health by 1% per point, damage by 0.5% per point, and spawn budget by 1.25% per point. Spawn budgets use non-negative round-half-up: `floor(scaled_value + 0.5)`, then encounter and global caps are applied.

Extraction latches at Night Pressure 18 and 36; the boss latches at 50. A first-crossed extraction is queued until a safe route boundary and becomes spent when declined or confirmed. A boss crossed at an unsafe moment remains queued until the next valid transition boundary. If extraction and boss thresholds cross in the same authoritative update, the boss wins unless extraction was already confirmed. Cooling never mutates Night Pressure, reopens a spent window, clears a boss latch/queue, or regenerates stock.

`RunCoolingController` begins each run with two Subway charges (15 Heat each) and two shop purchases (18 Heat each at 60 coins). Zero-stock/zero-charge requests reject without mutation, and neither source regenerates merely through time.

## Coin-cluster ownership

Coin clusters are optional ambient interactions implemented only for the Milestone 1 Combat Lab. `RewardDirector` owns the authoritative coin ledger, each cluster's resolution state, and the manual-collection streak. Combat requests an authored award and presentation displays a cluster, but neither may directly credit the ledger.

Manual click and the approximately 2.5-second timeout converge on one authoritative at-most-once resolution. Either path credits the full base value exactly once. Only a successful manual resolution advances the approximately 3-second streak and may add the data-driven bonus, capped at 10% of that cluster's base value; auto-collection grants no manual bonus. The presentation lives under `LootContainer`, remains non-authoritative, and is offset outside the immediate melee silhouette.

Milestone 3 standard rewards are selected from stable-ID, quality-filtered `StandardRewardDefinition` Resources with the `rewards` stream. Coin-cluster interaction retains the Milestone 1 at-most-once/full-value/manual-streak behavior. Equipment choices remain unimplemented despite the reserved `equipment` stream; presentation-only draws consume `cosmetic` so visual activity cannot alter reward outcomes.

## Deterministic run randomness

Every run has one authoritative signed integer seed owned by `RunDirector`. A supplied seed is accepted before the first draw; otherwise a recorded seed is generated from non-gameplay time only once at run start. Its run-scoped `RunRandomStreams` child derives stable, versioned sub-seeds and maintains one deterministic generator for each required `StringName` stream:

- `encounters`
- `spawns`
- `rewards`
- `equipment`
- `cards`
- `enemy_variants`
- `cosmetic`

Random schema version **1** uses algorithm ID `fnv1a32_utf8_v1`: FNV-1a 32-bit over the UTF-8 bytes of `neon-loop|schema:<version>|seed:<integer>|stream:<name>`, with unsigned 32-bit wrap after every multiply. Locked known vectors cover every stream. Gameplay owners receive only their declared stream and do not use global unseeded random calls. Candidates are filtered, empty/duplicate IDs are rejected, and remaining stable content IDs are sorted before drawing; scene-tree insertion order, dictionary iteration order, Resource order, and presentation order are not selection contracts.

The `cosmetic` stream is isolated: adding cosmetic draws cannot change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. Same-seed restart resets every generator to its derived initial state. Reproduction claims are limited to the same supported build, content revision, random schema, seed, ordered player decisions, and authoritative timing context; physics or cross-version bitwise replay is not promised.

## Deferred equipment and synergy contract

The vertical slice uses three generic equipment slots and at least nine data-driven equipment definitions. Each primary synergy—Knockback, Bleed, and Tech—must have at least three valid two-item activation combinations, and the catalogue must contain at least two items that bridge different primary synergy categories. `SynergySystem` will evaluate tags and thresholds without hard-coding equipment IDs; the exact nine-item catalogue and its current combination counts are recorded in `CONTENT_CATALOG.md`. No equipment Resource or synergy calculation exists through Milestone 3.

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

Milestone 3 adds no Neon Loop gameplay Autoloads. The existing `_mcp_game_helper` entry belongs to the Godot AI/MCP development plugin and is not run state or shipped gameplay architecture. Future `AppState` or `SaveService` Autoloads are allowed by the specification only when their milestones require them and their reason is documented. The active run is never managed as a singleton, and `RunRandomStreams` remains owned by its `RunDirector`.

## Deferred architecture

These are intentionally absent until their owning milestones:

- Call Backup, complete Wet/status effects, and combo-meter behavior
- The nine equipment Resources and synergy calculation/combination previews
- District card Resources, hand/deck state, drag-and-drop, and route modification
- Production shop content, save services, progression, final-boss actor/content, and procedural generation

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

## Complete Run Structure verification

Milestone 3 technical verification is complete. Seven discoverable suites passed **75/75 tests and 1,100 assertions with no failures or skips**. This preserves all **46/46 Milestone 1–2 tests and 694 assertions** and adds 29 Milestone 3 tests with 406 assertions covering the full state graph, rejection paths, Heat tiers/effects, irreversible eligible-time pressure, exactly-once completions, data-driven scaling/rounding/caps, threshold latching/precedence/queueing, finite cooling, seeds, known derivation vectors, stable ordering, stream isolation, rewards, terminal results, summaries, and clean restarts.

Godot 4.7 launched the configured `/GameRun` composition without parser/runtime warnings or errors. Accelerated representative runs reached extracted, defeated, and boss-triggered summaries; threshold crossings were exercised both separately and together; finite Subway/shop cooling exhausted without changing Night Pressure; modal, introduction, and paused time were ineligible; same-seed replay matched encounter and spawn choices despite extra cosmetic draws; and composed restart cleared actors, reservations, loot, timers, thresholds, cooling stock, and stream draw state. Existing Hydrant, coins, Help, fullscreen, `F1`, and `F2` paths remained usable during the lifecycle.

Local Windows and Web exports completed successfully. The Windows executable passed headless and hidden-window startup smoke checks. The locally served Web build rendered the live Milestone 3 HUD, unlocked audio from one gesture, toggled Help, entered/exited fullscreen, and reported no browser-console warnings or errors. Evidence is stored at `res://docs/screenshots/milestone_3_complete_run_structure.png`. No GitHub Pages publication or deployment was performed.

The Milestone 3 boss scope ends at deterministic latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE` transition behavior. Final-boss actor/content and a production victory encounter remain later content work. Equipment, synergies, district cards, general shops, saving/progression, and all other Milestone 4+ behavior remain deliberately unimplemented.
