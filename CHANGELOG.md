# Changelog

All notable changes to Neon Loop are documented here. Dates use the local project working date.

## [Unreleased]

### 2026-07-18 — Milestone 2: Player Intervention (Technical)

#### Added

- A visible Fire Hydrant environmental intervention with a generous pointer/touch target, hover highlight, exact range preview, click/tap activation, available/no-target/cooling/rejection states, concise tooltip, and matching HUD control.
- A typed `FireHydrantTuning` Resource with a 112-pixel inclusive circle, 18 deterministic area damage, fixed leftward 300-force knockback for 0.30 seconds, an 8.0-second cooldown, and 0.55-second water, 0.28-second impact, and 0.50-second rejection presentation timings.
- A run-scoped `FireHydrantController` authority that validates live enemies in stable order, locks cooldown before callbacks, rejects unavailable/no-target/repeated input, and applies environmental damage and knockback through existing combat contracts.
- A typed Downtown Loop combat-safe Resource defining inclusive actor origins X 164–456 and Y 194–258 with lane centers Y 194/226/258.
- Deterministic Milestone 2 combat-space and intervention suites covering exact boundaries, damage/knockback, invalid/dead exclusion, cooldown, reactivation, same-tick/re-entrant deduplication, preview/HUD mapping, repeated lifecycle cleanup, safe bounds, and coin/Hydrant input separation.
- Nonmodal re-openable player Help, one-shot Web sound-unlock guidance, visible fullscreen controls, landscape/safe-area presentation, and updated visual evidence at `res://docs/screenshots/milestone_2_player_intervention.png`.

#### Changed

- Spawn, movement, target approach, attack reservations, knockback, recovery, replacement cleanup, coin placement, and debug lane presentation now use the same combat-safe contract, preventing long-running fights from drifting under the left HUD while preserving visible knockback.
- Coin clusters now advertise click/tap interaction with a pointer, pulse, hover response, and persistent affordance while preserving the full-value timeout, manual-only streak, 10% bonus cap, and authoritative at-most-once accounting.
- The Combat Lab HUD has clearer hierarchy and containment, a dedicated intervention state area, honest purpose/onboarding copy, a generously sized fullscreen control, and safe-area-aware presentation.
- The small deterministic Combat Lab PCM set is built before play. Web displays one immediate unobtrusive sound-unlock affordance when a gesture is required and removes it after the first successful unlock without pausing or resetting combat.
- Local Web and Windows export presets exclude development addon, build, documentation, and test content from the shipped pack. The existing 640 x 360 internal resolution and 16:9 direction remain unchanged.

#### Verification

- Passed **46/46 tests and 694 assertions with no failures**: preserved Milestone 1 coverage is 30 tests/348 assertions, and Milestone 2 coverage is 16 tests/346 assertions.
- Completed a **315.3046-second** uninterrupted Combat Lab soak with 113 enemies spawned, 98 defeated, five active enemies, six live actors, and six live reservations. All actor origins remained within X 164–456 and Y 194–258, and repeated spawning/cleanup did not drift combat under the HUD.
- The soak coin ledger ended at **3,920**, exactly 98 rewarding defeats multiplied by the fixed 40-coin base; manual collection and full-value automatic collection also remained correct.
- Launched the configured project directly into `/GameRun`; repeatedly exercised Hydrant success, no-target/cooldown rejection, out-of-range exclusion, coins, Help, `F1`, and `F2`; and inspected fresh Godot output without task-introduced parser errors, runtime errors, or warnings.
- Smoke-tested local Windows and Web exports. Desktop audio initialized through WASAPI. Web cold and warm loads showed the immediate one-shot sound prompt; one gesture unlocked audio without resetting combat, and exercised browser checks reported no warning/error console messages.
- Repeated visible-control Web fullscreen entry/exit and fullscreen-only Escape were stable. Representative mobile-landscape and portrait viewports preserved centered 16:9 presentation, safe layout, and landscape guidance.

#### Limitations

- The in-app browser retained F11 instead of delivering it to the game. The runtime handles F11 if delivered and otherwise allows the browser to retain its normal behavior; the visible fullscreen control remains the primary cross-platform method.
- The generated Godot Web shell continued to block ordinary browser zoom while its canvas was focused. Fullscreen is the useful Milestone 2 presentation-scale alternative; a custom accessible shell is deferred.
- Physical-device touch testing was unavailable; representative mobile browser viewports, deterministic interaction-authority tests, and typed touch handlers supplied the current evidence.
- The temporary self-contained headless export runner reported that its sandboxed `user://` profiler directory could not be opened. Both exports completed, and the message did not reproduce in the exported Windows runtime or game/browser logs.
- The 640 x 360 canvas remains intentional. A future higher-resolution pixel-art presentation pass is recommended if production typography and art outgrow it.

#### Scope

- Technical Milestone 2 is complete. The separate Milestone 1 Human Validation Gate remains the project owner's qualitative pass and is not claimed by automated or agent verification.
- Wet/status effects, combo meters, Call Backup, Subway Reroute, patrol progression, encounter scheduling, Heat, Night Pressure, random streams, equipment, synergies, cards, shops, extraction, saving, bosses, progression, procedural generation, and all other Milestone 3+ behavior remain unimplemented.
- Local verification exports were not committed, published, or deployed. GitHub Pages was not redeployed.

### 2026-07-18 — Owner Human Validation Gate Pass and Milestone 2 Authorization

#### Recorded

- The project owner recorded the Milestone 1 five-person Human Validation Gate as **PASSED** on 2026-07-18.
- All five designated testers voluntarily played for more than two minutes. Their feedback showed clear curiosity about future encounters, enemies, abilities, weapons, customization, and progression.
- Testers could follow the combat, identified satisfying hits and sounds, and did not broadly describe the fighting as confusing, lifeless, or difficult to understand.
- Remaining feedback concerned presentation, onboarding, controls, and communicating the larger purpose of the game.
- This is the owner's qualitative human-validation record. It is distinct from automated test results, technical verification, or agent observation, and no individual tester records have been invented.

#### Design Input

- Captured interest in additional melee and ranged enemies, weapon and gun variants, timed abilities or spells, lifesteal, armor and damage types, enemy inspection and detailed health information, enemy area attacks, damage-over-time attacks and spells, encounter starts, between-fight structure, eventual coin spending, customization, and progression.
- These interests remain future design input for their owning later milestones; this record does not authorize or implement Milestone 3+ systems.

#### Scope

- The owner-recorded gate pass authorizes Milestone 2 — Player Intervention and targeted Milestone 1 presentation and usability improvements identified during testing.
- This owner-authorization entry itself claims no Milestone 2 technical acceptance; the separate technical completion entry above records the subsequently executed result.
- Milestone 3 and later gameplay systems remain outside the authorized scope.

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
