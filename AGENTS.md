# Neon Loop Agent Guide

This repository is a Godot 4.x project. `GameSpecifications.md` is the product source of truth. Read it in full before changing gameplay, scenes, project settings, architecture, or content.

## Canonical specification path and casing

- The tracked canonical specification is `GameSpecifications.md`, with that exact casing.
- A task brief that says `gamespecifications.md`, `gamespec.md`, or uses another casing is referring to the tracked `GameSpecifications.md`; it does not identify a second specification.
- On case-sensitive filesystems, always open and link the exact tracked filename. Do not create a lowercase alias, rename the canonical file, or attempt to reconcile the mismatch by copying or rewriting the specification.

## Required reading order

1. `GameSpecifications.md`
2. `AGENTS.md`
3. `ARCHITECTURE.md`
4. `IMPLEMENTATION_PLAN.md`
5. The files owned by the requested task

If documentation and implementation disagree with the specification, stop and resolve the conflict instead of silently inventing behavior.

## Current verified state

The currently implemented and technically verified scope is **Milestone 4.2 — Inventory drag and backpack clarity correction** on top of completed **Milestone 4.1 — Equipment usability and HUD readability correction** and **Milestone 4 — Equipment and Synergies**. It preserves all Milestone 0–4.1 behavior and includes:

- Exactly nine typed stable-ID equipment Resources, three generic ordered active slots, and one clearly named backpack with three ordered inactive slots
- Acquisition, explicit replacement/storage/removal, duplicate/invalid rejection, revisioned inventory transactions, and synchronous clean restart
- Stable deterministic equipment tag, modifier, and triggered-effect aggregation
- Data-driven Knockback 2, Bleed 2, and Tech 2 thresholds with immediate typed activation/deactivation events
- Actor-owned Bleed/Shock status behavior and shared combat modifier/effect application
- Deterministic equipment reward choices using only the `equipment` stream after stable-ID filtering/sorting
- Immediate-activation, alternative-path, and full-slot replacement previews
- A native 1280 x 720 equipment/synergy HUD over the preserved logical 640 x 360 world, with 16-pixel-minimum typography, item/synergy visuals, journey guidance, unambiguous active-versus-backpack language, bounded two-line prompts, compact action-target labels, and longest-name pixel-fit coverage across all reward/inventory destinations
- Typed built-in `Control` drag payloads and targets for owned equipment and reward choices, plus an 8-pixel typed mouse/touch threshold fallback into Godot `force_drag`; the first armed touch cannot be stolen by a second touch, cross-area drops stage a lossless move or swap and still require Confirm, and click/tap/keyboard destination selection remains available
- Explicit full-inventory replacement consequences and **Skip Gear** behavior that declines the new equipment without losing the paired run reward; destructive discard remains a separate named confirmation
- Six Knockback, three Bleed, and six Tech valid two-item pairs plus three cross-primary bridge items
- Three visibly distinct live builds and clean extraction/defeat/boss/restart behavior with equipment active
- Preserved complete run lifecycle, Heat/Night Pressure separation, finite cooling, deterministic streams, automatic combat, coins, Fire Hydrant, Help, sound unlock, fullscreen, `F1`, and `F2`

Technical verification on Godot 4.7 passed **145/145 tests and 1,709 assertions with no failures or skips** across 12 suites. This preserves all 132 Milestone 1–4.1 tests/1,584 assertions and adds 13 dedicated Milestone 4.2 tests/125 assertions. Configured `/GameRun` pointer drag, fresh logs, 1280 x 720 containment, Windows export/runtime smoke, and final local Web reward/inventory drag plus browser-console checks all passed.

Milestone 3 was committed to and deployed from `main` at `725cd373e2732b0dd6967a24a16e717e21ef8487`. The GitHub Pages build is available at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/). The deployed build rendered the live Milestone 3 HUD, accepted the sound-unlock gesture, and produced no Web-console warnings or errors during the deployment smoke check.

