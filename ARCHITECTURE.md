# Neon Loop Architecture

## Status

This document describes the implementation through **Milestones 0–6 plus owner-accepted WP01–WP06**. WP01 adds the reusable visual language without gameplay authority. WP02 migrates the core run authority to an explicit three-lap/three-block lifecycle, exact-once lap decisions, all-crew production access, cadence bands, state-clarity presentation, and lifecycle summary fields. WP03 replaces the production Milestone 5 hand/five-slot interaction with a focused next-block District Plan. WP04 preserves the bounded catalogue and economy while making build, reward, inventory, and shop consequences exact and visibly expressed. WP05 adds the selected Environment / Focus / Backup authority. WP06 replaces release-visible debug communication with deterministic authored city-block, silhouette, telegraph, feedback, audio-mix, and phase-transition presentation without changing gameplay authority.

Milestone 5 was merged through PR #4 at `da934897cbdee44cb4d1a44b25e91b458558bfbc`. Milestone 6 was fast-forwarded through `a147f93`; Pages run 29960250903 deployed its tentative playtest build. WP05 commit `37ebc9d872f2fd4972e5ac5cc621148c00f0d649` and Pages run 32931503114 are the preceding published boundary. WP06 was owner-accepted for publication on 2026-08-30; exact commit/Pages provenance is recorded after deployment. WP02/WP03/WP04 qualitative records remain pending.

WP04 was implemented on the WP03/documentation baseline `48ffb58fdcdcb1bd4d74bd011c2115c91a5f42a5`, owner-authorized, and subsequently published from `782f7fe18fa434d47020f1d4bc837c9c05790dad`. Publication does not satisfy its pending five-person consequence/variety gate. WP05 Part A began under a later explicit task; its recommendation was approved on 2026-08-23, implemented, and owner-accepted with all remaining gates on 2026-08-26.

On 2026-08-21 the owner separately authorized the technically evidenced WP02 boundary for a `main` and GitHub Pages browser-playtest release. On 2026-08-22 the owner separately authorized the evidenced WP03 boundary for the next `main` and Pages browser-playtest release. Publication does not close the still-pending WP02 comprehension or WP03 first-use qualitative gates.

The working tree also carries owner changes that are not WP04/WP05 authorship. The WP04 start snapshot contained 57 Godot-AI 3.1.5 paths (51 tracked plus six untracked); by the 2026-08-26 WP05 finalization audit it had advanced to 66 paths (53 modified plus 13 untracked), and `project.godot` carried an Autoload-order-only diff. Owner reward-modal/combo corrections and the earlier display-key deletions remain preserved. None is silently restored or attributed to WP05.

The rationale for the revised downstream boundaries is recorded in `docs/decisions/0001-run-engagement-escalation-and-randomness.md`. The owner-approved WP00 product/architecture rebaseline is recorded in `docs/decisions/0002-wp00-product-rebaseline.md` and `GameSpecifications.md` section 0.

## WP00-approved target and migration architecture

WP00 is documentation-only. WP01–WP06 have implemented their bounded portions of the migration map. This section distinguishes accepted runtime/presentation boundaries from still-prospective WP07 work.

### Implemented WP02 lifecycle with WP03 focused PLAN

```text
SELECT CREW
  -> LAP 1: [PLAN -> BLOCK -> REWARD] x3 -> EXTRACT / PUSH
  -> LAP 2: [PLAN -> BLOCK -> REWARD] x3 -> EXTRACT / FINAL-LAP COMMIT
  -> LAP 3: [PLAN -> BLOCK -> REWARD] x3 -> BOSS
  -> RESULT
```

`RunDirector` remains sole run-state, eligible-time, Heat, irreversible Night Pressure, scaling/threshold-latch, precedence, outcome, and summary authority. It composes a narrowly scoped `DistrictRunLifecycle` helper for explicit phase/lap/block revisions, exact-once decision tokens, the accepted decision trail, and boss commitment. `DistrictLoopDefinition` supplies the exact 3×3 structure and lap modifiers. UI labels are snapshots, never lifecycle authority.

### Authority and migration map

| Approved product change | Current owner/contract | Target owner and migration boundary | Compatibility/deprecation risk |
| --- | --- | --- | --- |
| Three laps × three blocks; Extract/Push after laps 1–2; final-lap boss commitment | Implemented by `RunDirector` + `DistrictRunLifecycle`; `RunFlowController` maps meaningful route outcomes into blocks | WP02 landed authoritative IDs, revisions/tokens, modifiers, summaries, cleanup, and configured threshold containment | Do not infer lap progress from UI or route dots; WP03 may migrate route scheduling but not this authority |
| All three crew on fresh production profiles | Implemented by `PersistentProfileData`/`AppState` access policy and `RunContentAccessSnapshot` | WP02 exposes all crew while retaining the serialized v1 Jax fact and retired Zoey/Rex history | Same-seed reproduction includes the access snapshot; loading never invents or rewrites legacy facts |
| Focused next-block District Plan | Implemented by `CardSystem` lap deck/offer/selection/history; `RunFlowController` safe dispatch; internal `PatrolController` approach boundary; snapshot-only `GameHUD` | WP03 keeps stable IDs, authored effects, `cards` stream, revision/token/exact-once authority; the production flow uses lap-scoped offers and resolved history with no hand/five-slot release UI | Locked schema-1 vector and stream isolation prove the new visible PLAN draw boundary; isolated M5 fixtures retain legacy compatibility |
| Minimal combat HUD and focused decisions | `GameHUD` plus `VerticalSliceOverlay` broad simultaneous presentation | WP01 owns reusable icon-plus-label components, minimal HUD, and focused shells; gameplay owners continue to publish snapshots and receive typed intent | Do not hide required state without an inspect path; do not move calculations or validation into UI |
| Environment/Focus/Backup combat vocabulary | `EnvironmentController`, `FocusController`, `CallBackupController`; configured bar uses context Hydrant/Power Box, Focus, and finite Backup; Subway is strategic travel | Owner-approved local WP05 implementation; Rally/Hanging Sign and prototype GameRun seams removed from release composition | WP04 remains published; avoid a global event bus, direct-control creep, or multiple environment buttons |
| Breadth/cosmetic/challenge progression only | `SaveService`/`AppState` version-1 settings/unlocks; Scrap summary field | WP02 retires crew grants; Hacker Deck/Gang Hideout remain active breadth rules; later content still needs approval | No save-version change. Scrap remains summary-only; no hidden permanent power |
| New acceptance/cadence targets | `RunCadenceTracker` configured by `wp02_cadence` | WP02 records ambient 10–20, block 45–90, and lap 120–180; WP07 owns representative fight/run distribution acceptance | Measurement never schedules gameplay; averages alone do not pass |

### Target presentation boundaries

- Combat shows crew/health, labelled Heat and Night Pressure, phase/block/lap, next event/countdown or visible approach, immediately spendable resource, Environment/Focus/Backup state, and a compact inspectable build summary.
- PLAN, reward/equipment, shop, and Extract/Push temporarily own attention and present exact consequences before one dominant confirmation.
- Persistent hand, future-slot legality, route-history dots, backpack management, full rules prose, and shop stock do not remain on the combat layer when non-actionable.
- Resolved District Plan blocks are simple history, not editable targets.
- Result presentation recalls decisive choices/build expression before progressively disclosed complete statistics.

### Implemented WP01 presentation boundary

`NeonUiTokens` creates the shared `Theme` contract for typography (16/18/20/26/34), 4–32-pixel spacing, surfaces/borders, semantic state colors, visible focus, disabled controls, 48-pixel touch minimums, and bounded motion. `NeonChoiceCard`, `NeonStatComparison`, `NeonCountdownStatus`, `NeonInterventionButton`, `NeonToast`, `NeonTooltip`, and `NeonPhaseBanner` are presentation-only composed controls.

`GameHUD` continues to subscribe to authoritative snapshots and emit typed intents. It presents phase/next-event/countdown first, keeps the combat center clear, exposes compact inspectable crew/build state, and opens focused decision layers for District Plan, equipment, shop, and Extract/Push. WP03's District Plan automatically owns attention at each PLAN boundary, presents up to two large next-block locations, and forwards the exact stable card/offer/lifecycle/lap/block context through native click/tap/keyboard activation. `VerticalSliceOverlay` applies the same hierarchy to crew selection, pause/settings, tutorials, and summary; legacy tutorial banners are suppressed while PLAN itself teaches the decision. WP05 supplies live Environment, Focus, and Backup snapshots in combat; Subway remains strategic travel. The visual gallery is an evidence fixture, never part of `/GameRun`.

No WP01 control calculates Heat, Night Pressure, health, reward results, cooldowns, routes, legality, or summary values. Safe-area adjustments remain presentation geometry only. Random schema version 1 and all seven stream states are untouched.

### Target progression and content access

Fresh production access is all three crew, eight existing equipment entries, and the three existing cards other than Gang Hideout. WP02 implements the all-crew policy while retaining the serialized v1 Jax default and loadable Zoey/Rex history. Hacker Deck and Gang Hideout remain active breadth unlocks. Development/test access remains 3/9/4. No landed change adds a content entry, permanent stat, save version, active-run save, or meta economy.

### Implementation sequencing

WP01 presentation, WP02 lifecycle/crew-profile migration, WP03 card/route interaction, WP04 consequence/balance migration, WP05 Environment / Focus / Backup, and WP06 world/combat presentation are implemented. WP05 Part A remains archived comparison evidence. WP06 owns only art/presentation polish: `DowntownBackdrop` maps existing context snapshots to five bounded profiles; `ActorVisual` owns replaceable silhouettes/status shapes; `CombatTelegraph`, `CombatFeedback`, and `HitSpark` own bounded cues; `PhaseTransitionPresenter` observes state without intercepting input; and `AudioPresentationController` mixes existing cues/buses. None is gameplay authority. WP07 remains unauthorized.

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

