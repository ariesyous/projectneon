# Neon Loop Architecture

## Status

This document describes the implemented **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, **Milestone 2 — Player Intervention**, **Milestone 3 — Complete Run Structure**, **Milestone 4 — Equipment and Synergies**, **Milestone 4.1 equipment usability/readability correction**, and the bounded **Milestone 4.2 inventory drag/backpack-clarity correction**. It remains deliberately smaller than the complete vertical-slice architecture in `GameSpecifications.md`: Milestone 5 and later cards, content, progression, persistence, final-boss systems, rarity/unique/set itemization, and a broader equipment economy remain deferred.

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

The current presentation viewport is a true **1280 x 720** at **16:9**. The established stage, combat space, actors, effects, and authored positions remain in the same logical **640 x 360** world coordinates: `GameRun` centers `Camera2D` at `(320, 180)` with `Vector2(2, 2)` zoom. This preserves every Milestone 0–4 world-space acceptance decision while allowing `GameHUD` and `DebugOverlay` to render natively at 1280 x 720 rather than rasterizing tiny text into a 640 x 360 canvas and enlarging the blur.

The project preserves viewport stretch mode, 16:9 aspect, integer scale mode, nearest-neighbour canvas texture filtering, the explicit default mipmap-filter setting, and 2D pixel snapping. Letterboxing is preferable to distortion. HUD labels and buttons use at least 16-pixel text at the native viewport, ordinary controls generally use 18 pixels where space permits, and headings/primary values use a larger hierarchy.

The browser playtest uses a source-controlled Godot 4.7 Web export preset with thread support disabled, so the generated build can run on ordinary GitHub Pages without cross-origin-isolation headers. GitHub Actions creates and deploys the generated artifact; exported binaries are not committed to the gameplay source tree.

`DisplayController` continues to own presentation-only fullscreen requests, F11 when it reaches the game, fullscreen-only Escape handling, landscape detection, and safe-area snapshots. `GameHUD` supplies the primary visible fullscreen control and applies conservative safe-area insets to edge-critical controls. The standard Godot Web shell's focused-canvas zoom behavior remains an export-shell limitation, but the native presentation now supplies readable text before any fullscreen scaling. The older 640 x 360 verification statements later in this document remain historical records of the builds that were actually accepted at those milestones; Milestone 4.1 supersedes only the current presentation configuration.

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
- `res://scripts/ui/equipment_drag_payload.gd`
- `res://scripts/ui/equipment_drag_slot.gd`
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

The tree above remains the implemented Milestone 4.2 composition. M4.2 adds typed presentation helpers under existing `GameHUD` controls and no new runtime authority node. `RunRandomStreams` is instantiated as a direct child of `RunDirector`, is reset for each run, and is never an Autoload.

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

- Presents authoritative run state, route progress, Heat/tier, Night Pressure, timer, extraction, cooling, summary, Jax health/state/target, coin total, manual streak, Hydrant readiness/cooldown, active equipment, ordered backpack storage, tag counts, synergy thresholds/effects, reward previews, onboarding, sound-unlock status, landscape guidance, and fullscreen state.
- Uses native 1280 x 720 typography and panel geometry, with a 16-pixel minimum for labels/buttons, so glyphs are rendered clearly rather than enlarged from the logical 640 x 360 world canvas.
- Presents the existing run lifecycle as a persistent `HIDEOUT → PATROL → FIGHT → GEAR → EXIT/BOSS` journey strip with current stage/next objective and an expanded opening Help panel. This is orientation only; it adds no card, route-authority, or later content system.
- The equipment/synergy region is live; the district-card region remains an honest future placeholder. Every live value is observed from its owning system.
- Names one backpack containing three ordered inactive slots beside the unchanged three generic active slots; it does not imply multiple bags, loadouts, or item categories.
- Ordinary equipment clicks inspect, while typed `EquipmentDragSlot` controls provide built-in `Control` drag/drop for owned items and reward choices. A valid drop stages the same destination/action state as the click/tap/keyboard fallback and never mutates inventory at drop time.
- Keeps dynamic reward targets compact as `ACTIVE n` / `BACKPACK [n]`, uses compact inventory targets `ACTIVE` / `STORE SLOT` / `SWAP SLOT`, bounds key inventory consequence prompts to two lines, states `CLICKS ONLY INSPECT; NEVER DISCARD` in Help, and uses ASCII action wording so the same glyphs render in desktop and Web builds. Longest-catalogue-name pixel-fit tests protect all six reward destinations, all six inventory action-target states, and key two-line prompts, not only static scene bounds.
- Reward selection, destination selection, inventory actions, and named confirmations are presentation state; the HUD forwards typed player intent with the inspected inventory revision and never mutates ownership itself.
- Forwards run actions, equipment acquisition/management intent, Hydrant activation/preview, Help, and fullscreen intent through typed signals.
- Does not own authoritative Heat, Night Pressure, time, cooling, rewards, equipment, synergies, extraction, cards, or crew state.

