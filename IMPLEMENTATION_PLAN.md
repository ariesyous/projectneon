# Neon Loop Implementation Plan

## Current target

**Milestone 0 — Project Foundation: complete**

**Milestone 1 — Combat Lab: technical implementation complete**

**Milestone 2 — Player Intervention: technical implementation and verification complete**

**Milestone 3 — Complete Run Structure: technical implementation and verification complete**

The Combat Lab foundation and Fire Hydrant intervention are preserved inside a complete run lifecycle. Technical Milestone 1 acceptance is complete. On 2026-07-18, the project owner recorded the five-person Human Validation Gate as **PASSED**, satisfying the Milestone 2 entry condition; this owner qualitative decision remains distinct from all automated and coding-agent verification. Milestone 2 and the separately authorized Milestone 3 run structure have now passed their respective technical verification.

## Milestone 0 implementation

### Completed foundation work

- [x] Establish the recommended `assets`, `data`, `scenes`, `scripts`, `tests`, and `docs` directory families.
- [x] Configure the 640 x 360 internal design resolution, 16:9 preservation, nearest-neighbour filtering, and integer-friendly pixel-art scaling.
- [x] Create `GameRun` as the run-scoped composition root and configure it as the project main scene.
- [x] Create the placeholder `DowntownLoop` stage with a nighttime street backdrop.
- [x] Add three visible development lane guides and placeholder route nodes.
- [x] Add clearly temporary, nonfunctional crew, enemy, effects, and interactable visuals under their future stage containers; keep spawn markers and loot unpopulated.
- [x] Create the `GameHUD` shell with reserved minimap, Heat, timer, crew, equipment/synergy, card, intervention, and extraction regions.
- [x] Create typed, logic-free `RunDirector`, `PatrolController`, `CombatDirector`, `RewardDirector`, `CardSystem`, and `SynergySystem` nodes.
- [x] Create the development `DebugOverlay` and `F1` toggle path.
- [x] Provide a control path for hiding and showing all three lane guides.
- [x] Create the Milestone 0 documentation set.

### Runtime acceptance verification

- [x] Launch the project with Godot 4.7.
- [x] Confirm the project-main launch opens with runtime root `/GameRun`.
- [x] Confirm the placeholder Downtown Loop street and HUD are visible in a 640 x 360 capture.
- [x] Confirm repeated `F1` transitions hide, show, hide, and show the development overlay.
- [x] Confirm `F2` hides and restores all three lane guides, including while the overlay is hidden.
- [x] Inspect the Godot game and editor logs after relaunch; no parser errors, runtime errors, or task-introduced warnings remain.
- [x] Correct all errors introduced by Milestone 0.
- [x] Capture `res://docs/screenshots/milestone_0_foundation.png`.
- [x] Record final verification evidence and the unexercised mouse-click detail in `TEST_PLAN.md` and `CHANGELOG.md`.

**Milestone 0 acceptance status: Passed.** The overlay lane button exists and is wired to the same callback exercised through `F2`; its direct mouse-click path was not separately simulated.

## Planned milestones

### Milestone 1 — Combat Lab

**Status: Technical implementation and verification complete. Human Validation Gate passed by owner on 2026-07-18.**

Implemented the smallest automatic combat proof: Jax, Street Punk, typed actor state, three-lane movement, targeting and attack-position reservation, basic attacks, damage/health, knockback, hit-stop, damage numbers, enemy death/cleanup, repeat spawning, and placeholder audiovisual feedback. The authored lab runs without coin clicks or direct character control.

Implemented the narrow coin-cluster loop required by the revised specification:

- Each coin-rewarding defeated enemy creates one generous clickable cluster; explicitly rewardless enemies create none.
- Milestone 1 uses fixed authored base coin values; randomized reward generation waits for the named streams in Milestone 3.
- A cluster auto-collects after approximately 2.5 seconds and always grants its full base value.
- A successful manual collection resolves immediately, grants the base value once, and advances an approximately 3-second manual streak.
- Auto-collection neither advances the manual streak nor earns its bonus.
- The manual per-cluster bonus is data-driven and capped at 10% of that cluster's base value.
- Click and timeout share one authoritative, at-most-once resolution so a race cannot duplicate the award.
- Ignoring clusters never loses the base reward and never interrupts combat.

