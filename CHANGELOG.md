# Changelog

All notable changes to Neon Loop are documented here. Dates use the local project working date.

## [Unreleased]

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