The Milestone 3 boss scope ends at threshold latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE`. Final-boss actor behavior, encounter content, art, audio, and the production victory path belong to later work.

## Next authorized scope

No Milestone 5 or later gameplay/content scope is authorized. Do not begin Milestone 5 District Cards, Milestone 6 content/presentation, final-boss content, broad progression or persistence, procedural generation, or any other later system without separate explicit authorization. Listing future content in documentation is not authorization to implement it.

The Milestone 4–4.2 implementation, local exports, and evidence have not been committed, pushed, merged, published, or deployed. Do not perform those actions without a new owner request.

## Historical Milestone 1 Human Validation Gate

Technical Milestone 1 is complete. On 2026-07-18, the project owner recorded the five-person Human Validation Gate as **PASSED** from the owner's aggregate playtest record. This is an owner qualitative decision, not an automated-test, coding-agent, or implementation-team verification result. Do not repeat, reinterpret, or reopen this decision.

The fixed procedure from `GameSpecifications.md` section 44 was:

1. The project owner recruited at least five people who were not involved in implementation.
2. The owner designated a five-person scored cohort before observation; additional testers could not replace a failed scored observation.
3. Each tester received only: “Watch this fight and tell me when you feel ready to stop.”
4. The intended build systems, future features, and desired conclusions were not explained beforehand.
5. The owner recorded observation duration and concise, unattributed notes for each tester.
6. Coin clicking could occur if discovered naturally, but coin-cluster engagement was not evidence that passive combat itself was entertaining.

The owner's passing record states that all five designated testers voluntarily played for more than two minutes, expressed curiosity about future content, found combat relationships readable, identified satisfying hits and sounds, and did not broadly describe combat as confusing, lifeless, or difficult to follow. Only the project owner may change this qualitative record.

## Engineering rules

- Use typed GDScript for all project scripts. Type parameters, return values, properties, constants, signals, and local variables when their type is not already unambiguous.
- Prefer small composed nodes and scenes over deep inheritance trees.
- Keep gameplay state and calculations out of UI scenes. UI may present values and forward player intent; it must not become an authority.
- Keep scene responsibilities narrow. `GameRun` composes systems; `DowntownLoop` owns stage presentation; `GameHUD` owns presentation; `DebugOverlay` owns development presentation and debug requests.
- Use typed signals or explicit typed methods for cross-system communication. Do not introduce an untyped global event bus.
- Do not add gameplay Autoloads without an architectural decision and specification-backed need. `_mcp_game_helper` is Godot MCP development tooling, not a Neon Loop gameplay Autoload.
- Put tunable gameplay content in custom Resources rather than hard-coded UI or unrelated systems.
- Preserve working behavior and existing assets. Do not rewrite `GameSpecifications.md`.
- Placeholder visuals must remain clearly temporary, visually distinct, and replaceable without changing gameplay ownership.
- Preserve deterministic stable ordering.
- Do not suppress parser errors, runtime errors, warnings, skipped tests, or failing tests to make a check appear clean.

## Deterministic gameplay randomness

Milestone 3 implements the deterministic randomness contract. All later gameplay must preserve it.

- `RunDirector` owns one authoritative integer run seed and a run-scoped `RunRandomStreams` child. `RunRandomStreams` is never an Autoload.
- The named streams are exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`.
- A gameplay system may consume only the stream appropriate to its responsibility. Milestone 4 equipment choices use `equipment`.
- Gameplay code must never call unseeded global randomness such as `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, or `Array.pick_random()`.
- Do not route all systems through one shared random sequence. Extra `cosmetic` draws must never change gameplay outcomes.
- Before a gameplay draw, filter candidates deterministically and sort them by stable content ID. Dictionary iteration order, scene-tree insertion order, Resource order, and presentation order are not selection contracts.
- Random schema version 1 uses `fnv1a32_utf8_v1`: FNV-1a 32-bit over the UTF-8 bytes of `neon-loop|schema:<version>|seed:<integer>|stream:<name>`, with unsigned 32-bit wrap after each multiply.
- Do not change `random_schema_version` unless derivation or draw semantics change incompatibly; document and test any schema change with locked vectors.
- Reproduction claims are limited to the same supported build, content revision, random-schema version, seed, gameplay decisions, and authoritative timing context.

## Current runtime ownership

- `RunDirector`: state graph, eligible time, Heat, Night Pressure, scaling, threshold latches/precedence, seed, outcomes, and summaries
- `RunRandomStreams`: seven isolated deterministic stream states and stable-ID selection
- `PatrolController`: route progression, safe boundaries, encounter pauses, and finite reroute movement
- `RunEncounterController`: encounter identity, deterministic spawning/lanes, scaling, caps, completion, and cleanup
- `RunCoolingController`: finite Subway and shop-cooling resources
- `RunFlowController`: typed coordination between run, patrol, encounter, reward, cooling, and presentation intent
- `CombatDirector`: actors, targeting, reservations, hits, equipment modifiers/effects, environmental effects, and combat cleanup
- `RewardDirector`: standard/equipment reward selection and application coordination, coin ledger, at-most-once clusters, and manual streak
- `FireHydrantController`: Hydrant validation, area resolution, rejection, and cooldown
- `DisplayController`: presentation-only fullscreen, landscape, and safe-area integration
- `CardSystem`: typed Milestone 5 authority shell only
- `SynergySystem`: three active equipment slots, one three-slot inactive backpack, unique ownership, revisioned inventory transactions, deterministic active-only aggregation, threshold state/signals, and non-mutating previews

The active run remains scene-scoped. No Neon Loop gameplay Autoload owns run state.

## Repository conventions

- Scenes: `res://scenes/<owner>/`
- Scripts: `res://scripts/<owner>/`
- Data Resources: `res://data/<content-type>/`
- Tests: `res://tests/unit/`, `res://tests/integration/`, and `res://tests/fixtures/`
- Architecture notes and decisions: `res://docs/`
- Use `snake_case` filenames and `PascalCase` class names.
- Prefer one primary owner per scene or script.

`res://scripts/stages/` is the narrow owner for fixed-stage presentation and debug-marker drawing scripts.

Primary run-system paths include:

