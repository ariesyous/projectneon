# Neon Loop Implementation Plan

## Current target

**Milestone 0 — Project Foundation: complete**

**Milestone 1 — Combat Lab: technical implementation complete**

The Combat Lab now supplies the smallest repeatable automatic-combat proof while preserving the Milestone 0 foundation. Technical acceptance is complete; the owner-recorded five-person Human Validation Gate has not been run or passed. Milestone 2 remains blocked.

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

**Status: Technical implementation and verification complete. Human Validation Gate pending.**

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

Deterministic tests cover damage, health, attack timing, lane/reservation behavior, target validity and cleanup, base-value delivery, click/timeout single resolution, streak timing, auto-collection exclusion, deterministic rounding, and the 10% cap. Technical runtime verification covers the configured main scene, a five-enemy session beyond 60 seconds, F1/F2, repeated spawning/cleanup, and clean logs. Final cadence and qualitative tuning remain part of the owner gate and Milestone 6.

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
- [x] No gameplay Autoload, global/unseeded randomness, or Milestone 2+ runtime system

### Milestone 1 Human Validation Gate — mandatory owner record

**Status: Eligible for owner testing, but not recorded and not passed.**

After every technical Milestone 1 acceptance criterion passes, the project owner must run and record the specification's qualitative test with at least five people who were not involved in implementation. A pass requires all recorded criteria, including at least four of five testers voluntarily watching for 60 seconds, at least three expressing curiosity or requesting another encounter, and majority readability/satisfying-impact observations without broad confusion or lifelessness feedback.

Only the project owner may record this gate as passed. Coding agents, automated tests, and implementation-team observations cannot satisfy or infer it. Any failed criterion requires combat improvements and a repeat of the full gate. **Milestone 2 is blocked until the owner records a pass.**

### Milestone 2 — Player Intervention

**Entry condition: an owner-recorded passing Milestone 1 Human Validation Gate.**

After that gate passes, implement the Fire Hydrant interaction, feedback, valid targeting, damage, strong knockback, and cooldown/charge presentation. Do not begin this milestone merely because automated or technical Milestone 1 checks pass.

### Milestone 3 — Complete Run Structure

Implement actual run states, patrol progression, encounters, timer, rewards, extraction, defeat, boss trigger, and summary while keeping the two escalation authorities distinct:

- **Heat** is tactical, ranges from 0-100, changes immediate encounter danger/reward quality, and may receive finite cooling. Heat 100 does not itself start the boss.
- **Night Pressure** is non-negative, irreversible during a run, advances through eligible active simulation time and exactly-once encounter completion, scales enemy health/damage/spawn budget, latches extraction progression, and eventually queues the unavoidable boss at a safe transition boundary.
- Cooling, shops, cards, and finite Subway Reroute charges may reduce Heat but never reduce Night Pressure, clear a queued boss, or reopen a spent threshold.

Add one authoritative integer run seed owned by `RunDirector` and a run-scoped `RunRandomStreams` component, never an Autoload. Use stable, versioned sub-seed derivation and deterministic candidate ordering for the named streams `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Gameplay systems must not use unseeded global random calls or share one fragile random sequence. Test same-seed selection reproducibility, stable candidate ordering, different-seed variation over a documented sample, and isolation such that extra `cosmetic` draws cannot change gameplay-stream outcomes.

### Milestone 4 — Equipment and Synergies

Implement at least nine equipment definitions, equipment UI, tag aggregation, and the Knockback, Bleed, and Tech synergies. The initial catalogue includes the original six plus Magnetic Flail, Voltaic Blade, and Chain Sneakers. Each primary synergy must have at least three valid two-item activation combinations, at least two items must bridge primary synergy categories, and choice UI must preview both immediate activation and alternative-path progress.

### Milestone 5 — District Cards

Implement data definitions, deck/hand/discard state, placement validation, route slots, minimap updates, and the four initial cards.

### Milestone 6 — Vertical-Slice Content and Presentation

Complete the specified crew, enemies, elite, boss, interventions, presentation, audio, tutorial, settings, minimal persistence, and run summary required for the replayable vertical slice. Tune ambient optional interactions to approximately every 10-20 eligible active seconds while keeping meaningful strategic decisions at approximately 30-60 active seconds and major risk decisions at approximately 2-3 active minutes.

## Scope gate

Procedural generation, additional districts, large rosters, multiplayer, advanced meta-progression, achievements, controller support, localization, and the other deferred features in `GameSpecifications.md` remain out of scope until the vertical slice is proven. Run-seed and named-stream infrastructure is required for the vertical slice and is scheduled for Milestone 3; daily scheduling, shared daily rules, leaderboards, and daily rewards remain deferred.
