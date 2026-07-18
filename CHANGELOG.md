# Changelog

All notable changes to Neon Loop are documented here. Dates use the local project working date.

## [Unreleased]

### 2026-07-17 — Browser Playtest Release

#### Added

- A Godot 4.7 Web export preset with browser threads disabled for ordinary GitHub Pages hosting.
- A GitHub Actions workflow that downloads the official Godot 4.7 editor and export templates, builds the web release from source, and deploys it through GitHub Pages.
- Public playtest and repository links in `README.md`, which now reflects the implemented Milestone 1 scope.

#### Scope

- Browser packaging changes distribution only; it adds no Milestone 2 gameplay or new gameplay authority.

#### Verification

- Exported the release locally with the official Godot 4.7 Web templates and loaded it through an HTTP server in the in-app browser.
- Confirmed automatic combat, five-enemy presentation, coin spawning and auto-collection, and the enlarged HUD with no browser-console warnings or errors.

### 2026-07-17 — HUD Readability Refinement

#### Changed

- Enlarged critical HUD typography, the timer, Jax portrait and health meter, placeholder buttons, panel borders, and the opt-in development overlay in response to playtest readability feedback.
- Shortened presentation-only copy for actor state, coin resolution, and deferred HUD regions so the larger type remains contained without adding later-milestone behavior or covering the five-enemy fight.
- Kept the existing 640 x 360 internal canvas and 1280 x 720 integer-scaled desktop window; no global HUD transform or gameplay authority was introduced.

#### Verification

- Passed all 30 discoverable Milestone 1 tests after the presentation changes.
- Launched directly into `GameRun`, visually inspected the enlarged HUD and debug overlay, and rechecked F1/F2 behavior with five enemies active.

### 2026-07-17 — Milestone 1: Combat Lab (Technical)

#### Added

- Resource-backed Jax and Street Punk actor scenes composed from typed state, health, attack-timing, logical-hitbox, and replaceable visual components.
- Three-lane automatic movement, stable opposing-team target acquisition/invalidation, six-position attack reservations, active-edge basic attacks, deterministic integer damage, visible knockback, combat-local hit-stop, health indicators, damage numbers, hit/death/spawn effects, and deterministic placeholder audio.
- A fixed authored Combat Lab that launches one Jax against five Street Punks, replaces defeated enemies, cleans dead actors and reservations, and restarts the lab round after Jax incapacitates without direct character control.
- Fixed-value coin clusters for rewarding enemies, including a generous click target, approximately 2.5-second full-value auto-collection, approximately 3-second manual streak, data-driven basis-point bonus schedule, and hard 10% per-cluster cap.
- Deterministic combat, combat-director, and reward suites covering damage/health, state and attack timing, lanes/reservations, target validity, repeated cleanup, manual/automatic accounting, same-tick races, repeated/late input, streak expiry/exclusion, rounding, and bonus caps.
- Updated Combat Lab screenshot evidence at `res://docs/screenshots/milestone_1_combat_lab.png`.

#### Changed

- `GameRun` now wires the run-scoped combat/reward authorities to the Combat Lab, HUD, debug overlay, and presentation feedback while preserving the Milestone 0 main scene and F1/F2 behavior.
- `GameHUD` presents elapsed lab time, Jax status/target, coin total, and manual streak. `DebugOverlay` presents live actor, lane, target, reservation, and reward diagnostics.
- `DowntownLoop` stage containers now host the Milestone 1 actors, effects, and temporary loot presentation; the intervention placeholder remains explicitly nonfunctional.
- Coin clusters are offset outside the immediate melee silhouette so their forgiving interaction area does not mask combat.

#### Verification

- Passed all 30 discoverable tests with 348 assertions and no failures in Godot 4.7.
- Launched the configured main scene directly to `/GameRun`, observed a five-enemy automatic fight beyond 60 seconds, confirmed repeated death/replacement cleanup and live-only target/reservation state, and verified lane/battlefield bounds.
- Exercised `F1` and `F2`, verified manual and ignored coin collection behavior, captured 640 x 360 evidence, and inspected fresh game/editor logs with no task-introduced parser errors, runtime errors, or warnings.

#### Scope

- No Neon Loop gameplay Autoload or unseeded/global randomness was added. Milestone 1 uses only fixed authored values.
- Fire Hydrant behavior, Night Pressure runtime, deterministic random streams, equipment, synergies, cards, extraction, shops, saving, bosses, progression, and procedural generation remain unimplemented.
- Technical Milestone 1 is complete. The Human Validation Gate has not been run or passed; only the project owner may record it, and Milestone 2 remains blocked.