### `DebugOverlay`

- Owns development-only diagnostic presentation and debug controls.
- Handles the `F1` development key to toggle its own visibility.
- Emits a typed `lane_visibility_requested(bool)` request from its lane button or `F2` shortcut.
- Does not take ownership of stage or combat state: `GameRun` forwards the request and `DowntownLoop` remains the sole owner of lane-marker visibility.
- Must be hidden or disabled for release behavior in a later production milestone.

### Actors and automatic combat

`ActorController` composes `ActorStateMachine`, `HealthComponent`, `AttackController`, `StatusController`, an active-phase logical hitbox, and replaceable `ActorVisual` presentation. `ActorDefinition` and `AttackDefinition` Resources hold authored Jax, Street Punk, and basic-attack tuning. The actor state machine exposes the required idle, patrol, acquisition, approach, windup, active, recovery, stun, knockback, incapacitated, and dead states. `StatusController` owns deterministic Bleed/Shock duration, stacking, tick application, snapshots, and cleanup; `ActorVisual` only renders their marks.

`CombatDirector` remains the combat authority. It owns stable actor registration, opposing-team target validity, deterministic nearest-target acquisition, attack-position reservations, damage resolution, combat-local hit-stop, synchronous dead-target invalidation, reservation cleanup, and application of aggregated equipment modifiers and triggered effects. It resolves heavy-hit, bleeding/shocked-target, knockback, follow-up, and environmental modifiers through shared modifier/effect interfaces rather than equipment-ID branches. Milestone 2's stable live-enemy circle query and typed environmental-hit seam remain in use by the Hydrant. `AttackPositionRegistry` exposes six reachable positions spanning the three authored lane centers. Actors never own reward, equipment, intervention, or UI state.

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

Milestone 4 adds equipment/synergy authority while preserving the complete Milestone 3 run owners. `CardSystem` remains the only deferred gameplay shell.

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
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Standard reward selection/accounting, deterministic equipment choice generation/application coordination, coin ledger, at-most-once clusters, and manual streak |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Deferred Milestone 5 card authority shell |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Three active equipment slots, three ordered backpack slots, unique ownership, stable active-only aggregation, revisioned inventory transactions, threshold evaluation, previews, and activation/deactivation signaling |

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

Milestone 3 standard rewards remain selected from stable-ID, quality-filtered `StandardRewardDefinition` Resources with the `rewards` stream. Milestone 4 pairs eligible standard rewards with three equipment candidates generated only from the `equipment` stream. `RewardDirector` filters invalid, duplicate, and already-owned definitions across active and backpack positions, sorts stable equipment IDs, draws without replacement, and accepts one pending token exactly once. Milestone 4.1 separates non-mutating choice/destination review from application: confirmed equip/store or **Keep Current Build** resolves the paired standard reward exactly once. Coin-cluster interaction retains the Milestone 1 at-most-once/full-value/manual-streak behavior; presentation-only draws consume `cosmetic` so visual activity cannot alter reward or equipment outcomes.

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

The `cosmetic` stream is isolated: adding cosmetic draws cannot change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. Same-seed restart resets every generator to its derived initial state. Equipment proc chances and equipment reward choices intentionally share the single specification-owned `equipment` stream, so reproducing later choices also requires the same ordered equipment effects and authoritative combat timing. Reproduction claims are limited to the same supported build, content revision, random schema, seed, ordered player decisions/effect resolutions, and authoritative timing context; physics or cross-version bitwise replay is not promised. Random schema version 1 is unchanged: Milestone 4.1 generalizes candidate filtering from equipped IDs to all player-owned IDs, so pre-backpack states produce the same ordered candidates and backpack contents are ordinary player-decision state; stream derivation, stable sorting, and draw-without-replacement semantics do not change.