The project explicitly preserves viewport stretch mode, integer scale mode, nearest-neighbour canvas texture filtering, 2D pixel snapping, and the 1280 × 720 16:9 viewport/window dimensions. The owner's two pre-existing `project.godot` deletions mean the aspect and nearest-mipmap-filter values are no longer written as explicit overrides; they use engine defaults and are not Milestone 6 changes. Letterboxing remains preferable to distortion. HUD labels and buttons use at least 16-pixel text at the native viewport, ordinary controls generally use 18 pixels where space permits, and headings/primary values use a larger hierarchy.

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
|- EnvironmentController
|- FocusController
|- CallBackupController
|- ComboTracker
|- RunCadenceTracker
|- RunCoolingController
|- RunEncounterController
|- RunFlowController
|- CardSystem
|- SynergySystem
|- DisplayController
|- ApplicationSettingsController
|- TutorialPromptController
|- ScreenShakeController
|- AudioPresentationController
|- DowntownLoop
|- Camera2D
|- GameHUD
|- VerticalSliceOverlay
`- DebugOverlay
```

Canonical scene locations:

- `res://scenes/game/game_run.tscn`
- `res://scenes/stages/downtown_loop.tscn`
- `res://scenes/ui/game_hud.tscn`
- `res://scenes/debug/debug_overlay.tscn`
- `res://scenes/actors/jax.tscn`
- `res://scenes/actors/zoey.tscn`
- `res://scenes/actors/rex.tscn`
- `res://scenes/actors/street_punk.tscn`
- `res://scenes/actors/bat_thug.tscn`
- `res://scenes/actors/bottle_thrower.tscn`
- `res://scenes/actors/viper_enforcer.tscn`
- `res://scenes/actors/the_viper.tscn`
- `res://scenes/actors/backup_runner.tscn`
- `res://scenes/combat/combat_projectile.tscn`
- `res://scenes/audio/audio_presentation_controller.tscn`
- `res://scenes/effects/combat_feedback.tscn`
- `res://scenes/interactables/coin_cluster.tscn`
- `res://scenes/interactables/fire_hydrant.tscn`
- `res://scenes/interactables/power_box.tscn`
- `res://scenes/ui/vertical_slice_overlay.tscn`

Their composition/presentation scripts live at:

- `res://scripts/run/game_run.gd`
- `res://scripts/run/run_director.gd`
- `res://scripts/run/district_loop_definition.gd`
- `res://scripts/run/district_run_lifecycle.gd`
- `res://scripts/run/run_random_streams.gd`
- `res://scripts/run/run_cooling_controller.gd`
- `res://scripts/run/run_flow_controller.gd`
- `res://scripts/run/run_cadence_tracker.gd`
- `res://scripts/run/run_content_access_snapshot.gd`
- `res://scripts/patrol/patrol_controller.gd`
- `res://scripts/encounters/run_encounter_controller.gd`
- `res://scripts/stages/downtown_loop.gd`
- `res://scripts/stages/downtown_backdrop.gd`
- `res://scripts/stages/debug_lane_markers.gd`
- `res://scripts/stages/route_markers.gd`
- `res://scripts/ui/game_hud.gd`
- `res://scripts/ui/vertical_slice_overlay.gd`
- `res://scripts/ui/equipment_drag_payload.gd`
- `res://scripts/ui/equipment_drag_slot.gd`
- `res://scripts/ui/district_card_drag_payload.gd`
- `res://scripts/ui/district_card_drag_slot.gd`
- `res://scripts/ui/debug_overlay.gd`
- `res://scripts/actors/actor_controller.gd`
- `res://scripts/actors/actor_scene_catalogue.gd`
- `res://scripts/combat/combat_director.gd`
- `res://scripts/combat/combat_projectile.gd`
- `res://scripts/combat/combo_tracker.gd`
- `res://scripts/rewards/reward_director.gd`
- `res://scripts/effects/combat_feedback.gd`
- `res://scripts/interactables/coin_cluster.gd`
- `res://scripts/interactables/fire_hydrant.gd`
- `res://scripts/interventions/fire_hydrant_controller.gd`
- `res://scripts/interventions/environment_controller.gd`
- `res://scripts/interventions/focus_controller.gd`
- `res://scripts/interventions/call_backup_controller.gd`
- `res://scripts/ui/display_controller.gd`
- `res://scripts/app/application_settings_controller.gd`
- `res://scripts/audio/audio_presentation_controller.gd`
- `res://scripts/effects/combat_telegraph.gd`
- `res://scripts/effects/screen_shake_controller.gd`
- `res://scripts/tutorial/tutorial_prompt_controller.gd`
- `res://scripts/cards/card_system.gd`
- `res://scripts/cards/card_effect_definition.gd`
- `res://scripts/cards/district_card_definition.gd`
- `res://scripts/cards/district_card_catalogue.gd`
- `res://scripts/cards/card_placement_record.gd`
- `res://scripts/cards/card_resolution_record.gd`

The four authored card Resources and their catalogue live under `res://data/cards/`; their replaceable placeholder icons live under `res://assets/ui/cards/icons/`. The WP02 loop and cadence definitions live under `res://data/run/`; Milestone 6 actor, attack, encounter, intervention, audio, tutorial, persistence, and presentation tuning live in the matching `res://data/` families. The validated actor-scene catalogue maps nine stable IDs to composed scenes. Content data names effects and tuning, while the runtime owners below validate and execute them.

`res://scripts/stages/` is an intentional, narrow addition to the recommended
directory list: it owns only the fixed stage's replaceable presentation and
debug-marker drawing.

`GameRun` owns assembly only. It connects explicit cross-owner signals required by the implemented systems; it must not grow into a second implementation of each child system.

The tree above is the implemented composition through WP04. `DistrictLoopDefinition` is configured on `RunDirector`; `DistrictRunLifecycle` is a run-owned helper rather than a second scene authority. `BuildConsequenceEvaluator` is a pure helper and `NeonBuildCallout` is composed inside the HUD, so WP04 adds no scene-scoped gameplay owner or Autoload. `RunRandomStreams` remains a direct child of `RunDirector`.

WP05 Part A's `wp05_proto_` Resources/runtime/tests remain isolated historical evidence. The former `GameRun` enable/freeze/world-cue seams were removed after owner selection. Configured `GameRun` now composes `EnvironmentController` and `FocusController`, while `RunFlowController` supplies the encounter-authored Environment context; no prototype node is created in release composition.

## Scene ownership

### `GameRun`

- Composes the run-scoped systems, encounter runtime, District Card/equipment authorities, all three intervention authorities, combo/cadence observers, application-settings bridge, tutorial/audio/screen-effect presentation, stage, camera, HUD, vertical-slice overlay, debug presentation, and combat feedback.
- Keeps all run-scoped state in the scene tree rather than a run singleton.
- Captures one immutable-by-convention `RunContentAccessSnapshot` before the first gameplay draw. It validates the selected accessible crew member, exactly one existing starter item, and stable allowed equipment/card IDs; same-seed restart reuses that snapshot while new-seed restart refreshes it from the profile.
- Connects typed run/patrol/encounter/combat/reward/card/intervention/settings/tutorial/audio/display signals without calculating their owned results.
- Begins and restarts composed runs, synchronously clears run-owned actors, summons, projectiles, telegraphs, reservations, rewards, combo/cadence state, card modal/token/pile/pending-route state, patrol modifications, thresholds, timers, intervention ledgers, cooling stock, and random-stream state, and forwards presentation intent to the correct authority.
- Records a completed run with `AppState` only after `RunDirector` publishes the final summary; persistent unlock/lifetime accounting never changes the already-completed run.

### `DowntownLoop`

- Owns the fixed placeholder nighttime street presentation.
- Owns the three lane guide visuals and their visibility operation.
- Owns replaceable route-node and spawn-marker presentation; `PatrolController` owns route progress.
- Provides stage containers for runtime scene instances. `CrewContainer`, `EnemyContainer`, `EffectsContainer`, and `LootContainer` host the Combat Lab actors, feedback, and temporary coin clusters; `Interactables` hosts the functional but presentation-only Fire Hydrant world scene.
- Does not own actor AI, combat, rewards, cards, or run progression.

The lane guides and route markers are development visualization, not movement or patrol authority.

### `GameHUD`

- Presents authoritative run state, route progress, Heat/tier, Night Pressure, timer, extraction, cooling, selected-crew health/state/target, coin total, manual streak, all three intervention states, active equipment, ordered backpack storage, tag counts, synergy thresholds/effects, reward previews, onboarding, sound-unlock status, landscape guidance, and fullscreen state.
- Uses native 1280 x 720 typography and panel geometry, with a 16-pixel minimum for labels/buttons, so glyphs are rendered clearly rather than enlarged from the logical 640 x 360 world canvas.
- Presents the authoritative WP02 phase plus `LAP n/3 · BLOCK n/3`, named next event/countdown or current action, and exact Extract/Push consequence. This is orientation only; it does not own district, route, or progression authority.
- Production District Plan presents the current lap deck's one or two focused next-block choices, exact Heat/effect prediction, one Confirm, and resolved history. Hand/draw/discard/future-slot controls remain hidden compatibility fixtures only.
- Production card choice uses native click/tap/keyboard Buttons and forwards exact offer/lifecycle/lap/block context; it has no drag-source or close path. Historical `DistrictCardDragPayload`/route-slot controls remain isolated M5 compatibility surfaces.
- Equipment rewards preserve native drag plus click/tap/keyboard staging and now show the monotonic reward token, exact active/backpack destination, outgoing/stored/left-behind item, final inventory state, synergy edges, crew values, next-fight promise, and paired payout in one layer.
- Shop presentation observes the exact revisioned authority preview/result and never infers affordability, Heat tier, reward tradeoff, or stock locally.
- Names one backpack containing three ordered inactive slots beside the unchanged three generic active slots; it does not imply multiple bags, loadouts, or item categories.
- Ordinary equipment clicks inspect, while typed `EquipmentDragSlot` controls provide built-in `Control` drag/drop for owned items and reward choices. A valid drop stages the same destination/action state as the click/tap/keyboard fallback and never mutates inventory at drop time.
- Keeps dynamic reward targets compact as `ACTIVE n` / `BACKPACK [n]`, uses compact inventory targets `ACTIVE` / `STORE SLOT` / `SWAP SLOT`, bounds key inventory consequence prompts to two lines, states `CLICKS ONLY INSPECT; NEVER DISCARD` in Help, and uses ASCII action wording so the same glyphs render in desktop and Web builds. Longest-catalogue-name pixel-fit tests protect all six reward destinations, all six inventory action-target states, and key two-line prompts, not only static scene bounds.
- Reward selection, destination selection, inventory actions, card planning, and named confirmations are presentation state; the HUD forwards typed player intent with the inspected inventory/hand/route revisions and reward/placement tokens and never mutates ownership itself.
- Shows replaceable icons, written names, exact charge/cooldown or target requirements, textual validity, tooltips, and activation/rejection feedback for Fire Hydrant, Call Backup, and Subway Reroute. Hydrant hover/focus exposes the same 112-pixel preview used by authority.
- Forwards run actions, equipment acquisition/management intent, card acquisition/placement/cancel intent, all intervention requests, Hydrant preview, Help, and fullscreen intent through typed signals.
- Does not own authoritative Heat, Night Pressure, time, cooling, rewards, equipment, synergies, extraction, cards, crew, combo, boss, or intervention state.

