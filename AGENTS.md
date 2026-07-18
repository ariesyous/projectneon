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

The currently implemented and technically verified scope is **Milestone 3 — Complete Run Structure**. It preserves all Milestone 0–2 behavior and adds:

- `GameRun` as the configured run-scoped composition root
- An explicit `RunDirector` state graph covering initialization, introduction, patrol, encounters, rewards, shop, extraction, boss trigger, terminal results, summary, pause, and restart
- Authored patrol-route progression, deterministic encounter scheduling, safe transition boundaries, and encounter/global concurrency limits
- Tactical Heat clamped to 0–100 with exact tiers and immediate danger/reward effects
- Separate, irreversible Night Pressure driven only by eligible active time and exactly-once encounter completion
- Data-driven enemy health, damage, and deterministic round-half-up spawn-budget scaling
- Latched extraction thresholds, boss precedence, and unavoidable safe-boundary boss queueing
- Finite Subway Reroute charges and finite shop cooling that reduce Heat without changing Night Pressure or latched progression
- One authoritative integer run seed, optional supplied seeds, and a run-scoped `RunRandomStreams` child
- Seven isolated deterministic streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`
- Stable-ID candidate ordering, same-seed restart, known derivation vectors, and stream/cosmetic isolation
- Standard rewards, authoritative coin/scrap accounting, extraction, defeat, boss-trigger results, summaries, and clean restart
- Preserved automatic Jax/Street Punk combat, coin clusters, Fire Hydrant intervention, Help, audio unlock, fullscreen, mobile-landscape guidance, `F1`, and `F2`

Technical verification on Godot 4.7 passed **75/75 tests and 1,100 assertions with no failures or skips**. This preserves the complete Milestone 1–2 result of 46 tests/694 assertions and adds 29 Milestone 3 tests/406 assertions.

Milestone 3 was committed to and deployed from `main` at `725cd373e2732b0dd6967a24a16e717e21ef8487`. The GitHub Pages build is available at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/). The deployed build rendered the live Milestone 3 HUD, accepted the sound-unlock gesture, and produced no Web-console warnings or errors during the deployment smoke check.

The Milestone 3 boss scope ends at threshold latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE`. Final-boss actor behavior, encounter content, art, audio, and the production victory path belong to later work.

## Next authorized scope

The project owner has authorized **Milestone 4 — Equipment and Synergies** as the next development scope. It is authorized but not yet implemented.

Milestone 4 is limited to:

- At least nine data-driven equipment definitions, including Magnetic Flail, Voltaic Blade, and Chain Sneakers
- Three generic equipment slots
- Equipment acquisition, replacement, removal, reward choices, and UI
- Deterministic equipment modifier and tag aggregation
- Knockback 2, Bleed 2, and Tech 2 synergies
- Immediate recalculation plus typed activation/deactivation events
- Immediate-activation and alternative-build-path previews
- At least three visibly distinct builds
- At least three valid two-item combinations for each primary synergy
- At least two cross-primary bridge items

The `equipment` stream exists as Milestone 3 compatibility infrastructure and must own Milestone 4 equipment selection. The current `SynergySystem` is still a typed shell until Milestone 4 implements its specified authority.

Do not begin Milestone 5 District Cards, Milestone 6 content/presentation, final-boss content, broad progression or persistence, procedural generation, or any other later system without separate explicit authorization. Listing future content in documentation is not authorization to implement it.

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
- `CombatDirector`: actors, targeting, reservations, hits, environmental effects, and combat cleanup
- `RewardDirector`: standard reward selection/accounting, coin ledger, at-most-once clusters, and manual streak
- `FireHydrantController`: Hydrant validation, area resolution, rejection, and cooldown
- `DisplayController`: presentation-only fullscreen, landscape, and safe-area integration
- `CardSystem`: typed Milestone 5 authority shell only
- `SynergySystem`: typed Milestone 4 authority shell pending implementation

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

Do not describe the implemented Milestone 3 directors as logic-free Milestone 0 shells. Only `CardSystem` and the pre-Milestone-4 `SynergySystem` remain deferred responsibility shells.

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

For Milestone 4, use the planned matrix and preview coverage in `TEST_PLAN.md`. All nine catalogue entries must be available to development/tests, each primary synergy must retain at least three valid two-item combinations, bridge choices must remain visible, and equipment selection must use the isolated `equipment` stream.

## Verification records

- **Milestone 0:** Godot 4.7 launched `/GameRun`; stage, HUD, `F1`, and `F2` checks passed. Evidence: `res://docs/screenshots/milestone_0_foundation.png`.
- **Milestone 1:** 30/30 tests and 348 assertions passed. The separate owner-recorded Human Validation Gate passed on 2026-07-18. Evidence: `res://docs/screenshots/milestone_1_combat_lab.png`.
- **Milestone 2:** 46/46 cumulative tests and 694 assertions passed. A 315.3046-second soak preserved the combat-safe region and exact reward accounting. Windows and Web checks were clean. Evidence: `res://docs/screenshots/milestone_2_player_intervention.png`.
- **Milestone 3:** 75/75 cumulative tests and 1,100 assertions passed with no failures or skips. Extraction, defeat, boss threshold, finite cooling, time eligibility, deterministic replay/isolation, and clean restart were exercised in the configured project plus local Windows and Web exports. Evidence: `res://docs/screenshots/milestone_3_complete_run_structure.png`.

Milestone 4 and later test sections remain planned acceptance contracts until their systems are actually implemented and executed.