Deterministic tests cover damage, health, attack timing, lane/reservation behavior, target validity and cleanup, base-value delivery, click/timeout single resolution, streak timing, auto-collection exclusion, deterministic rounding, and the 10% cap. Technical runtime verification covers the configured main scene, a five-enemy session beyond 60 seconds, F1/F2, repeated spawning/cleanup, and clean logs. The owner subsequently recorded the separate qualitative gate as passed; final vertical-slice cadence and broader tuning remain part of Milestone 6.

Technical checklist:

- [x] Jax and Street Punk Resource-backed actor scenes
- [x] Typed composed state, health, attack timing, and presentation components
- [x] Stable three-lane movement, target acquisition/invalidation, and six attack-position reservations
- [x] Active-edge damage, visible knockback, combat-local hit-stop, damage numbers, death, and cleanup
- [x] Fixed five-enemy authored Combat Lab with repeat replacement and no direct character control
- [x] Fixed authored 40-coin Street Punk reward and explicitly rewardless Jax
- [x] Approximately 2.5-second full-value auto-collection and immediate manual collection
- [x] One authoritative at-most-once click/timeout resolver
- [x] Manual-only approximately 3-second streak and data-driven bonus capped at 10%
- [x] Deterministic automated suites and Godot 4.7 runtime verification
- [x] Playtest-driven HUD readability pass with enlarged live values, meters, panel framing, buttons, and development diagnostics
- [x] At the Milestone 1 gate, no gameplay Autoload, global/unseeded randomness, or later-milestone runtime system

### Milestone 1 Human Validation Gate — mandatory owner record

**Status: PASSED — owner-recorded on 2026-07-18.**

After every technical Milestone 1 acceptance criterion passed, the project owner ran the specification's qualitative test and supplied an aggregate passing record. All five designated testers voluntarily played for more than two minutes. The owner reported clear curiosity about future encounters, enemies, abilities, weapons, customization, and progression; readable combat relationships; satisfying hits and sounds; and no broad description of the fighting as confusing, lifeless, or difficult to understand. Remaining feedback concerns presentation, onboarding, controls, and communicating the larger purpose of the Combat Lab.

Only the project owner may record this gate as passed. This plan transcribes the owner's 2026-07-18 decision; coding agents, automated tests, and implementation-team observations did not satisfy or infer it. The gate's pass unblocks Milestone 2 and does not verify any Milestone 2 acceptance criterion.

### Milestone 2 — Player Intervention

**Entry condition: an owner-recorded passing Milestone 1 Human Validation Gate.**

**Status: Entry condition satisfied; technical implementation and verification complete.**

Implemented the smallest complete Fire Hydrant player intervention together with the specifically authorized Combat Lab presentation/usability improvements. The authoritative tuning is a 112-pixel fixed circle, 18 deterministic area damage, fixed leftward 300-force knockback for 0.30 seconds, an 8.0-second cooldown, and 0.55-second water, 0.28-second impact, and 0.50-second rejection presentation windows.

Technical checklist:

- [x] Visible environmental Hydrant with a generous mouse/touch area, pointer cursor, hover highlight, and preview drawn from the same authored radius used by authority
- [x] Click/tap activation through a run-scoped typed controller rather than UI authority
- [x] Stable inclusive-circle validation, deterministic light damage, strong readable fixed-left knockback, and no effect on actors outside the authoritative area
- [x] Dead, invalid, unregistered, and non-enemy exclusion
- [x] Cooldown lock before callbacks, repeated/same-tick input rejection, no duplicate activation, cooldown progression/completion, and reactivation
- [x] Clear available, no-target, cooling-down, and rejected world/HUD states with a concise effect/availability tooltip
- [x] Readable placeholder water, impact, rejection, and prebuilt audio feedback sufficient to materially change an active encounter
- [x] One `CombatSpaceDefinition` used for spawning, lane movement, target approach, reservations, knockback, recovery, coin placement, and lane guides: actor origins X 164–456 and Y 194–258 on lanes Y 194/226/258
- [x] Nonmodal, re-openable Help explaining autonomous combat, manual/full-value-auto coins, Hydrant use, fullscreen, the Combat Lab purpose, and the absence of current coin spending
- [x] More discoverable coin clusters with pointer, pulse, hover, click/tap copy, generous bounds, preserved full-value auto-collection, manual-only streak rules, and non-overlapping Hydrant placement
- [x] Prebuilt Combat Lab audio set plus one-shot Web gesture unlock that does not pause or reset combat
- [x] Obvious fullscreen control, F11-if-delivered and fullscreen-only Escape handling, repeated stable transitions, mobile-landscape/safe-area support, and preserved 16:9 presentation
- [x] Retained the 640 x 360 internal canvas; documented Web-shell zoom limitation and future higher-resolution pixel-art recommendation instead of performing an unplanned resolution migration
- [x] Passed 46/46 tests and 694 assertions with no failures: preserved Milestone 1 30/348 plus Milestone 2 16/346
- [x] Completed editor, local Windows, and local Web checks plus a 315.3046-second safe-boundary soak with 113 spawned, 98 defeated, five active enemies, six live actors/reservations, and an exact 3,920-coin ledger
- [x] Captured `res://docs/screenshots/milestone_2_player_intervention.png`
- [x] Added no gameplay Autoload, unseeded/global randomness, Wet/status/combo system, or Milestone 3+ behavior