### `VerticalSliceOverlay`

- Owns presentation and typed intent for the pre-run crew menu, pause menu, settings panel, boss health/phase/warning strip, contextual tutorial strip, combo celebration, victory presentation, and complete run summary.
- Displays Jax, Zoey, and Rex availability and written mechanical roles. It cannot unlock content or start an inaccessible crew ID; `GameRun` revalidates intent against `AppState` and `RunLoadoutDefinition`.
- Presents all eight settings fields, but emits a settings dictionary rather than writing buses, windows, effects, focus pause, or save data itself. Save success/failure text comes back from authority.
- Presents result, loop/lap/block completion, boss commitment, accepted decision trail, build identity, duration, seed/schema, maximum Heat, final Night Pressure, enemy/elite counts, boss result, coins, manual clusters, maximum streak, scrap, highest combo, equipment, active synergies, Restart Run, and Return to Main Menu from the immutable summary snapshot.
- Uses explicit text alongside colour for locked/valid states, warnings, cooldowns, boss phase, and telegraphs.

### `DebugOverlay`

- Owns development-only diagnostic presentation and debug controls.
- Handles the `F1` development key to toggle its own visibility.
- Emits a typed `lane_visibility_requested(bool)` request from its lane button or `F2` shortcut.
- Does not take ownership of stage or combat state: `GameRun` forwards the request and `DowntownLoop` remains the sole owner of lane-marker visibility.
- Is forced hidden and ignores its development controls when `OS.is_debug_build()` is false; development/test profiles retain full catalogue access and the reset-save control.

### Actors and automatic combat

`ActorController` composes `ActorStateMachine`, `HealthComponent`, `AttackController`, `StatusController`, an active-phase logical hitbox, and replaceable `ActorVisual` presentation. The same controller runs Jax, Zoey, Rex, Backup Runner, Street Punk, Bat Thug, Bottle Thrower, Viper Enforcer, and The Viper from typed `ActorDefinition`/`AttackDefinition` data. The actor state machine exposes idle, patrol, acquisition, approach, windup, active, recovery, stun, knockback, incapacitated, and dead states. Stable-ID special attacks are sorted before a deterministic authored cycle: a basic attack opens the next available special, per-special cooldowns gate reuse, and `one_shot` prevents The Viper's summon from repeating. No gameplay RNG chooses attack order.

`ActorDefinition` owns role-specific health, speed, damage, knockback/stagger resistance, light-stagger armour, control-duration/lockout, preferred ranged distance, elite/boss damage multipliers, intervention-cooldown multiplier, environmental-collision multiplier, enrage threshold/multipliers, coin value, cleanup delay, and exactly one existing starter item for each selectable crew member. `StatusController` owns stable Bleed, Shock, and mechanics-neutral Wet duration/stack/tick state. `ActorVisual` observes state/status and draws replaceable palette/silhouette variants plus idle, walk, windup, active, recovery, knockback, incapacitated, and death poses; it is never attack timing or state authority.

`CombatDirector` remains the combat authority. It owns stable actor registration, opposing-team target validity, deterministic nearest-target acquisition, attack-position reservations, damage resolution, combat-local hit-stop, synchronous dead-target invalidation, reservation cleanup, projectiles, charge/area/summon dispatch, boss phase notification, and application of aggregated equipment modifiers/effects. Projectiles are stepped in stable spawn order and resolve once or expire; charge and area attacks reuse the direct-hit path. Light knockback at or below authored armour is ignored. Stun duration is reduced and capped by actor data, and a control lockout prevents permanent restunning of the elite/boss. Rex's target-role bonus and Jax's environmental-collision multiplier are applied by role/data rather than actor-ID branches. `AttackPositionRegistry` exposes six reachable positions spanning the three authored lane centers. Actors never own rewards, equipment inventory, intervention ledgers, run progression, or UI state.

### Combat-safe space

`CombatSpaceDefinition` is the one authored Downtown Loop combat-space contract. Its inclusive actor-origin rectangle is X 164 through 456 and Y 194 through 258, with lane centers at Y 194, 226, and 258. `CombatDirector` passes the same typed Resource to actors and reservations; the Combat Lab uses it for spawns and coin placement; actors use it for approach, knockback, and recovery clamping; and debug lane markers render it. The right edge accounts for the active actor silhouette plus the maximum conservative mobile safe-area inset. This removes the duplicated wider bounds that allowed long fights and replacement spawns to creep under HUD panels while preserving visible displacement within the safe space.

### `RunEncounterController`

- Owns encounter start/completion identity, the stable actor-scene catalogue, permanent-crew/temporary-ally/enemy spawning, deterministic mixed-enemy plans and lanes, authored staged-spawn timing, per-encounter/global caps, boss summons, defeat/elite/boss accounting, coin-cluster presentation requests, and transition-safe cleanup.
- Applies the `RunDirector` health, damage, and spawn-budget scales to fresh encounter actors without moving combat calculations into run state.
- Reports one typed completion notification per encounter token; `RunDirector` independently rejects duplicate or retried completion IDs.
- Requests the existing standard reward preparation after completion and exposes the typed baseline/non-elite source context used to decide whether a supplemental card opportunity is eligible; authoritative reward and card accounting remain outside this controller.
- Filters and sorts typed `EncounterSpawnEntry` actor IDs before using `enemy_variants` for budgeted roster choices and `spawns` for lane choices. Minimum entries guarantee required actors: baseline fights include Street Punk with optional Bat Thug/Bottle Thrower, `viper_signal` guarantees one Viper Enforcer, and `viper_showdown` contains one boss. The three non-boss definitions build their complete deterministic actor-ID queue at encounter start, wait 3.0 eligible encounter seconds before the first actor, and then release one queued actor every 12.0 eligible encounter seconds; a full concurrency cap leaves the elapsed delay at zero and retries when a stable slot is available. Completion waits for both the pending queue and all live enemies. Boss entry remains immediate after its separate intro, and The Viper's one-shot summon requests `bat_thug` and `street_punk` in stable ID order within the boss encounter cap.

### Combat and reward presentation

`CombatFeedback` observes resolved events and owns code-drawn hit sparks, optional damage numbers, death/spawn/water effects, and the preserved Web gesture-unlock path; it cannot change combat outcomes. `ScreenShakeController` applies deterministic presentation-only camera offsets from authored hit categories and the 0–1 accessibility intensity. `CombatTelegraph` draws a labelled world warning circle/crosshair for The Viper's area, charge, and summon attacks, freezes while paused, and clears synchronously on terminal/restart/menu transitions. Gameplay radius/timing remain in `AttackDefinition`/`CombatDirector`.

`AudioPresentationController` prebuilds 22,050 Hz mono 16-bit prototype PCM from 19 typed cue definitions without any random draw. Eight SFX voices share the `SFX` bus; district and boss-loop players share `Music`. District music runs throughout ordinary play, the boss layer starts for boss intro/active states, and terminal/menu cleanup removes it. `ApplicationSettingsController` applies Master/Music/SFX levels through the versioned bus layout. Audio remains replaceable presentation, not timing or combat authority.

`CoinCluster` is a generous mouse/touch `Area2D` under `LootContainer`; it forwards intent and presents a pulse, pointer, and click/tap countdown but never credits coins itself.

### Fire Hydrant intervention

`FireHydrantController` remains the run-scoped authority. A `FireHydrantTuning` Resource owns its 112-pixel circle, 18 damage, fixed leftward 300-force/0.30-second knockback, four-second Wet application to surviving targets, eight-second base cooldown, and feedback timings. The controller validates live registered enemies in stable registration order, rejects no-target and cooldown requests, locks before resolving callbacks to prevent duplicate activation, applies damage/knockback through `CombatDirector`, and owns cooldown progression. Successful environmental hits continue the shared presentation-only combo. Zoey, Hacker Deck, and Tech 2 scale its remaining cooldown proportionally through one composed multiplier; they do not add charges or bypass validity.

The `FireHydrant` world scene and `GameHUD` are presentation and input surfaces. Both forward the same activation intent, and the world preview reads the exact tuning Resource used by authority. The world scene owns hover/tap bounds, highlighting, range drawing, replaceable hydrant/water art, and local presentation timers. Neither can choose targets, apply damage, or consume cooldown.

### Call Backup and Subway Reroute