### 2026-07-17 — Specification Alignment Review (Documentation Only)

#### Changed

- Revised `GameSpecifications.md` in place across the product experience, loop, UI, encounters, escalation, interventions, equipment, synergies, rewards, economy, extraction, summary, architecture, data, events, persistence, debugging, tests, performance, milestones, completion criteria, agent rules, and review questions.
- Split interaction cadence into ambient optional opportunities (approximately 10-20 eligible active seconds), meaningful strategic decisions (approximately 30-60 seconds), and major risk decisions (approximately 2-3 minutes). Defined full-value optional coin clusters with approximately 2.5-second auto-collection, an approximately 3-second manual streak, a 10% per-cluster bonus cap, and at-most-once click/timeout resolution. Milestone 1 uses fixed authored base coin values.
- Split future escalation between tactical, finitely coolable Heat and irreversible Night Pressure, which advances only during eligible active simulation or exactly-once encounter completion, latches extraction/boss thresholds, and eventually makes the boss unavoidable.
- Raised the vertical-slice equipment target from six to at least nine items, adding Magnetic Flail, Voltaic Blade, and Chain Sneakers and requiring at least three two-item combinations per primary synergy plus at least two bridge items.
- Defined the Milestone 3 authoritative integer seed and `RunDirector`-owned, non-Autoload deterministic streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and isolated `cosmetic` randomness.
- Added the mandatory owner-recorded Milestone 1 Human Validation Gate and made a recorded pass an explicit blocking entry condition for Milestone 2.
- Aligned `AGENTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, and `CONTENT_CATALOG.md` with the revised contracts while preserving Milestone 0 implementation truth.
- Recorded the architectural rationale in `docs/decisions/0001-run-engagement-escalation-and-randomness.md`.
- Documented that the repository's tracked canonical specification is `GameSpecifications.md`; the review brief's lowercase spelling refers to that same file. No alias or case-only rename was created.

#### Scope

- Documentation alignment only: no gameplay code, scenes, data, project settings, assets, or runtime behavior changed.
- Milestone 0 remains completed and verified. Milestone 1 remains unstarted, its human gate is not yet eligible, and Milestone 2 remains blocked until the project owner eventually records a passing gate.

### 2026-07-16 — Milestone 0: Project Foundation

#### Added

- Recommended project folder structure for assets, data, scenes, scripts, tests, and documentation.
- `GameRun` composition scene with the six run-scoped system placeholders, Downtown Loop stage, camera, HUD, and debug overlay.
- Placeholder `DowntownLoop` nighttime street with three development lane guides, route markers, and clearly temporary nonfunctional interactable, crew, enemy, and effects visuals in their future containers. Spawn markers and `LootContainer` remain unpopulated.
- Placeholder HUD regions for the minimap, Heat, run timer, crew, equipment and synergies, district cards, interventions, and extraction.
- Development `DebugOverlay` with an `F1` visibility toggle and a lane-guide visibility control.
- Typed, logic-free `RunDirector`, `PatrolController`, `CombatDirector`, `RewardDirector`, `CardSystem`, and `SynergySystem` classes.
- Core repository documentation: `AGENTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, `CONTENT_CATALOG.md`, and this changelog.

#### Changed

- Configured the project for a 640 x 360 internal resolution, preserved 16:9 presentation, nearest-neighbour texture filtering, and integer-friendly pixel-art scaling.
- Configured the project to launch into `GameRun`.

#### Scope

- No combat, actors, enemies, targeting, cards, equipment, rewards, progression, saving, shops, bosses, patrol behavior, encounter behavior, or procedural generation was implemented.
- No Neon Loop gameplay Autoload was added. The existing `_mcp_game_helper` remains Godot MCP development tooling.

#### Verification

- Passed a Godot 4.7 project-main launch with runtime root `/GameRun`.
- Confirmed the Downtown Loop stage and HUD in a 640 x 360 capture.
- Exercised `F1` through hidden -> visible -> hidden -> visible transitions.
- Used `F2` to hide `LaneMarkers` (`visible=false`) and restore them while the overlay was hidden.
- Relaunched and confirmed clean game/editor logs with no parser or runtime errors introduced by Milestone 0.
- Saved the acceptance screenshot at `res://docs/screenshots/milestone_0_foundation.png`.
- The overlay lane button is present and wired to the same tested callback; its direct mouse-click path was not separately simulated.