## Equipment, statuses, and synergy ownership

`EquipmentDefinition`, `EquipmentModifierDefinition`, `TriggeredEffectDefinition`, and `StatusEffectDefinition` are typed Resources. `EquipmentCatalogue` validates and returns the nine definitions in stable content-ID order. Tunable values live in `.tres` content; UI and combat do not own item tuning. `EquipmentDefinition.icon` and `SynergyDefinition.badge` are presentation references used by the HUD; the nine generated item icons and three synergy badges are deliberately replaceable placeholders and do not participate in gameplay validation, aggregation, or deterministic selection. `SynergyDefinition` and `SynergyCatalogue` define tag thresholds and derived modifiers without item-specific checks.

`SynergySystem` owns exactly three generic ordered active slots plus exactly three ordered backpack slots. Only active slots feed build aggregation; stored items remain owned but add no tags, modifiers, triggered effects, new triggered status applications, or synergy progress. A status already applied to an actor remains actor-owned and expires normally after later inventory changes. Duplicate stable-ID ownership is rejected across all six positions. Reward acquisition can store directly or equip into a chosen slot; when an active item is displaced it moves to the first empty backpack position or the exact player-selected position. If all six positions are occupied, mutation requires an explicit confirmation for the exact stored item left behind. No oldest-item policy or silent eviction exists.

M4.2 makes the one-backpack model explicit in presentation without changing this authority. `EquipmentDragPayload` is a typed, non-authoritative value carrying its inventory/reward origin, stable equipment ID, source or choice position, inventory revision, encounter identity where applicable, display name, and presentation icon. `EquipmentDragSlot` is a typed `Button` specialization using Godot's built-in `Control._get_drag_data()`, `_can_drop_data()`, `_drop_data()`, and off-tree drag-preview APIs. When a Web or touch motion path does not enter `_get_drag_data()`, typed mouse/touch input arms at press and crosses an 8-pixel threshold before calling Godot `force_drag()` with the same payload and preview. Touch arming retains the first pointer index, so a second touch cannot steal or start that drag. This is only an input-compatibility route into the same native drag transaction: it emits no inventory authority request and cannot bypass staging or Confirm. Target acceptance is a pure presentation check; authoritative validation still occurs when the staged request is confirmed.

Owned-item dragging is deliberately cross-area and non-destructive. Active-to-empty-backpack stages a move, while any occupied active/backpack cross-area drop stages an atomic swap so both items stay owned. Same-area drops are not reorder operations and reject without mutation. Reward-to-active or reward-to-backpack dragging stages the existing exact choice/destination/leave-behind flow; it does not bypass the revisioned reward token or Confirm action. Stale revisions, wrong identities, invalid origin/target combinations, combat-locked management, and drops outside a valid target all reject or snap back without changing ownership. Destructive removal remains available only through the separate named discard confirmation. Click/tap/keyboard destination selection remains the accessibility and non-drag fallback.

Between encounters, revisioned atomic operations move an active item to storage, swap a stored item with an active item, or discard the exact named active/stored item after confirmation. Inspection remains available during combat, but management mutation is allowed only in `INTRO`, `PATROLLING`, `SHOP`, and `EXTRACTION_AVAILABLE`. Every transaction validates the snapshot revision, identities, destination, replacement confirmation, catalogue membership, and unique ownership; stale or incomplete requests reject without side effects. Successful active-slot changes synchronously rebuild tags, modifiers, triggered effects, and thresholds and emit only real activation/deactivation edges. Backpack-only changes publish inventory state without altering the build. Restart clears all six positions, derived state, and old confirmation revisions.

Tag counts are accumulated in stable slot/content order. Modifiers are aggregated by stable modifier ID and operation; triggered effects are sorted by stable effect ID. Synergy thresholds are evaluated from data, so additional 2/4/6 definitions require content rather than equipment-ID branches. Knockback 2, Bleed 2, and Tech 2 are the only authored Milestone 4 thresholds. Their exact catalogue, tuning, and combination counts are recorded in `CONTENT_CATALOG.md`.