`CallBackupController` owns a transactional, finite two-charge ledger, 30-second base cooldown, activation tokens, exactly two temporary `backup_runner` allies, 12 eligible-combat-second lifetime, defeat notification, rollback on spawn/registration failure, and terminal/restart cleanup. Cooldown consumes eligible active time; promised ally lifetime consumes only active combat time. Invalid state, active instance, no-charge, cooldown, spawn, or registration rejection changes no accepted token, charge, cooldown, or ally ledger. `RunEncounterController` creates/registers/removes the actual allies, while `GameHUD` only presents the typed snapshot and forwards intent.

`RunCoolingController` remains Subway Reroute authority. It accepts only safe non-boss `PATROLLING` travel when `PatrolController.can_reroute()` is true and a finite charge remains. After all rejection checks, it commits one of two charges and -15 Heat before synchronously advancing to the next authored occurrence, so the next encounter sees the cooled tier. It cannot run during an active boss, mutate Night Pressure, clear/reopen progression latches, consume a card-owned Subway skip, or draw randomness. Exhausted/invalid requests are immutable rejections.

## Run-system ownership

WP02 extends the preserved run-scoped authorities through composition. No presentation node becomes a gameplay owner, and neither persistent Autoload may own an active run.

| Class | Path | Authoritative ownership |
| --- | --- | --- |
| `DistrictLoopDefinition` | `res://scripts/run/district_loop_definition.gd` | Data-only exact 3×3 loop, stable lap/block IDs, +6 Push Heat, lap Pressure multipliers, reward tiers, and modifier IDs |
| `DistrictRunLifecycle` | `res://scripts/run/district_run_lifecycle.gd` | Run-owned phase/lap/block revision, exact-once lap-decision tokens, accepted decision trail, final-lap commitment, snapshot, and reset helper |
| `RunDirector` | `res://scripts/run/run_director.gd` | State-transition graph and district-lifecycle composition, eligible run time, Heat, irreversible Night Pressure/scaling/threshold latches, owned card-planning pause, ordinary/focus pause authority, boss/victory timing, outcomes, summary record, run seed, and calculations |
| `RunRandomStreams` | `res://scripts/run/run_random_streams.gd` | Seven isolated deterministic stream states and stable-ID selection |
| `PatrolController` | `res://scripts/patrol/patrol_controller.gd` | Authored route sequence and 21.0-second represented approach, authoritative current position, monotonic stable occurrence/slot identities, five-slot future snapshot, route revision, one-per-occurrence pending/resolved modifications, encounter pauses, safe boundaries, and finite reroute progression |
| `RunEncounterController` | `res://scripts/encounters/run_encounter_controller.gd` | Encounter/source identity, actor-catalogue spawning, deterministic roster/lane selection, 3.0s/12.0s non-boss staged-spawn queues, scaled actor creation, temporary allies, boss summons/results, enemy/elite counts, baseline card-reward eligibility, caps, and cleanup |
| `RunCoolingController` | `res://scripts/run/run_cooling_controller.gd` | Finite Subway charges/route advance; finite priced shop stock; monotonic visit context; exact Heat/economy preview/result; Heat-only cooling |
| `RunFlowController` | `res://scripts/run/run_flow_controller.gd` | Typed coordination between run, meaningful route outcomes, patrol, encounters, rewards, cards, cooling, route effects, exact lap-decision tokens, boss/victory flow, starter equipment, summary settlement, and presentation intent |
| `CombatDirector` | `res://scripts/combat/combat_director.gd` | Actor combat, projectiles, charge/area/summon dispatch, boss phase edges, environmental hits, stable targeting/reservations, and complete run-owned combat cleanup |
| `FireHydrantController` | `res://scripts/interventions/fire_hydrant_controller.gd` | Hydrant target validation, area damage/knockback/Wet resolution, immutable rejection, and scalable cooldown |
| `CallBackupController` | `res://scripts/interventions/call_backup_controller.gd` | Finite charges, activation tokens, two-ally transaction, eligible-time cooldown, combat-only 12-second lifetime, defeat/terminal/restart cleanup, and immutable rejection |
| `ComboTracker` | `res://scripts/combat/combo_tracker.gd` | Shared crew/environmental hit count, 2.5-second eligible-time expiry, highest value, and presentation-only milestones |
| `RunCadenceTracker` | `res://scripts/run/run_cadence_tracker.gd` | Measurement-only eligible-time records for ambient, strategic, and major opportunities; no scheduling and no coin-as-strategy relabelling |
| `RewardDirector` | `res://scripts/rewards/reward_director.gd` | Standard reward selection, latched Heat coin multiplier, immutable payout results, monotonic equipment-choice tokens, deterministic equipment coordination, coin ledger, at-most-once clusters, and manual streak |
| `CardSystem` | `res://scripts/cards/card_system.gd` | Finite draw pile/hand/discard state, capacity/no-reshuffle rules, `cards`-stream selection, planning state, revisioned placement validation/staging, pending effects, card-reward tokens/acquisition, exactly-once resolution coordination, and restart cleanup |
| `SynergySystem` | `res://scripts/synergies/synergy_system.gd` | Three active equipment slots, three ordered backpack slots, unique ownership, stable active-only aggregation, revisioned inventory transactions, exact reward/inventory previews, threshold evaluation, and activation/deactivation signaling |
| `ApplicationSettingsController` | `res://scripts/app/application_settings_controller.gd` | Applies sanitized presentation/audio/display settings and forwards focus-pause intent to `RunDirector`; never pauses the tree directly |
| `TutorialPromptController` | `res://scripts/tutorial/tutorial_prompt_controller.gd` | Stable-ID, priority-ordered, once-per-run nonmodal contextual prompts |
| `AudioPresentationController` | `res://scripts/audio/audio_presentation_controller.gd` | Generated district/boss music and SFX playback only |
| `ScreenShakeController` | `res://scripts/effects/screen_shake_controller.gd` | Deterministic presentation-only camera impulses and reset |

## Run lifecycle

`RunDirector` permits only explicit edges and rejects invalid or duplicate transitions. Its WP02 district lifecycle is:

```text
SELECT_CREW -> INTRO
  -> LAP 1: [PLAN -> BLOCK -> FIGHT/SHOP -> REWARD] x3 -> LAP_DECISION -> EXTRACT or PUSH
  -> LAP 2: [PLAN -> BLOCK -> FIGHT/SHOP -> REWARD] x3 -> LAP_DECISION -> EXTRACT or FINAL-LAP COMMIT
  -> LAP 3: [PLAN -> BLOCK -> FIGHT/SHOP -> REWARD] x3 -> BOSS -> RESULT
```

The existing `RunState` graph remains the lower-level simulation transition contract for `PATROLLING`, `ENCOUNTER_ACTIVE`, `REWARD_SELECTION`, `SHOP`, `EXTRACTION_AVAILABLE`, `BOSS_INTRO`, `BOSS_ACTIVE`, terminal states, and `PAUSED`. `DistrictRunLifecycle` maps those states to the player-facing phases without replacing their owners. A meaningful block is an encounter, shop, utility, or card-modified route occurrence; unmodified fixed-route travel is internal navigation rather than a counted block. Stale, replayed, wrong-phase, wrong-lap, and invalid decision requests reject before Heat, Pressure, phase, route, stream, or token-ledger mutation.

The run timer and Night Pressure time gain advance only while `is_eligible_active_time()` is true. Intro, pause, reward selection, shop, extraction transition, 2.5-second boss intro, two-second victory presentation, terminal states, and summary do not advance either value. Card planning is accepted only from the safe `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE` states. Planning entered from `PATROLLING` uses a `RunDirector`-owned `PAUSED` transition; an ordinary pause toggle cannot release that card-owned pause. Ordinary pause and focus-loss requests also pass through `RunDirector`; focus loss during unskippable intro/boss-intro is latched and applied only after a safe pauseable transition. `RunDirector` coordinates state but does not absorb patrol, encounter, combat, reward, card, persistence, or UI details.

Main-menu presentation occurs before a run begins and before any gameplay draw. Selecting any of the three production-accessible crew IDs captures content access, installs that crew's single starter item, then starts ordinary initialization. Same-seed restart reuses that exact access snapshot and selected crew; new-seed restart refreshes access. The Viper's defeat enters `VICTORY`, waits for the authored presentation duration, settles every unresolved coin cluster at full base value, builds the summary, and only then records idempotent unlock/lifetime data. Extraction and defeat use the same pending-base-coin settlement before summary publication.

## Heat and Night Pressure

`RunDirector` is the sole authority for two separate values:

- **Heat** is a tactical district-alert value clamped from 0 through 100. It controls immediate encounter composition, elite availability, danger, and ordinary reward quality, and may be changed by finite player-facing effects.
- **Night Pressure** is non-negative, monotonically increasing run progression. It advances through eligible active simulation time and exactly-once encounter completion, controls long-term enemy/spawn scaling and major progression, and can reset only when the run ends or restarts.

Extraction and boss thresholds belong to Night Pressure, not Heat. Once crossed, thresholds latch and cannot be reopened or cleared by cooling. In the configured WP02 district mode, these latches remain scaling/debug facts but cannot dispatch progression early: extraction is offered only after blocks three and six, and the boss follows block nine after the second Push commits to the final lap. Isolated legacy configurations without a `DistrictLoopDefinition` preserve the historical safe-boundary threshold dispatch for compatibility.

Heat uses exact tiers 0: 0–19, 1: 20–39, 2: 40–59, 3: 60–79, 4: 80–99, and 5: 100. Its preserved Resource controls immediate spawn additions, enemy damage, elite eligibility, reward quality, reward multiplier, and HUD presentation. The configured Milestone 6 escalation Resource tunes Night Pressure to 0.07 per eligible active second plus exactly-once completion gains of 1.5 (standard) or 3.0 (elite-flagged), while preserving extraction thresholds 18/36 and boss threshold 50. It retains +1% health, +0.5% damage, and +1.25% spawn budget per Pressure plus the global cap 30. Spawn budgets use non-negative round-half-up: `floor(scaled_value + 0.5)`, then encounter and global caps are applied. The older `milestone_3_escalation` Resource remains tracked as the historical accepted M3 tuning but is not assigned to the configured M6 `GameRun`.

