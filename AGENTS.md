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

## Current scope

The currently implemented scope is **Milestone 1 — Combat Lab**. The completed technical proof preserves Milestone 0 and adds:

- Resource-backed Jax and Street Punk actor scenes
- Typed composed actor state, health, attack timing, and presentation
- Three-lane automatic movement, target acquisition/invalidation, and attack-position reservations
- Deterministic damage, visible knockback, hit-stop, damage numbers, death, cleanup, and repeat spawning
- Fixed authored coin rewards with generous clusters, approximately 2.5-second full-value auto-collection, at-most-once click/timeout resolution, and a manual-only streak bonus capped at 10%
- Live Combat Lab HUD/debug presentation and sufficient placeholder audiovisual feedback for technical readability checks
- Deterministic Milestone 1 combat and reward tests

Technical Milestone 1 is complete. The owner-recorded five-person Human Validation Gate is still pending and **Milestone 2 remains blocked**. Do not implement Fire Hydrant behavior, Night Pressure runtime, deterministic random streams, equipment, synergies, cards, extraction, shops, saving, bosses, progression, procedural generation, or other later-milestone systems until their entry conditions and explicit tasks are satisfied.

## Engineering rules

- Use typed GDScript for all project scripts. Type parameters, return values, properties, constants, signals, and local variables when their type is not already unambiguous.
- Prefer small composed nodes and scenes over deep inheritance trees.
- Keep gameplay state and calculations out of UI scenes. UI may present values and forward player intent; it must not become the authority for run state.
- Keep scene responsibilities narrow. `GameRun` composes systems; `DowntownLoop` owns stage placeholders; `GameHUD` owns presentation; `DebugOverlay` owns development presentation and debug requests.
- Use signals or explicit typed methods for future cross-system communication. Do not introduce an untyped global event bus.
- Do not add gameplay Autoloads without an architectural decision and specification-backed need. `_mcp_game_helper` is existing Godot MCP development tooling, not a Neon Loop gameplay Autoload.
- Put future tunable gameplay content in custom Resources rather than hard-coded UI or unrelated systems.
- Preserve working project behavior and existing assets. Do not rewrite `GameSpecifications.md`.
- Placeholder visuals must be clearly temporary, visually distinct, and replaceable without changing gameplay ownership.
- Do not suppress parser errors, runtime errors, or warnings to make a check appear clean.

## Deterministic gameplay randomness

These rules apply when their owning later milestone is explicitly authorized. They do not authorize implementing random systems during the current Milestone 0 scope.

- `RunDirector` owns one authoritative integer run seed and a run-scoped `RunRandomStreams` component. `RunRandomStreams` is never an Autoload.
- The required named streams are exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. A gameplay system may consume only the stream appropriate to its responsibility.
- Gameplay code must never call unseeded global randomness such as `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, or `Array.pick_random()`.
- Do not route every system through one shared random sequence. Named streams must have isolated generator state, and extra `cosmetic` draws must never change gameplay outcomes.
- Before a gameplay draw, filter candidates deterministically and sort them by stable content ID. Dictionary iteration order, scene-tree insertion order, and presentation order must not determine an outcome.
- Sub-seed derivation must use a documented, versioned, platform-stable algorithm and `random_schema_version`; it must not use a process- or platform-unstable hash.
- Reproduction claims are limited to the same supported build, content revision, and random-schema version with the same seed, gameplay decisions, and authoritative timing context.

## Milestone progression gate

Milestone 2 is blocked until all technical Milestone 1 acceptance criteria pass and the project owner records a passing five-person human validation gate.

The gate procedure is fixed by `GameSpecifications.md` section 44:

1. The project owner recruits at least five people who were not involved in implementation.
2. The owner designates a five-person scored cohort before observation; additional testers are supplemental and cannot replace a failed scored observation.
3. Each tester receives only: “Watch this fight and tell me when you feel ready to stop.”
4. The intended build systems, future features, and desired conclusions are not explained beforehand.
5. The owner records observation duration and concise, unattributed notes for each tester.
6. Coin clicking may occur if discovered naturally, but coin-cluster engagement is not evidence that passive combat itself is entertaining.

The owner may record a pass only when all of these are true:

- At least four of five testers voluntarily watch for 60 seconds.
- At least three testers express curiosity about what happens next or request another encounter.
- Most testers can identify who is attacking whom.
- Most testers identify at least one satisfying hit, reaction, or combat moment.
- Combat is not broadly described as confusing, lifeless, or visually difficult to follow.

Only the project owner may record this gate as passed. Coding agents, automated tests, and implementation-team observations must not claim, infer, or mark a pass. If any criterion fails, Milestone 2 remains blocked and the complete gate must be repeated after the relevant Combat Lab improvements.

## Repository conventions

- Scenes: `res://scenes/<owner>/`
- Scripts: `res://scripts/<owner>/`
- Data Resources: `res://data/<content-type>/`
- Tests: `res://tests/unit/`, `res://tests/integration/`, and `res://tests/fixtures/`
- Architecture notes and decisions: `res://docs/`
- Use `snake_case` filenames and `PascalCase` class names.
- Prefer one primary owner per scene or script.

`res://scripts/stages/` is the narrow owner for the fixed stage's replaceable
presentation and debug-marker drawing scripts.

The Milestone 0 system shells live at:

- `res://scripts/run/run_director.gd`
- `res://scripts/patrol/patrol_controller.gd`
- `res://scripts/combat/combat_director.gd`
- `res://scripts/rewards/reward_director.gd`
- `res://scripts/cards/card_system.gd`
- `res://scripts/synergies/synergy_system.gd`

These classes intentionally contain no runtime gameplay behavior yet.

## Verification requirements

Before declaring an implementation task complete:

1. Launch the project through Godot.
2. Confirm the configured main scene opens directly.
3. Exercise every input or interaction changed by the task.
4. Inspect the Godot output and debugger.
5. Fix all parser and runtime errors introduced by the task.
6. Record remaining warnings or limitations honestly.
7. Update `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md` when test coverage changes, `CONTENT_CATALOG.md` when content changes, and `CHANGELOG.md`.
8. Capture visual evidence for visual acceptance criteria when tooling supports it.

For Milestone 0 specifically, verify the stage and HUD are visible, `F1` toggles the debug overlay, and the three lane guides can be hidden and shown with the overlay button or `F2`.

## Milestone 0 verification record

Milestone 0 passed its Godot 4.7 launch verification on 2026-07-16. The project launched to `/GameRun`; the stage and HUD were visible; repeated `F1` transitions worked; `F2` hid and restored the stage-owned lane markers while the overlay was hidden; and the game/editor logs were clean after relaunch. Visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.