Choice previews clone the three active slots into a non-mutating candidate evaluation. They report current and prospective counts, immediate activations, deactivations caused by active-slot replacement, and progress toward every inactive primary threshold. The reward modal separately names the active destination, outgoing active item, backpack destination, and any exact stored item that would be left behind. The same aggregation/evaluation path powers previews and authoritative active changes. `GameHUD` forwards the chosen equipment index, destination positions, replacement confirmation, and inventory revision; it never equips directly. **Keep Current Build** clears the pending equipment choice while still granting the paired standard reward.

Bleed is an actor-owned stackable status: base maximum three stacks, four-second duration, one-second ticks, and two damage per stack per tick. Bleed 2 adds two maximum stacks and +20% crew damage against bleeding enemies; Serrated Wraps independently adds one maximum stack and +15% such damage. Shock is a non-damaging actor-owned status with one stack and a three-second base duration. Shock Gloves apply it at 25%; Hacker Deck and Tech 2 each add 1.5 seconds. Status timers and effects clear on actor/run cleanup.

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

Milestone 4 and its 4.1/4.2 corrections add no Neon Loop gameplay Autoloads. The existing `_mcp_game_helper` entry belongs to the Godot AI/MCP development plugin and is not run state or shipped gameplay architecture. Future `AppState` or `SaveService` Autoloads are allowed by the specification only when their milestones require them and their reason is documented. The active run is never managed as a singleton, and `RunRandomStreams` remains owned by its `RunDirector`.

## Deferred architecture

These are intentionally absent until their owning milestones:

- Call Backup, Wet, combo-meter behavior, and statuses beyond the Milestone 4 Bleed/Shock subset
- District card Resources, hand/deck state, drag-and-drop, and route modification
- Production shop content, save services, progression, final-boss actor/content, and procedural generation
- Equipment selling, salvage, buyback, auto-sell/auto-salvage rules, and a broader equipment-shop economy
- Equipment rarity tiers, uniques, affixes, set items/set bonuses, and category-locked equipment slots

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

The Milestone 3 boss scope ends at deterministic latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE` transition behavior. Final-boss actor/content and a production victory encounter remain later content work. District cards, general shops, saving/progression, and all other Milestone 5+ behavior remain deliberately unimplemented.

## Equipment and Synergies verification

Milestone 4 technical verification is complete. Nine discoverable suites passed **106/106 tests and 1,306 assertions with no failures or skips**. This preserves all **75/75 Milestone 1–3 tests and 1,100 assertions** and adds 31 Milestone 4 tests with 206 assertions covering the nine-definition catalogue, Resource validation, three slots, rejection/replacement/removal, stable aggregation, immediate threshold evaluation/signals, every two-item matrix, bridge behavior, deterministic choices/stream isolation, previews, exactly-once selection, UI bounds/input, combat modifiers/statuses, and restart cleanup.

Godot 4.7 launched the configured `/GameRun` composition without task-introduced parser/runtime warnings or errors. Normal reward clicks acquired, replaced, and removed equipment. Live Knockback, Bleed, and Tech builds changed displacement/environmental damage, status stacks/conditional damage, and Shock/intervention timing respectively. Equipment changes did not mutate Heat or Night Pressure; Tech cooldown scaling retained finite cooling/intervention rules. Extraction, defeat, and boss-threshold flows remained valid with equipment active, and same-seed restart cleared slots, tags, modifiers, statuses, pending reward state, and all named-stream draw counts.

Fresh local release Windows and Web exports completed successfully. The Windows executable passed a headless startup smoke check. The locally served Web build rendered the 640 x 360 equipment UI, accepted one sound-unlock gesture, and applied an equipment reward with one ordinary click/tap path; the browser console contained no warnings or errors. Evidence is stored at `res://docs/screenshots/milestone_4_equipment_synergies.png`. Embedded-runner fullscreen could only report Godot's informational “Windowed mode” limitation; the existing exported/browser fullscreen controls and delivery paths remain unchanged. No GitHub Pages publication or deployment was performed.

## Milestone 4.1 usability/readability correction verification