Extraction latches remain configured at Night Pressure 18 and 36; the boss latch remains 50. In district mode they never bypass the authoritative lap decisions or boss commitment. Cooling never mutates Night Pressure, changes the decision ledger, clears final-lap commitment, or regenerates stock. The preserved legacy threshold-only mode still enforces queued safe-boundary dispatch and same-update boss precedence unless extraction was already confirmed.

`RunCoolingController` begins each run with two Subway charges (15 Heat each) and two shop purchases (18 Heat each at 60 coins). Each shop visit receives a monotonic revision and explicit source. Its exact preview/result freezes coins, Heat/tier, reward quality/multiplier, global/visit stock, and unchanged Night Pressure. Production requests pass revision+source; partial, stale, wrong-source, reentrant, zero-Heat, unaffordable, visit-used, and sold-out requests reject atomically. Neither cooling source regenerates through time.

## Coin-cluster ownership

Coin clusters are the vertical slice's optional ambient interactions. `RewardDirector` owns the authoritative coin ledger, each cluster's resolution state, and the manual-collection streak. Defeated rewarding enemies request their authored award and presentation displays one cluster, but neither combat actors nor UI may directly credit the ledger. Terminal settlement resolves still-visible clusters at full base value before the summary, without a manual bonus or streak increment.

Manual click and the approximately 2.5-second timeout converge on one authoritative at-most-once resolution. Either path credits the full base value exactly once. Only a successful manual resolution advances the approximately 3-second streak and may add the data-driven bonus, capped at 10% of that cluster's base value; auto-collection grants no manual bonus. The presentation lives under `LootContainer`, remains non-authoritative, and is offset outside the immediate melee silhouette.

Milestone 3 standard rewards remain selected from stable-ID, quality-filtered `StandardRewardDefinition` Resources with the `rewards` stream. Milestone 4 pairs eligible standard rewards with three equipment candidates generated only from the `equipment` stream. `RewardDirector` filters invalid, duplicate, and already-owned definitions across active and backpack positions, sorts stable equipment IDs, draws without replacement, and accepts one pending token exactly once. Milestone 4.1 separates non-mutating choice/destination review from application: confirmed equip/store or **Keep Current Build** resolves the paired standard reward exactly once. Coin-cluster interaction retains the Milestone 1 at-most-once/full-value/manual-streak behavior; presentation-only draws consume `cosmetic` so visual activity cannot alter reward or equipment outcomes.

WP04 latches `RunDirector.get_reward_multiplier()` with the selected standard reward and applies it to coins only using multiplier quantization plus non-negative half-up rounding; Scrap remains raw. It publishes immutable pending/applied payout snapshots. Equipment choices additionally receive a monotonic authority token that is not reset between runs, so a delayed Confirm or Skip from a prior offer cannot mutate a later encounter even when encounter IDs restart.

Milestone 5 adds a supplemental card-reward phase after the existing standard/equipment reward is resolved. Only a completed baseline, non-elite standard encounter may open it. `RewardDirector` coordinates presentation and application through typed `CardSystem` methods, but `CardSystem` alone filters and selects card candidates with the `cards` stream. The offer contains up to three remaining valid deck cards, a selected card may enter the hand exactly once only when capacity permits, and **Skip / Keep Hand** clears the phase without changing the hand or draw pile. Card-created fights, elite encounters, shops, reroutes, and every card effect set `allows_card_reward` false, so the supplemental phase cannot recurse or replace/mutate the standard/equipment contract.

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

Milestone 6 changes neither derivation nor draw semantics, so random schema version 1 remains unchanged. `RunDirector` still selects eligible encounter IDs with `encounters`; `RunEncounterController` sorts typed roster entries and consumes `enemy_variants` while constructing the complete ordered actor-ID plan at encounter start, then uses `spawns` for a stable lane ID when each queued actor is actually released. Authored 3.0-second entry and 12.0-second interval timers consume no random draw. Boss special order, one-shot summon IDs, ally lanes, projectile stepping, combo, cadence, audio synthesis, tutorial order, screen shake, settings, save handling, and unlock application consume no gameplay stream. Equipment/card access filtering is profile decision context captured before the first draw; same-seed claims therefore require the same content-access snapshot in addition to the same build/content/schema, ordered gameplay decisions, and authoritative timing.

In focused production mode, `CardSystem` performs no hidden INTRO draw. At the first PLAN of each lap it constructs one copy of every accessible valid catalogue card in stable card-ID order and draws a visible offer of up to two without replacement using only `cards`. The unselected choice remains offered; after one selection the offer refills to two while the lap deck has cards, and the three blocks can consume at most three cards. Selection, rejection, dispatch, resolution, and history archival consume no further random draw. Locked schema-1 seed `30301` with full access offers `[gang_hideout, subway_entrance]`; cosmetic-stream perturbation leaves it unchanged. Neither `RewardDirector`'s `rewards` stream nor `encounters`, `spawns`, `equipment`, `enemy_variants`, or `cosmetic` selects cards. Isolated Milestone 5 fixtures retain the historical hand/reward draw path for compatibility only.

The `cosmetic` stream is isolated: adding cosmetic draws cannot change encounter, spawn, reward, equipment, card, or enemy-variant outcomes. Same-seed restart resets every generator, including `cards`, to its derived initial state. Equipment proc chances and equipment reward choices intentionally share the single specification-owned `equipment` stream, so reproducing later choices also requires the same ordered equipment effects and authoritative combat timing. Card reproduction likewise requires the same build/content revision, schema, seed, ordered acquisitions/placements, and authoritative route timing. Reproduction claims are limited to the same supported build/content revision, random schema, captured access snapshot, seed, ordered player decisions/effect resolutions, and authoritative timing context; physics or cross-version bitwise replay is not promised.

## District Card ownership and route resolution

`DistrictCardDefinition` is a typed, data-only Resource containing a lowercase stable ID, display copy, replaceable icon, zero cost/`FREE` label, signed Heat delta, valid baseline node types, uppercase tags, progression implications, and one typed `CardEffectDefinition`. `CardEffectDefinition` has four closed effect kinds and validates the exact payload required by each: encounter ID, authored reward-tier step count, maximum purchases/existing-stock use, guaranteed-equipment flag, or reroute/standard-skip/Subway-charge flags. Definitions never mutate runtime state. `DistrictCardCatalogue` validates unique card/effect IDs and returns the exactly four one-copy definitions in stable card-ID order.

| Stable card ID | Cost / tags | Presented next block | Confirmed Heat | Exactly-once effect when that block is reached |
| --- | --- | --- | ---: | --- |
| `arcade` | `FREE`; `FIGHT`, `REWARD` | `FIGHT + REWARD` | +10 | Starts one standard-only placeholder fight. Its standard reward advances exactly one available authored quality tier on the existing 0/1/3 tier ladder and clamps at the catalogue maximum; it creates no general upgrade system and no card reward. |
| `convenience_store` | `FREE`; `SHOP`, `RECOVERY` | `SHOP + RECOVERY` | -10 | Opens one purchase using the existing finite shop/cooling stock (two run-stock purchases total, each 60 coins for 18 Heat cooling). The card visit allows at most one of those purchases, never replenishes stock, and creates no broader economy. |
| `gang_hideout` | `FREE`; `ELITE`, `EQUIPMENT` | `ELITE + GEAR` | +20 | Starts the scaled `viper_signal` encounter, now authored with one required Viper Enforcer plus budgeted basic enemies, and guarantees the normal equipment-choice phase from eligible catalogue items. It grants no recursive card reward. |
| `subway_entrance` | `FREE`; `REROUTE`, `SKIP` | `TRANSIT + COOLING` | -15 | Replaces exactly one baseline standard encounter with non-combat transit. It never calls the finite Subway intervention, so it consumes/replenishes no Subway charge and grants no encounter/card reward. |

`CardSystem` owns the production lap deck, visible offer, selected-next-block record, staged confirmation, active block effect, resolved current-lap history, archived prior-lap history, offer revision, and exact lifecycle context. Confirm consumes one exact staged token and selection identity; only then does `RunFlowController` apply Heat once and release the planning pause. At a new lap, current history is archived and the accessible one-copy deck is rebuilt. Restart/menu/terminal cleanup synchronously clears the offer, deck, selection, active effect, staged token, both histories, and `cards`-stream draw state. The historical hand/discard/reward/route-placement fields remain operational only when focused mode is not configured by isolated M5 compatibility fixtures.

`PatrolController` remains authoritative for the fixed authored approach and safe occurrence boundary. Its stable occurrences and legacy five-slot records remain available to isolated compatibility tests and development inspection, but production focused PLAN does not expose or mutate future modification slots. The selected card is bound instead to `DistrictRunLifecycle`'s exact stable lap/block ID; this remains a fixed authored route beneath explicit blocks, not procedural route generation.

Focused selection is a two-stage transaction. `CardSystem.stage_focused_district_plan_choice()` validates planning ownership, stable card ID, offer revision, lifecycle revision, stable lap ID, and stable block ID, then issues one monotonic confirmation token. Confirm revalidates the same context against the current lifecycle to reject transition races, consumes the token once, removes only the selected offered card, retains/refills the unselected offer, and binds the authored effect to the exact next block. Only a successful result makes `RunFlowController` ask `RunDirector` to apply Heat exactly once. Invalid, stale, replayed, wrong-phase, wrong-block, cancelled, malformed, or unsafe-transition requests leave Heat, Night Pressure, offer/deck/history, lifecycle, rewards, and every random-stream draw count unchanged. No UI control can bypass these validations.