**Milestone 2 technical acceptance status: Passed.** This result is an implementation/test record; it neither performs nor reinterprets the separate owner-recorded Milestone 1 Human Validation Gate. The verified local Milestone 2 build was not republished or redeployed by this work.

#### Historical Milestone 2 design input — deferred to its owning later work

The owner-recorded playtest surfaced interest in the following areas. They are captured for later design work and are deliberately excluded from Milestone 2 implementation:

- Additional melee and ranged enemies, plus enemy area attacks, damage-over-time attacks, and spells
- Weapon and gun variants, timed abilities or spells, lifesteal, armour, and damage types
- Enemy inspection and more detailed health information
- How encounters begin, what happens between fights, and how coins are eventually spent
- Customization and progression

At Milestone 2 completion, Call Backup, Subway Reroute, patrol progression, encounter scheduling, Heat, Night Pressure, `RunRandomStreams`, equipment, synergies, cards, shops, extraction, saving, bosses, progression, and procedural generation were outside that milestone's authorized implementation scope. Milestone 3 subsequently implemented only its explicitly authorized run-structure subset.

### Milestone 3 — Complete Run Structure

**Status: Technical implementation and verification complete.**

Implemented actual run states, patrol progression, encounters, timer, standard rewards, extraction, defeat, boss trigger, summary, and restart while keeping the two escalation authorities distinct:

- **Heat** is tactical, ranges from 0-100, changes immediate encounter danger/reward quality, and may receive finite cooling. Heat 100 does not itself start the boss.
- **Night Pressure** is non-negative, irreversible during a run, advances through eligible active simulation time and exactly-once encounter completion, scales enemy health/damage/spawn budget, latches extraction progression, and eventually queues the unavoidable boss at a safe transition boundary.
- Cooling, shops, cards, and finite Subway Reroute charges may reduce Heat but never reduce Night Pressure, clear a queued boss, or reopen a spent threshold.