Milestone 4.1 technical verification is complete. Eleven discoverable suites passed **132/132 tests and 1,584 assertions with no failures or skips**. This preserves all **75/75 Milestone 1–3 tests and 1,100 assertions**, retains the 31 Milestone 4 tests, and adds 26 correction-specific tests with 249 assertions for finite storage, active-only aggregation, safe revisioned transactions, exactly-once reward resolution, inspection-only clicks, modal layering, native-resolution typography/containment, journey guidance, and all twelve placeholder visuals.

Godot 4.7 launched the configured main scene directly into `/GameRun` at a native 1280 x 720 presentation viewport with the established logical world framing. Real pointer input selected a reward without mutation, selected a destination, applied exactly once only after Confirm, opened inventory inspection without mutation, and staged/cancelled a named discard without losing the item. Help, Hydrant rejection, sound unlock, fullscreen, and the preserved `F1`/`F2` handlers were checked; fresh cursor-bounded editor/game logs contained no task-introduced warnings or errors. Updated evidence is stored at `res://docs/screenshots/milestone_4_1_inventory_readability.png`.

Fresh local release Windows and Web exports succeeded. Windows passed a 180-frame headless startup smoke. The locally served Web build rendered the sharp 1280 x 720 UI, unlocked sound, completed the one-confirm equipment flow, preserved an item through discard cancellation, exercised Help/fullscreen/Hydrant input, and reported no browser-console warnings or errors. The portable headless export editor printed an ObjectDB-profiler `user://` directory message after successful export; it did not occur in the exported Windows runtime or Web console. Browser automation did not deliver `F1` to the Web canvas, so Web-specific F1 delivery was not re-claimed; the unchanged runtime handler and preserved automated coverage passed. No publication or deployment was performed. This follow-up changes no Milestone 0–4 acceptance result and authorizes no Milestone 5 system.

## Milestone 4.2 inventory drag/backpack-clarity verification

M4.2 technical verification is complete. Twelve discoverable suites passed **145/145 tests and 1,709 assertions with no failures or skips**. This preserves the full **132/132-test, 1,584-assertion Milestone 1–4.1 result** and adds 13 focused M4.2 tests/125 assertions covering one-backpack terminology, typed drag payload identity/revision data, all three active and backpack destinations, combat lockout, staged active-to-empty storage, occupied cross-area swaps, reward dragging to active/backpack slot 3, exact full-inventory leave-behind or Skip Gear behavior, exactly-once confirmation, and stale/same-area rejection without mutation. Twenty dynamic-fit assertions use the longest catalogue item name across all six reward destination controls, all six inventory action-target states, and key two-line prompts; seven assertions prove the 8-pixel pointer threshold starts native drag without mutation; five prove touch thresholding preserves the first armed pointer against a second touch.

Godot 4.7 opened the configured main scene directly into `/GameRun`. A real `InputEvent` pointer drag moved Magnetic Flail from active slot 3 toward empty backpack slot 3: the drop staged `move_to_backpack`, left inventory revision 6 unchanged, and named the no-loss consequence; the separate Confirm applied exactly once at revision 7, and a repeated invocation left revision 7 unchanged. The 1280 x 720 HUD showed one backpack, all third-slot targets, and no visible overflow or border crossing. Evidence: `res://docs/screenshots/milestone_4_2_inventory_drag.png`.

Fresh cursor-bounded editor logs contained no new line, warning, or error; the game log contained only development-helper registration. Fresh Windows and Web exports both completed with exit code 0 and no export warning/error. The Windows headless smoke exited 0, loaded `game_run.tscn` plus the M4.2 scripts/Resources, produced empty stderr, and reported no diagnostic. The final locally served Web build rendered at 1280 x 720, unlocked sound with one ordinary click, staged Hacker Deck reward→active slot 3 through real pointer drag without pre-Confirm mutation, and applied it with one ordinary Confirm click. A second real pointer drag staged active slot 3→empty backpack slot 3 with the named no-loss consequence; one Confirm left active slot 3 empty and backpack slot 3 holding Hacker Deck. Compact ASCII copy showed no glyph boxes, overflow, or border crossing, and the final browser warning/error console was empty. Selling, salvage, rarity, uniques, set items, category slots, and every Milestone 5+ system remain unimplemented. No publication or deployment was performed.