On route-node entry, `RunFlowController` first preserves the exact current occurrence and invokes `RunDirector.notify_safe_transition_boundary()`. An already-due lap decision or final-lap boss boundary takes precedence before focused card dispatch; isolated legacy definitions retain historical threshold precedence. Only after progression permits dispatch does `CardSystem` validate and resolve the exact selected lap/block record, publish it into current-lap history, and dispatch the authored fight/shop/elite/transit effect once. Completion marks the same stable card/location as completed before opening the next PLAN. Card effects never write Night Pressure: Arcade and Gang Hideout use existing encounter gains, Convenience Store uses existing finite Heat cooling only, and Subway Entrance omits one baseline encounter without subtracting accrued Pressure. None can change a lap-decision token, clear final-lap commitment, skip block-nine boss progression, or override safe-boundary precedence.

`GameHUD` renders only snapshots and forwards typed intent. The native 1280×720 focused panel shows up to two large authored locations (or one when the finite lap deck is exhausted), exact block type, signed Heat, special rule, reward/risk, selected prediction, one confirmation, compact Next Block, and simple resolved history. Native Button focus/activation provides click, tap, and keyboard parity; production cards are not drag sources. The mandatory layer has no close/decline route, and Help/tutorial banners cannot obscure it. Hand/draw/discard capacity, supplemental card rewards, future-slot validity, five route targets, and route dots are absent from the release interaction while historical controls remain available to isolated legacy fixtures.

## Equipment, statuses, and synergy ownership

`EquipmentDefinition`, `EquipmentModifierDefinition`, `TriggeredEffectDefinition`, and `StatusEffectDefinition` are typed Resources. `EquipmentCatalogue` validates and returns the nine definitions in stable content-ID order. Tunable values live in `.tres` content; UI and combat do not own item tuning. `EquipmentDefinition.icon` and `SynergyDefinition.badge` are presentation references used by the HUD; the nine generated item icons and three synergy badges are deliberately replaceable placeholders and do not participate in gameplay validation, aggregation, or deterministic selection. `SynergyDefinition` and `SynergyCatalogue` define tag thresholds and derived modifiers without item-specific checks.

`SynergySystem` owns exactly three generic ordered active slots plus exactly three ordered backpack slots. Only active slots feed build aggregation; stored items remain owned but add no tags, modifiers, triggered effects, new triggered status applications, or synergy progress. A status already applied to an actor remains actor-owned and expires normally after later inventory changes. Duplicate stable-ID ownership is rejected across all six positions. Reward acquisition can store directly or equip into a chosen slot; when an active item is displaced it moves to the first empty backpack position or the exact player-selected position. If all six positions are occupied, mutation requires an explicit confirmation for the exact stored item left behind. No oldest-item policy or silent eviction exists.

M4.2 makes the one-backpack model explicit in presentation without changing this authority. `EquipmentDragPayload` is a typed, non-authoritative value carrying its inventory/reward origin, stable equipment ID, source or choice position, inventory revision, encounter identity where applicable, display name, and presentation icon. `EquipmentDragSlot` is a typed `Button` specialization using Godot's built-in `Control._get_drag_data()`, `_can_drop_data()`, `_drop_data()`, and off-tree drag-preview APIs. When a Web or touch motion path does not enter `_get_drag_data()`, typed mouse/touch input arms at press and crosses an 8-pixel threshold before calling Godot `force_drag()` with the same payload and preview. Touch arming retains the first pointer index, so a second touch cannot steal or start that drag. This is only an input-compatibility route into the same native drag transaction: it emits no inventory authority request and cannot bypass staging or Confirm. Target acceptance is a pure presentation check; authoritative validation still occurs when the staged request is confirmed.

Owned-item dragging is deliberately cross-area and non-destructive. Active-to-empty-backpack stages a move, while any occupied active/backpack cross-area drop stages an atomic swap so both items stay owned. Same-area drops are not reorder operations and reject without mutation. Reward-to-active or reward-to-backpack dragging stages the existing exact choice/destination/leave-behind flow; it does not bypass the revisioned reward token or Confirm action. Stale revisions, wrong identities, invalid origin/target combinations, combat-locked management, and drops outside a valid target all reject or snap back without changing ownership. Destructive removal remains available only through the separate named discard confirmation. Click/tap/keyboard destination selection remains the accessibility and non-drag fallback.

Between encounters, revisioned atomic operations move an active item to storage, swap a stored item with an active item, or discard the exact named active/stored item after confirmation. Inspection remains available during combat, but management mutation is allowed only in `INTRO`, `PATROLLING`, `SHOP`, and `EXTRACTION_AVAILABLE`. Every transaction validates the snapshot revision, identities, destination, replacement confirmation, catalogue membership, and unique ownership; stale or incomplete requests reject without side effects. Successful active-slot changes synchronously rebuild tags, modifiers, triggered effects, and thresholds and emit only real activation/deactivation edges. Backpack-only changes publish inventory state without altering the build. Restart clears all six positions, derived state, and old confirmation revisions.

Tag counts are accumulated in stable slot/content order. Modifiers are aggregated by stable modifier ID and operation; triggered effects are sorted by stable effect ID. Synergy thresholds are evaluated from data, so additional 2/4/6 definitions require content rather than equipment-ID branches. Knockback 2, Bleed 2, and Tech 2 are the only authored Milestone 4 thresholds. Their exact catalogue, tuning, and combination counts are recorded in `CONTENT_CATALOG.md`.

Choice previews clone the three active slots into a non-mutating candidate evaluation. They report current and prospective counts, immediate activations, deactivations caused by active-slot replacement, and progress toward every inactive primary threshold. The reward modal separately names the active destination, outgoing active item, backpack destination, and any exact stored item that would be left behind. The same aggregation/evaluation path powers previews and authoritative active changes. `GameHUD` forwards the chosen equipment index, destination positions, replacement confirmation, and inventory revision; it never equips directly. **Keep Current Build** clears the pending equipment choice while still granting the paired standard reward.

Bleed is actor-owned: base maximum three stacks, four-second duration, one-second ticks, and two damage per stack per tick. Bleed 2 adds two maximum stacks and +20% crew damage against bleeding enemies; Serrated Wraps independently add one cap, +15% such damage, and one typed 35% on-hit four-second Bleed application. Shock is a non-damaging actor-owned one-stack marker with a three-second base duration and data-driven +25% damage taken from Environment interventions only. Shock Gloves apply it at 25%; Hacker Deck and Tech 2 each add 1.5 seconds. Wet remains mechanics-neutral. Status timers/effects and rate-limited presentation callouts clear on actor/run cleanup.

Each selectable crew definition supplies exactly one existing accessible starter item, resolving the specification's run-entry requirement without a tenth item or permanent bonus: Jax starts with Spiked Bat, Zoey with Shock Gloves, and Rex with Reinforced Jacket. `RunFlowController` installs the selected definition's item immediately after resetting `SynergySystem`; subsequent equipment and backpack rules are unchanged.

### WP04 consequence snapshots and feedback

`BuildConsequenceEvaluator` is a pure `RefCounted` translator. It receives exact before/after modifier/effect snapshots from `SynergySystem`, the selected crew/attack definitions, and existing intervention cooldown definitions; it returns player-facing maximum health, movement, full attack cycle, primary hit, knockback, Hydrant/Backup cooldown, Environment modifiers, Bleed cap/condition, Shock duration, received knockback, and proc changes. It owns no state and UI never supplies a gameplay result.

Equipment offers use a positive monotonic token owned by `RewardDirector` in addition to encounter identity and inventory revision. `SynergySystem` previews every active destination, exact outgoing-backpack target, storage destination, and staged inventory move/swap/discard without mutation. The HUD presents only the selected candidate/destination in the owner-carried single 1→2→3 decision layer, including final active/backpack lists and exact paired standard reward.

`NeonBuildCallout` is a non-authoritative icon-plus-label surface. `GameRun` maps resolved `status_applied`, environmental collision, Tech intervention, synergy edge, and encounter-entry snapshots into rate-limited presentation. Duplicate procs aggregate for 900ms; non-combat state synchronously clears the surface. No callout schedules gameplay or consumes a stream.

## Boss, combo, cadence, and summary ownership

`viper_showdown` is a separate boss-only encounter begun after block nine in the committed final lap and the authored 2.5-second intro. The Viper owns no run outcome: its 1,800-health actor exposes typed melee, charge, area, summon, and enrage events through combat; `RunEncounterController` reports the one boss defeat; `RunFlowController` asks `RunDirector` for victory. The dedicated overlay health bar, named warnings, ground markers, enraged text, boss music layer, and two-second victory presentation observe those events. Reduced knockback, light-stagger armour, capped stun, and a two-second control lockout protect against permanent control without a blanket invulnerability branch.

`ComboTracker` observes successful crew and environmental hits only. It expires after 2.5 eligible active seconds, accepts contributions from all crew/environmental sources, stores the run's highest value, and emits visual milestones at 10/20/30/50. Combo never changes damage, rewards, Heat, Night Pressure, encounter selection, or random streams.

`RunCadenceTracker` is measurement-only. With `wp02_cadence`, it timestamps coin-cluster presentation as ambient, accepted meaningful block completion as strategic, and accepted lap decisions/boss commitment as major, all against `RunDirector.run_elapsed_seconds`. Target bands are 10–20, 45–90, and 120–180 eligible seconds. The non-boss encounters' 3.0-second entry beat and 12.0-second staged actor interval are authored content pacing intended to space potential rewarding defeats; actual gaps still depend on deterministic roster choices and combat duration. The tracker explicitly rejects any coin-labelled event as strategic, never schedules content, and does not count pause/modal/introduction time because that clock does not advance. Empirical fight/block/lap distributions and 8–12-minute boss-run acceptance remain owner-playtest work and cannot be inferred from the observer.