- `res://scripts/run/run_director.gd`
- `res://scripts/run/run_random_streams.gd`
- `res://scripts/run/run_flow_controller.gd`
- `res://scripts/run/run_cooling_controller.gd`
- `res://scripts/patrol/patrol_controller.gd`
- `res://scripts/encounters/run_encounter_controller.gd`
- `res://scripts/combat/combat_director.gd`
- `res://scripts/rewards/reward_director.gd`
- `res://scripts/cards/card_system.gd`
- `res://scripts/synergies/synergy_system.gd`

Do not describe the implemented Milestone 3–4 directors as logic-free Milestone 0 shells. Only `CardSystem` remains a deferred responsibility shell.

## Verification requirements

Before declaring an implementation task complete:

1. Launch the project through Godot.
2. Confirm the configured main scene opens directly into `/GameRun`.
3. Exercise every input and interaction changed by the task.
4. Inspect fresh Godot output and debugger state.
5. Fix every task-introduced parser error, runtime error, warning, and failing test.
6. Record remaining warnings and limitations honestly.
7. Preserve all existing milestone tests and add deterministic coverage for new logic.
8. Update `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, `CONTENT_CATALOG.md`, and `CHANGELOG.md` when their owned facts change.
9. Capture visual evidence for visual acceptance criteria when tooling supports it.
10. Verify affected Windows and Web behavior in proportion to the change.

Milestone 4's executed matrix and preview record in `TEST_PLAN.md` is an acceptance contract for later changes. All nine catalogue entries must remain available to development/tests, each primary synergy must retain at least three valid two-item combinations, bridge choices must remain visible, and equipment selection/effect chances must use only the isolated `equipment` stream.

## Verification records

- **Milestone 0:** Godot 4.7 launched `/GameRun`; stage, HUD, `F1`, and `F2` checks passed. Evidence: `res://docs/screenshots/milestone_0_foundation.png`.
- **Milestone 1:** 30/30 tests and 348 assertions passed. The separate owner-recorded Human Validation Gate passed on 2026-07-18. Evidence: `res://docs/screenshots/milestone_1_combat_lab.png`.
- **Milestone 2:** 46/46 cumulative tests and 694 assertions passed. A 315.3046-second soak preserved the combat-safe region and exact reward accounting. Windows and Web checks were clean. Evidence: `res://docs/screenshots/milestone_2_player_intervention.png`.
- **Milestone 3:** 75/75 cumulative tests and 1,100 assertions passed with no failures or skips. Extraction, defeat, boss threshold, finite cooling, time eligibility, deterministic replay/isolation, and clean restart were exercised in the configured project plus local Windows and Web exports. Evidence: `res://docs/screenshots/milestone_3_complete_run_structure.png`.
- **Milestone 4:** 106/106 cumulative tests and 1,306 assertions passed with no failures or skips. Nine equipment definitions, three slots, aggregation, all three synergies/signals, choice determinism/previews/one-click input, three live builds, run endings, restart cleanup, and local Windows/Web exports were exercised. Evidence: `res://docs/screenshots/milestone_4_equipment_synergies.png`.
- **Milestone 4.1:** 132/132 cumulative tests and 1,584 assertions passed with no failures or skips. Three inactive backpack slots, safe staged acquisition and revisioned inventory management, inspection-only clicks, named discard confirmation, native 1280 x 720 readability, twelve placeholder visuals, configured-project real-pointer input, and fresh local Windows/Web exports were verified. Evidence: `res://docs/screenshots/milestone_4_1_inventory_readability.png`.
- **Milestone 4.2:** 145/145 cumulative tests and 1,709 assertions passed with no failures or skips across 12 suites. The 13 new tests/125 assertions verify one-backpack terminology, typed drag payloads and all three destinations, staged non-destructive move/swap behavior, reward-drag destination forwarding, exact full-inventory leave-behind/skip behavior, invalid/stale/combat-locked rejection, runtime pixel fit using the longest catalogue item name, the 8-pixel mouse/touch threshold fallback entering the same native drag transaction without mutation, and first-touch ownership under multi-touch input. Twenty dynamic-fit assertions cover all six reward destinations, all six inventory action-target states, and key two-line prompts; the pointer fallback has seven assertions and the touch/first-pointer test has five. Reward targets use compact `ACTIVE n` / `BACKPACK [n]` labels, inventory actions use compact `ACTIVE` / `STORE SLOT` / `SWAP SLOT` targets, Help states `CLICKS ONLY INSPECT; NEVER DISCARD`, and action labels use Web-safe ASCII wording. Configured Godot 4.7 opened `/GameRun`; a real pointer drag staged Magnetic Flail from active slot 3 to empty backpack slot 3 without mutation, then one Confirm changed revision 6→7 and a second invocation did nothing. Fresh logs were clean, the 1280 x 720 evidence showed no overflow, and fresh Windows export/runtime checks passed. The final local Web build unlocked sound, staged Hacker Deck reward→active slot 3 and active slot 3→empty backpack slot 3 through real pointer drags, applied each only after one ordinary Confirm click, showed no glyph boxes/overflow, and produced an empty warning/error console. Evidence: `res://docs/screenshots/milestone_4_2_inventory_drag.png`.

Milestone 5 and later test sections remain planned acceptance contracts until their systems are separately authorized, implemented, and executed.