Added one authoritative integer run seed owned by `RunDirector` and a run-scoped `RunRandomStreams` child, never an Autoload. Schema version 1 derives every sub-seed with `fnv1a32_utf8_v1` over the UTF-8 canonical input `neon-loop|schema:<version>|seed:<integer>|stream:<name>`. All candidates are filtered, duplicate/empty stable IDs are excluded, and remaining IDs are sorted before drawing. The isolated named streams are exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`.

Authored run tuning:

- Heat tiers are exactly 0–19, 20–39, 40–59, 60–79, 80–99, and 100. Their spawn additions are 0/1/2/3/4/5; enemy-damage multipliers are 1.00/1.05/1.10/1.15/1.20/1.30; reward-quality floors are 0/0/1/2/3/4; reward multipliers are 1.00/1.05/1.10/1.20/1.35/1.50; elite eligibility begins at tier 3.
- Night Pressure gains 0.25 per eligible active second and exactly-once completion gains of 6 for a standard encounter or 10 for an elite-flagged encounter.
- Each Night Pressure point adds 1% enemy health, 0.5% enemy damage, and 1.25% encounter spawn budget. Spawn budget uses non-negative round-half-up, `floor(scaled + 0.5)`, before encounter/global caps; the global enemy cap is 30.
- Extraction thresholds are 18 and 36 Night Pressure; the boss threshold is 50. Extraction is latched and spent once; boss queueing is irreversible and wins a same-update crossing unless extraction was already confirmed.
- Subway Reroute starts with 2 charges and removes 15 Heat per use. Shop cooling allows 2 purchases per run, costs 60 coins each, and removes 18 Heat. Neither stock regenerates through time.
- The authored route has five nodes with four-second travel segments. Intro is 1.25 seconds and extraction transition is 1.0 second.
- Standard reward definitions are Street Cache (20 coins, 2 scrap, quality 0), Neon Stash (30 coins, 3 scrap, quality 1), and Viper Cache (45 coins, 5 scrap, quality 3), modified by current Heat reward tuning.

Technical checklist:

- [x] Explicit typed state graph with invalid/duplicate transition rejection, eligible-time pause/modal/introduction rules, extraction, defeat, boss trigger, summary, and restart
- [x] Authored patrol route, safe transition boundaries, deterministic encounter scheduling, spawn/lane selection, and encounter/global concurrency caps
- [x] Separate Heat and Night Pressure state with exact tiers, monotonic pressure, exactly-once completion IDs, scaling, deterministic rounding, and visible diagnostics
- [x] Latched extraction progression, spent-window behavior, unavoidable queued boss, and same-update boss precedence unless extraction was already confirmed
- [x] Finite player-facing Subway and shop cooling with zero-stock rejection and no Night Pressure/threshold mutation
- [x] Optional supplied seed, generated recorded seed, schema version, seven run-scoped named streams, locked vectors, stable ordering, same-seed replay, different-seed sample variation, and stream/cosmetic isolation
- [x] Data-driven route, encounters, Heat, pressure/scaling, cooling, random schema, and standard rewards
- [x] Standard reward accounting, extracted/defeated/boss-triggered/victory result records, and clean same-seed/new-seed restart
- [x] Preserved all 46 Milestone 1–2 tests and added 29 Milestone 3 tests: **75/75 tests, 1,100 assertions, no failures or skips**
- [x] Launched `/GameRun`; exercised representative extracted, defeated, and boss-threshold runs; tested cooling, time eligibility, threshold ordering, same-seed/cosmetic isolation, restart cleanup, Hydrant, coins, Help, fullscreen, `F1`, and `F2`
- [x] Produced clean local Windows and Web exports, clean Windows startup smoke checks, and a locally served Web smoke with audio unlock, Help, fullscreen, and no browser-console warnings/errors
- [x] Captured `res://docs/screenshots/milestone_3_complete_run_structure.png`
- [x] Added no gameplay Autoload and no Milestone 4+ equipment, synergy, district-card, progression, persistence, procedural, or final-boss content

**Milestone 3 technical acceptance status: Passed.** The boss implementation deliberately stops at threshold latching, safe queueing, boss intro, and boss-active transition. Final-boss content belongs to later milestones. The implementation and verification are local only; no commit, push, merge, publication, or deployment was performed.

### Milestone 4 — Equipment and Synergies

Implement at least nine equipment definitions, equipment UI, tag aggregation, and the Knockback, Bleed, and Tech synergies. The initial catalogue includes the original six plus Magnetic Flail, Voltaic Blade, and Chain Sneakers. Each primary synergy must have at least three valid two-item activation combinations, at least two items must bridge primary synergy categories, and choice UI must preview both immediate activation and alternative-path progress.

### Milestone 5 — District Cards

Implement data definitions, deck/hand/discard state, placement validation, route slots, minimap updates, and the four initial cards.

### Milestone 6 — Vertical-Slice Content and Presentation

Complete the specified crew, enemies, elite, boss, interventions, presentation, audio, tutorial, settings, minimal persistence, and run summary required for the replayable vertical slice. Tune ambient optional interactions to approximately every 10-20 eligible active seconds while keeping meaningful strategic decisions at approximately 30-60 active seconds and major risk decisions at approximately 2-3 active minutes.

## Scope gate

Procedural generation, additional districts, large rosters, multiplayer, advanced meta-progression, achievements, controller support, localization, and the other deferred features in `GameSpecifications.md` remain out of scope until the vertical slice is proven. Run-seed and named-stream infrastructure is complete in Milestone 3; daily scheduling, shared daily rules, leaderboards, and daily rewards remain deferred.