`RunSummaryRecord` is assembled once from `RunDirector`, district lifecycle, encounter, reward, combo, equipment, and synergy authorities after unresolved clusters settle at full base value. It records result, completed laps/blocks, boss commitment, final stable lap/block IDs, accepted decision trail, duration, seed/schema, maximum Heat, final Night Pressure, encounters, enemies/elites, boss result, coins, manual clusters/maximum streak, scrap, highest combo, equipment build, and active synergies. `VerticalSliceOverlay` adds Restart Run and Return to Main Menu controls; it cannot change the record.

## Settings, persistence, and unlock ownership

Milestone 6 uses the two specification-authorized non-gameplay Autoloads:

- `SaveService` (`ProfileSaveService`) owns atomic JSON read/write/reset at `user://neon_loop_profile_v1.json`, save version 1, missing/default status, corrupt/IO recovery to safe defaults, future-version read-only handling, and `.tmp`/`.bak` replacement files. Active runs are never serialized.
- `AppState` (`NeonAppState`) owns the loaded profile, settings updates, idempotent completed-run unlock application, lifetime counts, development full-catalogue access, and typed persistence feedback. It owns no run state, Heat, Night Pressure, seed, stream, actor, reward, route, or outcome authority.

WP02 production access exposes Jax, Zoey, and Rex, the eight existing equipment items other than Hacker Deck, and the three existing cards other than Gang Hideout. The serialized version-1 Jax default and any historical Zoey/Rex facts remain loadable and are not invented, deleted, or rewritten on load. The Zoey/Rex rules remain stable historical definitions but are excluded from new grants; Hacker Deck after an elite defeat and Gang Hideout after extraction remain active idempotent breadth rules. Debug/test profiles expose all three crew, all nine equipment items, and all four cards without modifying stored unlock arrays. No unlock grants actor statistics, currency, run modifiers, or a new catalogue entry.

`GameSettingsData` owns sanitized 0–1 Master/Music/SFX volume, fullscreen/windowed, screen-shake intensity, damage-number visibility, hit-flash reduction, and pause-on-focus-loss values. `ApplicationSettingsController` applies only presentation/audio/display state and forwards focus intent; `RunDirector` remains pause authority. `VerticalSliceOverlay` presents values and save feedback. Missing optional fields take typed defaults and out-of-range numeric values clamp; a future-version profile loads a sanitized read-only projection and cannot be overwritten.

`TutorialPromptController` owns seven stable-ID, once-per-run, nonmodal contextual prompts for run controls, coins, interventions, equipment, cards, extraction, and boss warnings. It queues stable/priority-ordered definitions, never pauses play, and clears on run end/restart. The overlay only presents or dismisses the active prompt.

## Dependency direction

```text
Player input
    -> GameHUD / VerticalSliceOverlay / FireHydrant / DebugOverlay (presentation and intent)
    -> GameRun wiring (typed signal connections)
    -> run-scoped systems (authority)
    -> stage/actor presentation (results)

Completed summary -> AppState -> SaveService (versioned profile only)
Saved settings -> ApplicationSettingsController -> audio/display/effect presentation
```

Presentation may observe authoritative state, but authoritative gameplay code must not depend on concrete HUD controls. Stage containers host actors, but the stage does not implement actor behavior. Persistent services may filter available content before run initialization and record a completed summary afterward; they cannot mutate an active run.

## Autoload policy

Milestone 6 adds exactly the two Autoload roles allowed by `GameSpecifications.md`: `SaveService` for versioned persistent JSON and `AppState` for the loaded profile/settings/content-access policy. They are non-gameplay application services. The active run is never managed as a singleton, `RunDirector` remains the only run-state/Heat/Night Pressure/outcome authority, and `RunRandomStreams` remains owned by its scene-scoped `RunDirector`.

The existing `_mcp_game_helper` entry and live Godot-AI working-tree update belong to owner-carried development tooling. Historical snapshots remain 3.0.5/17 files for M6, 3.1.5/57 paths at WP04 start, and 66 dirty addon paths at WP05 finalization. WP04/WP05 neither removes nor converts the plugin into gameplay authority.

## WP05 selected intervention boundary

- `EnvironmentController` owns the encounter-authored Hydrant/Power Box context, exact caller revision/token, shared eligible-time cooldown, and immutable rejection. Existing `FireHydrantController` still owns Hydrant effect resolution.
- `FocusController` observes `CombatDirector`'s stable live-intent projection, revalidates the exact target/attack/revision/token and cutoff, and applies temporary priority only through existing automatic targeting methods.
- `CallBackupController` retains its finite two-ally transaction and now validates the exact published caller revision/token. UI owns no charge, cooldown, ally, or effect result.
- `RunFlowController` supplies the selected encounter's Environment ID and clears it at safe noncombat/terminal boundaries; pause preserves identity while invalidating the caller context.
- `GameHUD` exposes exactly Environment / Focus / Backup in combat and forwards snapshots through typed signals. Subway remains a strategic travel control.
- `WP05PrototypeRuntime`, definitions, telemetry, and screenshots remain isolated Part A evidence. Rally/Hanging Sign and the former GameRun enable/freeze seams are absent from release composition.

## Deferred architecture

WP06 is owner-accepted for publication as the current release boundary on 2026-08-30; exact commit/Pages provenance follows deployment. WP07 remains unauthorized. The following remain intentionally absent and unauthorized unless a later explicit owner decision changes the specification:

- Procedural route generation, additional districts/cards, a card currency/shop/economy, or broader production shop content
- Additional crew, enemy, elite, boss, intervention, equipment, synergy, or status content beyond the specified vertical-slice catalogues
- Multiplayer, controller support, localization, achievements, daily scheduling/rewards, leaderboards, replay infrastructure, or mid-run saving
- Advanced meta-progression, permanent statistical bonuses/trees, or a larger unlock graph
- Equipment selling, salvage, buyback, auto-sell/auto-salvage, rarity, uniques, affixes, sets, category-locked slots, or a broader equipment economy

No unbounded post-Milestone-6 expansion is authorized. The approved rebaseline is an experience restructuring using the bounded work-package roadmap; permitted future breadth categories are not pre-authorized content. These boundaries may be changed only by a later explicit owner request and specification/architecture update.

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

Local Windows and Web exports completed successfully. The Windows executable passed headless and hidden-window startup smoke checks. The locally served Web build rendered the live Milestone 3 HUD, unlocked audio from one gesture, toggled Help, entered/exited fullscreen, and reported no browser-console warnings or errors. Evidence is stored at `res://docs/screenshots/milestone_3_complete_run_structure.png`. No GitHub Pages publication or deployment was performed as part of that technical-verification pass; Milestone 3 was subsequently committed/deployed from `725cd373e2732b0dd6967a24a16e717e21ef8487` and later superseded by the published M4–M4.2 build.

The Milestone 3 boss scope ends at deterministic latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE` transition behavior. Final-boss actor/content and a production victory encounter remain later content work. District cards, general shops, saving/progression, and all other Milestone 5+ behavior were deliberately unimplemented at that historical milestone; District Cards are now implemented by M5 without broadening the other boundaries.

## Equipment and Synergies verification

Milestone 4 technical verification is complete. Nine discoverable suites passed **106/106 tests and 1,306 assertions with no failures or skips**. This preserves all **75/75 Milestone 1–3 tests and 1,100 assertions** and adds 31 Milestone 4 tests with 206 assertions covering the nine-definition catalogue, Resource validation, three slots, rejection/replacement/removal, stable aggregation, immediate threshold evaluation/signals, every two-item matrix, bridge behavior, deterministic choices/stream isolation, previews, exactly-once selection, UI bounds/input, combat modifiers/statuses, and restart cleanup.

Godot 4.7 launched the configured `/GameRun` composition without task-introduced parser/runtime warnings or errors. Normal reward clicks acquired, replaced, and removed equipment. Live Knockback, Bleed, and Tech builds changed displacement/environmental damage, status stacks/conditional damage, and Shock/intervention timing respectively. Equipment changes did not mutate Heat or Night Pressure; Tech cooldown scaling retained finite cooling/intervention rules. Extraction, defeat, and boss-threshold flows remained valid with equipment active, and same-seed restart cleared slots, tags, modifiers, statuses, pending reward state, and all named-stream draw counts.

Fresh local release Windows and Web exports completed successfully. The Windows executable passed a headless startup smoke check. The locally served Web build rendered the 640 x 360 equipment UI, accepted one sound-unlock gesture, and applied an equipment reward with one ordinary click/tap path; the browser console contained no warnings or errors. Evidence is stored at `res://docs/screenshots/milestone_4_equipment_synergies.png`. Embedded-runner fullscreen could only report Godot's informational “Windowed mode” limitation; the existing exported/browser fullscreen controls and delivery paths remain unchanged. No GitHub Pages publication or deployment was performed during that verification pass; M4, M4.1, and M4.2 were subsequently committed to `main`, pushed, and published together from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`.

## Milestone 4.1 usability/readability correction verification

Milestone 4.1 technical verification is complete. Eleven discoverable suites passed **132/132 tests and 1,584 assertions with no failures or skips**. This preserves all **75/75 Milestone 1–3 tests and 1,100 assertions**, retains the 31 Milestone 4 tests, and adds 26 correction-specific tests with 249 assertions for finite storage, active-only aggregation, safe revisioned transactions, exactly-once reward resolution, inspection-only clicks, modal layering, native-resolution typography/containment, journey guidance, and all twelve placeholder visuals.

Godot 4.7 launched the configured main scene directly into `/GameRun` at a native 1280 x 720 presentation viewport with the established logical world framing. Real pointer input selected a reward without mutation, selected a destination, applied exactly once only after Confirm, opened inventory inspection without mutation, and staged/cancelled a named discard without losing the item. Help, Hydrant rejection, sound unlock, fullscreen, and the preserved `F1`/`F2` handlers were checked; fresh cursor-bounded editor/game logs contained no task-introduced warnings or errors. Updated evidence is stored at `res://docs/screenshots/milestone_4_1_inventory_readability.png`.

Fresh local release Windows and Web exports succeeded. Windows passed a 180-frame headless startup smoke. The locally served Web build rendered the sharp 1280 x 720 UI, unlocked sound, completed the one-confirm equipment flow, preserved an item through discard cancellation, exercised Help/fullscreen/Hydrant input, and reported no browser-console warnings or errors. The portable headless export editor printed an ObjectDB-profiler `user://` directory message after successful export; it did not occur in the exported Windows runtime or Web console. Browser automation did not deliver `F1` to the Web canvas, so Web-specific F1 delivery was not re-claimed; the unchanged runtime handler and preserved automated coverage passed. No publication or deployment was performed during that correction pass; it was later included in the M4–M4.2 publication from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`. At that time this follow-up changed no Milestone 0–4 acceptance result and did not authorize a Milestone 5 system; the owner subsequently authorized M5 separately.

## Milestone 4.2 inventory drag/backpack-clarity verification

M4.2 technical verification is complete. Twelve discoverable suites passed **145/145 tests and 1,709 assertions with no failures or skips**. This preserves the full **132/132-test, 1,584-assertion Milestone 1–4.1 result** and adds 13 focused M4.2 tests/125 assertions covering one-backpack terminology, typed drag payload identity/revision data, all three active and backpack destinations, combat lockout, staged active-to-empty storage, occupied cross-area swaps, reward dragging to active/backpack slot 3, exact full-inventory leave-behind or Skip Gear behavior, exactly-once confirmation, and stale/same-area rejection without mutation. Twenty dynamic-fit assertions use the longest catalogue item name across all six reward destination controls, all six inventory action-target states, and key two-line prompts; seven assertions prove the 8-pixel pointer threshold starts native drag without mutation; five prove touch thresholding preserves the first armed pointer against a second touch.

Godot 4.7 opened the configured main scene directly into `/GameRun`. A real `InputEvent` pointer drag moved Magnetic Flail from active slot 3 toward empty backpack slot 3: the drop staged `move_to_backpack`, left inventory revision 6 unchanged, and named the no-loss consequence; the separate Confirm applied exactly once at revision 7, and a repeated invocation left revision 7 unchanged. The 1280 x 720 HUD showed one backpack, all third-slot targets, and no visible overflow or border crossing. Evidence: `res://docs/screenshots/milestone_4_2_inventory_drag.png`.

Fresh cursor-bounded editor logs contained no new line, warning, or error; the game log contained only development-helper registration. Fresh Windows and Web exports both completed with exit code 0 and no export warning/error. The Windows headless smoke exited 0, loaded `game_run.tscn` plus the M4.2 scripts/Resources, produced empty stderr, and reported no diagnostic. The final locally served Web build rendered at 1280 x 720, unlocked sound with one ordinary click, staged Hacker Deck reward→active slot 3 through real pointer drag without pre-Confirm mutation, and applied it with one ordinary Confirm click. A second real pointer drag staged active slot 3→empty backpack slot 3 with the named no-loss consequence; one Confirm left active slot 3 empty and backpack slot 3 holding Hacker Deck. Compact ASCII copy showed no glyph boxes, overflow, or border crossing, and the final browser warning/error console was empty. At M4.2 completion, selling, salvage, rarity, uniques, set items, category slots, and every Milestone 5+ system remained unimplemented, and no publication/deployment was performed by that correction pass. M4–M4.2 was subsequently committed to `main`, pushed, and published from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`; District Cards were later authorized and implemented separately in M5.

## District Cards verification

Milestone 5 technical verification is complete. Fifteen discoverable suites passed **188/188 tests and 2,450 assertions with no failures or skips**, preserving the accepted **145-test/1,709-assertion Milestone 1–4.2 baseline** and adding 43 M5 tests/741 assertions: card system 13/307, card UI 15/214, and route effects 15/220. The matrix covers typed resource validation, finite pile state, deterministic selection and stream isolation, immutable rejections, exactly-once placement/acquisition/resolution, all four effects, safe-state planning and pause ownership, authority-driven modal cleanup, progression precedence, route/minimap snapshots, input regressions, and restart cleanup.

Godot 4.7 launched the configured main scene directly into `/GameRun`. The configured and locally served Web passes observed the deterministic opening hand, the supplemental baseline-encounter card reward, safe planning, immediate wrong-type/occupied/outside feedback, return without mutation, a real pointer drag, click fallback, exactly-once Heat and discard changes, stable future/current/past route identities, pending/resolved preview state, Gang Hideout's scaled `viper_signal` placeholder plus guaranteed equipment, Arcade's created fight/reward path, Hydrant use, and boss precedence while Convenience Store remained pending. A clean Web reload returned Heat, route-card state, piles, equipment, and presentation to a fresh run. Current/past/expired slots are history-only snapshots rather than mutable targets, so their rejection behavior is asserted through the authoritative composed suites.

Fresh release Windows and Web exports completed with exit code 0. The exported Windows runtime startup smoke exited 0 with no diagnostic. The local 1280 x 720 Web build unlocked sound, remained within panel borders, and ended with an empty browser warning/error console. Evidence: `res://docs/screenshots/milestone_5_district_cards.png`.

Remaining M5 limits are intentional: the four icons are replaceable placeholders; the route overlay is the fixed authored route with a rolling five-future-occurrence window and separate history, not procedural generation; the four-card one-copy deck has capacity three and no reshuffle, currency, or economy; and reproduction is bounded to the same supported build, content revision, schema, seed, decisions, and authoritative timing. Milestone 5 was subsequently merged through PR #4 and published from `main` commit `da934897cbdee44cb4d1a44b25e91b458558bfbc`. Milestone 6 replaces only the former `viper_signal` actor placeholder with the specified Viper Enforcer and adds the bounded profile gate around the same four-card catalogue.

## Vertical-Slice Content and Presentation verification

Milestone 6 implementation is present on `codex/milestone-6-vertical-slice`. Godot 4.7 passed **244/244 cumulative tests and 3,234 assertions with no failures or skips across 22 suites**, and a configured headless boot opened `/GameRun` without parser/runtime warnings, errors, or leaks. The cumulative single-process harness nevertheless emitted 48 ObjectDB-instance and four resource-in-use shutdown diagnostics; because the configured production boot did not reproduce them, harness cleanup is retained as a diagnostic TODO rather than hidden.

A fixed-seed Rex/starter-only technical probe naturally reached Defeated at 589.517 eligible seconds (9m49.5s), after reaching the boss at 584.983 seconds. Pages run 29960250903 subsequently completed the official Godot 4.7 Web export/deploy; the live page exposed a visible 1280×720 canvas and no warning/error console entry. It did not establish representative Victory/Extraction, real-input browser flows, per-gap cadence acceptance, boss readability, crew feel, tutorial comprehension, three-build viability, Windows export/runtime, visual evidence, or any owner qualitative result. Those checks are delegated to `MILESTONE_6_PLAYTEST.md` and `TEST_PLAN.md`; this record invents no pass.

## WP01–WP04 verification

WP01 passed **254/254 tests and 3,376 assertions** plus its configured runtime and inspected presentation matrix. WP02 then passed **4/4 focused authority tests with 173 assertions**, **27/27 affected tests with 495 assertions**, and **264/264 cumulative tests with 3,646 assertions**, all with zero failures or skips. Its fixed-seed composed timing gate reaches lap decisions at 121.267/292.683 eligible seconds and a boss result at 599.883 seconds. The aggregate single-process runner still reports the pre-existing post-success 48-ObjectDB/four-resource shutdown diagnostic; focused, affected, configured-runtime, long-form, release-export, exported-Windows, and browser runs do not reproduce it.

The configured `/GameRun` smoke exercised all three crew, PLAN/pause, shop, first Push, explicit final-lap commitment, block-nine boss/result, extraction, and cleanup. Twelve inspected WP02 captures cover the representative native states, safe area, Web integer scale, and final commitment. `docs/product/WP02_ACCEPTANCE_EVIDENCE.md` records that matrix; its owner-run comprehension gate remains pending.

WP03 adds **5/5 focused authority tests with 130 assertions**, **72/72 affected tests with 1,388 assertions**, and an isolated release-snapshot **274/274 cumulative result with 3,919 assertions across 27 suites**, all with zero failures or skips. Configured focused dispatch proves the live authored outcome of all four stable card IDs; native GUI routing proves keyboard and touch selection/confirmation. Its configured native smoke covers visible offer/prediction, exact confirmation/Heat, replay rejection, patrol occurrence, resolved history, natural one-choice block-three handling, next PLAN, and cleanup. Three 1280×720 captures were inspected. Windows/Web release exports and exported-Windows runtime passed. Commit `a6ef571942afb319b3e2c0cdd9c9cffcc1f1bc93` was pushed to `main`; Pages run 32586634393 deployed it successfully, and the live 1280×720 real-pointer selection/occurrence/history flow passed with an empty browser warning/error console. `docs/product/WP03_ACCEPTANCE_EVIDENCE.md` records the exact matrix, owner-authorized playtest publication, and still-pending owner-run unbriefed first-use gate; no qualitative pass is inferred.

WP04 adds **15/15 focused tests with 247 assertions**, **226/226 affected tests with 3,175 assertions**, and **291/291 cumulative tests with 4,192 assertions across 30 suites**, all with zero failures or skips. The configured smoke freezes exact reward token/replay, full inventory/Skip, shop purchase/stale/exit, proc feedback, cleanup, and four inspected 1280×720 states. Native GUI routing passes mouse, touch, keyboard, and shop context. Release Windows/Web exports share a 1,482,264-byte PCK; exported Windows exits 0. The local production Web build passes real-pointer plan, reward selection/Confirm, finite purchase/exit, 2560×1440 containment, and an empty warning/error console. The aggregate runner retains only the inherited 48-ObjectDB/four-resource shutdown diagnostic. `docs/product/WP04_ACCEPTANCE_EVIDENCE.md` records the exact local result and the still-pending human gate. The owner separately authorized this exact boundary for `main`/Pages publication on 2026-08-22.
