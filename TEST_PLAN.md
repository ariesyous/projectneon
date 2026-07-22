# Neon Loop Test Plan

## Purpose

Testing is milestone-scoped. Milestone 0 verifies the project foundation; Milestone 1 verifies the narrow Combat Lab, automatic combat, and coin-cluster accounting; Milestone 2 verifies the Fire Hydrant intervention, combat-safe space, and targeted presentation/usability improvements; Milestone 3 verifies the complete run structure, escalation, thresholds, cooling, deterministic streams, standard rewards, outcomes, and restart cleanup; Milestone 4 verifies equipment, statuses, synergies, and deterministic choices; Milestone 4.1 verifies the authorized equipment-safety and HUD-readability correction; Milestone 4.2 verifies the bounded inventory-drag and one-backpack-clarity correction; Milestone 5 verifies District Cards, deterministic finite deck state, future-route placement/resolution, supplemental card rewards, progression protections, and safe multimodal planning; and Milestone 6 verifies the bounded vertical-slice crew/enemy/elite/boss content, all three interventions, combo/projectiles, final presentation/audio/tutorials, settings, minimal versioned persistence/unlocks, complete summaries, cadence measurement, complete outcomes, and cross-system cleanup. Later checklists do not pretend that deferred gameplay systems are implemented.

## Error policy

- A parser error or runtime error introduced by the current task is a release blocker.
- Warnings must be investigated and either fixed or reported with their cause; they must not be hidden merely to clean the log.
- Visual acceptance requires a running-project check and screenshot when supported.
- Test status must distinguish static inspection from a verified Godot launch.

## Status convention

- **Passed** means the recorded check was actually executed against the stated build.
- **Planned** means the test is a downstream acceptance contract only; an unchecked planned item is not evidence that its system exists or works.
- **Pending execution** means implementation and its test case exist, but no final pass result is recorded until that exact matrix is run against the finished working tree.
- **Owner-recorded** means only the project owner may enter the result.

Milestone 1 through Milestone 5 technical suites are recorded as executed. The authorized Milestone 6 implementation and seven-suite/56-test addition passed its final cumulative automated gate, and the configured headless `/GameRun` boot completed cleanly. Representative manual runs/interactions, exports, browser-console inspection, visual evidence, cleanup-diagnostic follow-up, and owner qualitative validation remain **Pending execution** until the checks below complete. The Milestone 1 Human Validation Gate result remains separately labelled as an owner-recorded qualitative decision and is neither repeated nor reopened.

## Milestone 0 static checks

Inspect the project before launch:

- [x] `project.godot` points its main scene to `GameRun`.
- [x] The internal viewport is 640 x 360 and preserves 16:9 output.
- [x] Canvas texture filtering is nearest-neighbour and scaling is integer-friendly.
- [x] The recommended folder families exist.
- [x] `GameRun` composes all six system nodes, `DowntownLoop`, a camera, `GameHUD`, and `DebugOverlay`.
- [x] `DowntownLoop` contains a background, three lane guides, placeholder route nodes, and the required future-content containers.
- [x] `GameHUD` contains visibly labelled placeholder regions for every Milestone 0 HUD requirement.
- [x] `DebugOverlay` has a typed script and a route to toggle lane visibility.
- [x] `DebugOverlay` handles `F1` only in development builds and rejects key-repeat events.
- [x] The lane button and `F2` emit a typed visibility request that `GameRun` forwards to `DowntownLoop`.
- [x] Each system placeholder extends `Node`, has the expected `class_name`, uses typed GDScript, and contains no gameplay behavior.
- [x] No Neon Loop gameplay Autoload was added. The existing `_mcp_game_helper` is development tooling.

## Milestone 0 manual runtime verification

Status: **Passed — Godot 4.7, 2026-07-16**

- [x] Launched the configured project main scene; runtime root was `/GameRun`.
- [x] Confirmed the Downtown Loop stage and required HUD shell in a 640 x 360 capture.
- [x] Confirmed all three lane guides and placeholder route presentation were visible.
- [x] Exercised `F1` through hidden -> visible -> hidden -> visible transitions without accumulating input errors.
- [x] Hid `LaneMarkers` (`visible=false`) with `F2` while the overlay was hidden, then restored them.
- [x] Relaunched and inspected the game/editor logs; they were clean.
- [x] Saved visual evidence to `res://docs/screenshots/milestone_0_foundation.png`.

The overlay lane button is present and connected to the same `_toggle_lanes` callback exercised by `F2`. A direct mouse click on that button was not separately simulated during this verification pass.

### Expected result

- Project opens directly into `GameRun`.
- Street, route placeholders, HUD, and lane guides render.
- Debug and lane toggles are reliable.
- No parser or runtime errors are present.
- Placeholder directors/systems perform no gameplay work.

Screenshot: `res://docs/screenshots/milestone_0_foundation.png`.

## Milestone 0 automated coverage

No deterministic gameplay logic exists yet, so Milestone 0 does not require fabricated unit tests. A headless Godot parse/load smoke check may be used when the installed engine supports it. Automated deterministic coverage begins with the first corresponding gameplay calculations.

## Milestone suites

The complete unit and integration requirements remain authoritative in `GameSpecifications.md` section 41. The checklists below record implemented coverage and preserve later acceptance targets.

### Milestone 1 — Combat Lab technical suite

Status: **Passed — technical verification on Godot 4.7, 2026-07-17**

Combat baseline:

- [x] Deterministic damage calculations never produce negative damage.
- [x] Target validity rejects dead, incapacitated, same-team, unregistered, or otherwise invalid actors.
- [x] Jax acquires, approaches, and attacks a valid Street Punk without direct movement or attack input.
- [x] Hitboxes are active only during `ATTACK_ACTIVE`; knockback, hit-stop, damage numbers, and death are visibly distinct.
- [x] A dead enemy is released as a target, reservations are cleared synchronously, and repeated spawning/cleanup leaves no invalid combat state.
- [x] The Combat Lab remains understandable with five enemies and runs repeatably for at least 60 seconds without requiring character control or coin clicks.

Coin-cluster ledger and timing:

- [x] Every coin-rewarding defeated enemy creates exactly one cluster; an explicitly rewardless enemy creates none.
- [x] Milestone 1 cluster base values are fixed authored values and do not introduce ad hoc randomness before the Milestone 3 named-stream contract.
- [x] Ignoring a cluster grants its full base value once after the configured approximately 2.5-second `auto_collect_delay`.
- [x] A successful click before timeout collects immediately through a generous hit area, does not pause or interrupt combat, and grants the same full base value once.
- [x] Click-first, timeout-first, and same-authoritative-tick click/timeout races all resolve through one authoritative state transition, emit one collection result, change the coin ledger once, and remove or recycle the cluster once.
- [x] A click arriving after auto-collection, a timeout arriving after manual collection, and repeated click events are harmless no-ops with no duplicate base award or bonus.
- [x] Only a successful manual collection advances the manual streak. Auto-collection neither advances the streak nor receives a manual bonus.
- [x] The streak window is measured from the previous successful manual collection. A manual collection within the configured approximately 3-second window increments it; after expiry, the streak resets before the new successful manual collection is counted.
- [x] Auto-collecting another cluster during an otherwise-live manual streak does not itself advance the streak or receive its bonus.
- [x] The manual bonus follows the data-driven curve and documented deterministic rounding rule, and is never greater than 10% (`0.10`) of the current cluster's base value.
- [x] Missing every cluster still grants every base reward, and the Combat Lab remains playable as a fully passive observer.
- [x] The collection signal/record accurately reports cluster identity, manual versus automatic resolution, base value, bonus value, and resulting streak count.

Automated execution:

- `milestone_1_combat`: 8/8 tests, 97 assertions.
- `milestone_1_combat_director`: 3/3 tests, 175 assertions.
- `milestone_1_rewards`: 19/19 tests, 76 assertions.
- Total: **30/30 tests, 348 assertions, 0 failures**.
- The first editor-only long-loop fixture was rejected after it exercised non-`@tool` placeholder instances and destabilized the editor. It was removed rather than suppressed. Bounded active-instance director tests replaced it; the required 60+ second proof is executed in the configured running game.

Runtime execution:

- Project-main launch resolved directly to `/GameRun` with one Jax and five live Street Punks.
- Automatic combat was observed beyond 60 seconds with repeated enemy deaths/replacements, fixed lane bounds, visible hit reactions/knockback, and coherent targets/reservations.
- Ignored clusters awarded exactly the authored 40-coin base per defeat; a successful manual collection advanced the streak while combat continued.
- `F1` toggled the debug overlay. `F2` hid and restored all lane guides both with the overlay visible and hidden.
- The post-playtest readability pass was inspected at the native 640 x 360 canvas under the configured 1280 x 720 integer-scaled presentation; enlarged HUD text remained contained and the five-enemy combat canvas remained unobscured.
- The single-threaded Godot 4.7 Web release was exported locally and served over HTTP; automatic combat, five-enemy presentation, coin spawning and auto-collection, and the enlarged HUD loaded with no browser-console warnings or errors.
- Fresh game and editor logs were inspected after relaunch; no parser error, runtime error, or task-introduced warning remained.
- Screenshot: `res://docs/screenshots/milestone_1_combat_lab.png`.

### Milestone 1 human validation gate — owner recorded

Status: **PASSED — owner-recorded on 2026-07-18**

This qualitative gate began only after every technical Milestone 1 criterion passed. Automated checks, coding agents, and implementation-team observations cannot satisfy it. The result below transcribes the project owner's decision and is not an independent agent or automated verification result.

Owner procedure:

1. Recruit at least five people who were not involved in implementation.
2. Designate the five-person scored cohort before observation; treat additional testers as supplemental rather than replacements for a failed scored observation.
3. Give each tester only: “Watch this fight and tell me when you feel ready to stop.”
4. Do not explain intended build systems, future features, or desired conclusions beforehand.
5. Record each observation duration and concise, unattributed notes.
6. Allow coin clicking only if discovered naturally; do not count coin-cluster engagement as evidence that passive combat is entertaining.

Owner-provided aggregate record:

- All five designated testers voluntarily played for more than two minutes.
- Feedback showed clear curiosity about future encounters, enemies, abilities, weapons, customization, and progression.
- Testers could follow the combat and identified satisfying hits and sounds.
- Testers did not broadly describe the fighting as confusing, lifeless, or difficult to understand.
- Remaining feedback concerns presentation, onboarding, controls, and communicating the larger purpose of the game.

No individual tester rows are fabricated here; the project owner's aggregate decision is the authoritative human-validation record supplied to this repository task.

The project owner may record **Go** only if every criterion passes:

- [x] At least four of five testers voluntarily watched for 60 seconds.
- [x] At least three testers expressed curiosity about what happens next or requested another encounter.
- [x] Most testers could identify who was attacking whom.
- [x] Most testers identified at least one satisfying hit, reaction, or combat moment.
- [x] Combat was not broadly described as confusing, lifeless, or visually difficult to follow.

Owner-only result record:

- Owner-recorded decision: **PASSED**
- Date: **2026-07-18**
- Build/revision: **Not separately identified in the owner's aggregate record**
- Evidence location: **Owner-provided aggregate record transcribed in this section**

If any criterion fails, the result is **No-Go**, Milestone 2 remains blocked even if technical tests pass, and the full five-person gate must be repeated after the relevant attack timing, animation, sound, hit reaction, targeting readability, density, pacing, or effects revisions. Only the project owner may change the result above or record a pass.

### Milestone 2 — Fire Hydrant

Status: **Passed — technical verification on Godot 4.7, 2026-07-18**

Authoritative intervention behavior:

- [x] An available Hydrant activates once and begins its authored 8.0-second cooldown before resolution callbacks can request another activation.
- [x] Requests while cooling down, repeated/same-tick requests, and a re-entrant callback are rejected without duplicate damage, knockback, feedback, or cooldown reset.
- [x] An available request with no valid enemy in range is rejected without consuming cooldown.
- [x] The inclusive 112-pixel circle includes a valid enemy exactly on its boundary and excludes one beyond it.
- [x] Stable registration order, rather than scene-tree presentation order, determines the deterministic affected-target sequence.
- [x] Every valid in-range enemy receives exactly 18 area damage and fixed leftward 300-force knockback for 0.30 seconds; out-of-range actors are unchanged.
- [x] Dead, freed, queued-for-deletion, unregistered, allied, and otherwise invalid actors are excluded.
- [x] Cooldown starts, progresses, reaches ready, and permits reactivation with no hidden charge or random state.
- [x] The world preview and HUD state are projections of authoritative tuning/state rather than competing gameplay calculations.

Combat-space and regression behavior:

- [x] One typed combat-space Resource defines inclusive actor origins X 164–456 and Y 194–258 with lane centers Y 194/226/258.
- [x] Spawning, lane movement, target approach, attack-position reservations, knockback, recovery, coin placement, and debug lanes use that same contract.
- [x] Repeated spawning/death cleanup leaves only live actors and reservations and never moves combat beneath the left HUD.
- [x] Coin base values, full-value timeout collection, at-most-once resolution, manual-only streak, deterministic rounding, and 10% bonus cap remain unchanged.
- [x] Coin and Hydrant interaction regions do not overlap; both retain generous mouse/touch bounds and forward intent to separate authorities.

Presentation and input behavior:

- [x] The environmental Hydrant is visible and has pointer, hover highlight, exact range preview, click/tap activation, and clear available/no-target/cooling/rejection feedback.
- [x] The HUD exposes authoritative state, remaining cooldown, target count, a concise tooltip, and the same activation intent while automatic combat continues.
- [x] Placeholder water, impact, damage-number, rejection, and generated audio feedback make a successful activation readable and materially disruptive.
- [x] Nonmodal Help accurately explains automatic combat, manual and full-value-auto coins, Hydrant readiness/range, fullscreen, the Combat Lab purpose, and that coins are not spendable yet.
- [x] Coin clusters show a persistent click/tap affordance plus pulse/hover feedback without affecting timeout or accounting authority.
- [x] Web sound unlock appears immediately when a gesture is required, uses one ordinary interaction to prime audio, and neither pauses nor resets combat.
- [x] The visible fullscreen control is the primary cross-platform path; repeated entry/exit and fullscreen-only Escape preserve combat state.
- [x] F11 toggles fullscreen if the platform delivers it to the game; browser-retained F11 remains browser behavior rather than a captured no-op.
- [x] Mobile landscape preserves the native 16:9 presentation with sensible letterboxing/safe-area handling, and portrait displays a landscape recommendation.

Automated execution:

- `milestone_1_combat`: 8/8 tests, 97 assertions.
- `milestone_1_combat_director`: 3/3 tests, 175 assertions.
- `milestone_1_rewards`: 19/19 tests, 76 assertions.
- Preserved Milestone 1 total: **30/30 tests, 348 assertions**.
- `milestone_2_combat_space`: 3/3 tests, 27 assertions.
- `milestone_2_intervention`: 13/13 tests, 319 assertions.
- Milestone 2 total: **16/16 tests, 346 assertions**.
- Combined result: **46/46 tests, 694 assertions, 0 failures**.

The Milestone 2 suites cover available activation; cooldown/no-target rejection; inclusive in-range versus out-of-range behavior; exact damage and strong knockback; dead/invalid exclusion; cooldown progression/completion/reactivation; repeated, same-tick, and re-entrant activation; shared preview/HUD authority; combat-safe tuning and lane usage; coin/Hydrant input separation; and a deterministic 30-cycle spawn/cleanup lifecycle. A production `PackedScene` long-loop probe was not kept inside the editor addon because non-`@tool` runtime scripts are represented as placeholders there; the configured running game supplies the required lifecycle soak instead of suppressing or misreporting that tooling limitation.

Manual editor, desktop, and Web execution:

- The configured project launched directly into `/GameRun` with Jax and five live Street Punks, and automatic combat continued while hovering, activating, opening Help, collecting coins, and waiting for cooldown.
- Repeated Hydrant use with five enemies present materially changed active encounters. A representative boundary probe changed the only in-range Street Punk from 58 to 40 health and entered knockback while four out-of-range enemies and Jax were unchanged; an immediate second request was rejected.
- The uninterrupted combat-boundary soak reached **315.3046 seconds**: 113 enemies spawned, 98 defeated, five remained active, and all six live actors plus six reservations remained valid inside the authored safe region. Repeated Jax round resets and enemy replacement did not drift combat beneath the HUD.
- The soak coin ledger reached **3,920**, exactly 98 rewarding defeats multiplied by the fixed 40-coin base; active clusters resolved to zero without duplicate or lost awards. Manual collection separately produced the expected manual streak while automatic collection remained full-value.
- Help content was readable, nonmodal, and re-openable. `F1` and `F2` still toggled the debug overlay and lane visibility.
- A local Windows export launched and remained stable with WASAPI audio active; its smoke log contained no parser/runtime warning or error matches.
- Local Web cold load progressed into the game with the sound-unlock affordance immediately visible. One click removed it and enabled feedback without resetting the encounter. A warm reload reported its load event after approximately 226 ms and showed the same immediate one-shot prompt before the first gesture.
- Web hover showed the authoritative range circle. Successful activation showed water/impact feedback and cooldown; a no-target activation showed rejection without consuming cooldown. Coin, Help, and Hydrant clicks did not conflict.
- The visible Web fullscreen control entered and exited a 1920 x 1080 16:9 view twice; Escape restored the 1280 x 720 view without changing combat. The in-app browser retained F11 rather than delivering it to the game, exercising the allowed browser-owned path.
- A representative 844 x 390 mobile-landscape viewport retained centered 16:9 content and readable controls with side letterboxing. A 390 x 844 portrait viewport showed the landscape recommendation.
- Ordinary browser zoom remained unchanged while the generated Godot Web canvas had focus because the standard shell uses `user-scalable=no` and canvas touch ownership. Fullscreen is the documented presentation-scale alternative; a custom accessible shell is deferred.
- Fresh editor/game output and browser warning/error checks after the exercised interactions were clean. No task-introduced parser error, runtime error, warning, or browser-console message remained.
- Visual evidence: `res://docs/screenshots/milestone_2_player_intervention.png`.
- The local Windows and Web outputs were verification artifacts only. No GitHub Pages publication or redeployment occurred.

Technical limitations recorded without waiving acceptance:

- A physical mobile device was not available; mobile layouts were inspected at representative browser viewports, while mouse/touch authority and `InputEventScreenTouch` paths have deterministic coverage and typed runtime handlers.
- The in-app browser and embedded editor did not deliver F11 to the game. The runtime handles it when delivered and otherwise does not capture it, so the browser can retain its normal fullscreen shortcut.
- The standard Web shell's zoom policy remains a presentation limitation. The visible fullscreen control provides a stable scale alternative for Milestone 2.
- The temporary self-contained headless export runner reported that its sandboxed `user://` profiler directory could not be opened. Both exports completed, and this environment-only message did not reproduce in the exported Windows runtime or game/browser logs.
- The 640 x 360 internal canvas remains intentional. A future higher-resolution pixel-art presentation pass is recommended if production typography and art require more detail; no unplanned resolution migration was made.

**Milestone 2 technical acceptance result: Passed.** Every technical Milestone 2 criterion was satisfied. This does not constitute, repeat, or reinterpret the owner-recorded Milestone 1 Human Validation Gate.

### Milestone 3 — Complete Run Structure

Status: **Passed — implemented and executed in Godot 4.7**

Automated result:

- Complete project result: **75/75 tests, 1,100 assertions, 0 failures, 0 skips**.
- Preserved Milestone 1–2 result: **46/46 tests, 694 assertions**.
- Added Milestone 3 result: **29/29 tests, 406 assertions** across `milestone_3_run_authority_suite.gd` (19 tests) and `milestone_3_randomness_suite.gd` (10 tests).

Run lifecycle and outcomes:

- [x] The complete explicit transition graph covers initializing, intro, patrol, encounter, reward, shop, extraction available/extracting, boss intro/active, victory, defeat, summary, and paused states.
- [x] Invalid, duplicate, and terminal-state transitions reject without mutating authoritative state.
- [x] Standard rewards account coins/scrap once and resolve through `RewardDirector` rather than UI.
- [x] Extraction, defeat, boss-trigger, and victory results produce typed summary records with seed/schema, elapsed time, Heat/Pressure, encounter/enemy counts, and rewards.
- [x] Same-seed and generated-seed restart paths synchronously clear stale actors, reservations, loot, timers, latches, pending rewards, cooling stock, encounter IDs, and random-stream positions.

Heat separation and tiers:

- [x] Heat is clamped to 0–100 and maps exactly to tiers 0 at 0–19, 1 at 20–39, 2 at 40–59, 3 at 60–79, 4 at 80–99, and 5 at 100.
- [x] Heat changes immediate spawn additions, enemy damage, elite availability, reward quality/multiplier, and alert presentation without mutating already-earned Night Pressure.
- [x] Heat 100 does not itself start the boss or permanently close extraction.

Night Pressure invariants and scaling:

- [x] Night Pressure is non-negative and monotonically increasing throughout a run; cooling, interventions, reroutes, and extraction decisions cannot decrease it.
- [x] Only ending or restarting a run resets Night Pressure.
- [x] Eligible active simulation time advances timer and Pressure at 0.25 per second; paused states, modal reward/shop choices, extraction/boss transitions, terminal states, and non-interactive introduction add exactly zero.
- [x] Each authoritative encounter completion applies 6 standard or 10 elite-flagged Pressure exactly once; duplicate and retried completion IDs are rejected.
- [x] Enemy health, enemy damage, and spawn budget use active `RunEscalationDefinition` coefficients of 1%, 0.5%, and 1.25% per Pressure point.
- [x] Spawn budget uses documented non-negative round-half-up, `floor(scaled + 0.5)`, and respects both per-encounter concurrency and the global limit of 30.

Thresholds and precedence:

- [x] Tests immediately below, exactly at, and immediately above extraction thresholds 18/36 and boss threshold 50 produce the expected single latch.
- [x] Each extraction or boss threshold latches once and cannot reopen, clear, or fire twice after cooling, rerouting, or later updates.
- [x] A boss crossed at an unsafe transition sets `boss_queued` and begins exactly once at the next valid boundary.
- [x] A same-update extraction/boss crossing gives boss precedence unless extraction was already confirmed before that update.
- [x] Continued eligible active play and exactly-once encounter completions eventually reach the boss despite repeated Heat cooling.

Finite cooling and anti-farming:

- [x] Subway Reroute consumes one of two per-run charges, removes 15 Heat, advances the authored route, and never regenerates merely through time.
- [x] A zero-charge Subway request rejects without changing Heat, Night Pressure, route state, thresholds, or boss queue state.
- [x] Shop cooling costs 60 authoritative run coins, removes 18 Heat, and is limited to two purchases per run.
- [x] Zero-stock and insufficient-funds requests reject without mutation.
- [x] Exhausting cooling provides tactical relief but cannot postpone the boss indefinitely, reopen a spent extraction window, unlatch progression, or clear a queued boss.

Deterministic seed and named streams:

- [x] `RunDirector` records one authoritative integer seed, accepts an optional supplied seed, and otherwise generates it before the first gameplay draw.
- [x] Seed and `random_schema_version` appear in diagnostics and summary; summary exposes same-seed restart.
- [x] Run-scoped `RunRandomStreams` exposes exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic` as `StringName` values.
- [x] Locked vectors cover schema 1 `fnv1a32_utf8_v1` for every stream and do not use process/platform-dependent hashes.
- [x] Gameplay-code static inspection finds no `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, or `Array.pick_random()` calls.
- [x] Same seed, build/content/schema, decisions, and authoritative timing produce identical encounter, spawn, reward, equipment, card, and enemy-variant selections.
- [x] Same-seed restart resets every stream; extra draws in any one stream do not perturb another; extra `cosmetic` draws do not alter gameplay outcomes.
- [x] Empty and duplicate IDs are excluded, remaining candidates are sorted by stable content ID, and source ordering cannot change a choice.
- [x] A documented multi-seed sample produces sequence variation without relying on one coincidental pair.
- [x] Reproduction claims are limited to the same supported build, content revision, schema version, seed, ordered decisions, and authoritative timing context; cross-version or bitwise physics replay is not promised.

Manual/runtime verification:

- [x] Launched the configured main scene directly as `/GameRun` and inspected fresh editor/game output with no task-introduced parser errors, runtime errors, or warnings.
- [x] Completed accelerated representative extracted, defeated, and boss-threshold runs; boss threshold crossed during an unsafe encounter queued until the post-reward safe boundary.
- [x] Repeated shop and Subway cooling to exhaustion; Heat decreased while Night Pressure, latches, and boss queue did not.
- [x] Held the run in pause and modal shop/reward states and confirmed elapsed run time and Night Pressure did not advance.
- [x] Restarted a supplied seed with identical decisions and matched encounter/lane selections; 50 extra cosmetic draws left gameplay selections unchanged.
- [x] Restarted into one clean Jax actor with zero enemies, reservations, loot, thresholds, timer/Pressure/Heat, pending rewards, and stream draws; finite cooling stock reset to authored values.
- [x] Exercised Fire Hydrant damage/cooldown, manual/full-value coin collection, Help, fullscreen, `F1`, and `F2` during the run lifecycle.
- [x] After owner playtest feedback, reproduced reward selection and verified one mouse press/release applies the prepared standard reward and continues the run; stable per-frame button presentation also covers Subway, shop, and extraction actions.
- [x] Re-captured the native 640 x 360 HUD and confirmed the compact `AUTO • FULL VALUE` line remains inside the Run Resources border.
- [x] Exported local Windows and Web builds. Windows passed headless and hidden-window startup smoke checks. The locally served Web build rendered the live HUD, unlocked audio, toggled Help, entered/exited fullscreen, and had no warning/error console messages.
- [x] Captured `res://docs/screenshots/milestone_3_complete_run_structure.png`.

Honest limitations:

- The final-boss actor, encounter logic, art/audio, and production victory path belong to later milestone content. Milestone 3 verifies only the required latch, queue, intro, active transition, and typed result seam.
- The current encounter set reuses Street Punk placeholder presentation; elite availability is data/tier behavior without later Viper Enforcer content.
- The generated Web shell retains its existing focused-canvas zoom limitation; the exercised fullscreen control remains the presentation-scale alternative.
- No publication or GitHub Pages redeployment was performed.

**Milestone 3 technical acceptance result: Passed.** Every explicitly authorized technical Milestone 3 criterion is satisfied. No Milestone 4+ system is started by this record.

### Milestone 4 — nine-item equipment and synergy matrix

Status: **Executed — passed**

The development/test profile must expose all nine catalogue entries:

| Item | Required tags relevant to matrix validation |
| --- | --- |
| Spiked Bat | `MELEE`, `BLEED`, `KNOCKBACK` |
| Shock Gloves | `TECH`, `SHOCK`, `FAST` |
| Reinforced Jacket | `DEFENCE`, `STREET` |
| Hacker Deck | `TECH`, `INTERVENTION` |
| Steel-Toe Boots | `KNOCKBACK`, `MOBILITY` |
| Serrated Wraps | `BLEED`, `FAST` |
| Magnetic Flail | `TECH`, `KNOCKBACK` |
| Voltaic Blade | `TECH`, `BLEED` |
| Chain Sneakers | `FAST`, `KNOCKBACK` |

Automated matrix checks:

- [x] Enumerated all 36 unordered pairs of distinct catalogue items through the same tag aggregation path used at runtime; generic slots allow every pair to be evaluated.
- [x] Knockback 2 activates for the six expected pairs among Spiked Bat, Steel-Toe Boots, Magnetic Flail, and Chain Sneakers.
- [x] Bleed 2 activates for exactly the three pairings among Spiked Bat, Serrated Wraps, and Voltaic Blade.
- [x] Tech 2 activates for the six expected pairs among Shock Gloves, Hacker Deck, Magnetic Flail, and Voltaic Blade.
- [x] Each primary synergy therefore has at least three valid two-item activation combinations without hard-coded equipment-ID branches.
- [x] The bridge tags are present on Spiked Bat (`BLEED`/`KNOCKBACK`), Magnetic Flail (`TECH`/`KNOCKBACK`), and Voltaic Blade (`TECH`/`BLEED`), satisfying the requirement for at least two cross-category bridge items.
- [x] Equipping or replacing an item recalculates once, emits correct activation/deactivation events, and removing an item can deactivate a threshold.
- [x] Equipment modifier aggregation remains independent of concrete UI nodes.

Preview and presentation checks:

- [x] For every candidate against every legal current loadout, the preview reports all synergies activated immediately and progress opened toward every alternative primary synergy.
- [x] Preview results exactly match a non-mutating `SynergySystem` evaluation and do not equip the item, consume a reward, or change authoritative tags.
- [x] The UI shows tag name, current count, threshold, active state/effect, immediate activation, and alternative-path progress without relying on colour alone.
- [x] Manual build review demonstrated three visibly distinct builds and confirmed bridge choices create a legible tradeoff between completing one synergy and opening another.

Additional deterministic coverage passed for exactly nine unique stable IDs; Resource tag/modifier/effect validation; slot equip/replace/remove and duplicate/invalid rejection; stable modifier/effect/tag aggregation; immediate recalculation; exact Knockback/Bleed/Tech derived effects; signal deduplication; generic future 2/4/6 threshold data; stable candidate ordering; same-seed replay; different-seed variation; equipment-only stream consumption; cosmetic isolation; full-slot preview consequences; exactly-once reward application; one-click regression; equipment-derived health, heavy-hit/conditional damage, movement/attack speed, knockback/environmental damage, intervention cooldown, Bleed, Shock, and clean restart.

#### Milestone 4 execution record

- Passed **106/106 tests and 1,306 assertions with no failures or skips**. All **75 Milestone 1–3 tests and 1,100 assertions** remain preserved; Milestone 4 adds 31 tests and 206 assertions.
- Normal reward choices acquired Spiked Bat, Voltaic Blade, and Magnetic Flail, immediately activating Bleed 2, then Knockback 2 and Tech 2. A full-slot Shock Gloves replacement preview correctly reported lost thresholds; the applied replacement left only Tech 2. Subsequent removals deactivated Tech without duplicate signals.
- Seed 424242 generated the same `steel_toe_boots`, `serrated_wraps`, `hacker_deck` choices before and after 20 extra cosmetic draws. Clean same-seed restart reset all seven draw counts, slots, tags, synergies, modifiers, statuses, and pending modal/token state.
- Representative live builds were distinct: Bat/Boots/Chain raised movement and knockback/environmental displacement; Bat/Wraps/Blade produced six-stack Bleed capacity and conditional damage; Gloves/Hacker/Blade reduced Hydrant cooldown to 6.0 seconds and extended Shock to 6.0 seconds.
- Equipment changes left Heat and Night Pressure unchanged. Extraction, defeat, and boss-threshold flows remained valid with equipment active. Hydrant, coins, Help, sound unlock, fullscreen delivery path, `F1`, and `F2` remained usable.
- The 640 x 360 configured run and evidence capture kept all slot, effect, threshold, preview, and replacement copy inside panel borders. The embedded runner reported its expected informational windowed-only fullscreen limitation.
- Fresh local release Windows and Web exports succeeded. Windows passed a 180-frame headless startup smoke. The locally served Web build rendered the live equipment UI, accepted the sound-unlock gesture, applied Serrated Wraps to slot 1 with one ordinary click, closed the modal, and produced no browser-console warnings or errors.
- Fresh Godot editor/game output contained no task-introduced parser errors, runtime errors, warnings, failures, or skips. No publication or GitHub Pages redeployment was performed during that technical-verification pass; the cumulative Milestone 4–4.2 baseline was subsequently committed to `main`, pushed, and published from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`.

**Milestone 4 technical acceptance result: Passed.** Random schema version 1 remains unchanged. Equipment effect chance draws and equipment reward choices share the existing `equipment` stream, so replay of later choices requires identical equipment decisions, proc resolutions, and authoritative timing. Work stopped before Milestone 5 at the time of this acceptance record; Milestone 5 was authorized separately later.

### Milestone 4.1 — equipment safety and HUD readability correction

Status: **Passed — technical verification on Godot 4.7, 2026-07-19**

This follow-up corrects playtest-reported readability and inventory hazards without reopening any Milestone 0–4 acceptance decision and without starting Milestone 5. The two new suites are `milestone_4_1_inventory_safety_suite.gd` and `milestone_4_1_inventory_ui_suite.gd`; the final totals below come from the executed test runner.

#### Planned/executed coverage matrix

| Contract | Automated coverage present | Executed result |
| --- | --- | --- |
| Exactly three ordered backpack slots with finite capacity | Yes | **Passed** |
| Stored items contribute no active tags, modifiers, triggered effects, new triggered status applications, or synergy progress | Yes | **Passed** |
| Duplicate stable-ID ownership rejects across active and backpack positions | Yes | **Passed** |
| Equipping into an occupied active slot atomically stores the outgoing item | Yes | **Passed** |
| Full six-position inventory rejects every unconfirmed eviction | Yes | **Passed** |
| Confirmed full-inventory acquisition replaces only the exact named stored item | Yes | **Passed** |
| Active/backpack swap preserves both items and recalculates the active build | Yes | **Passed** |
| Move-to-backpack replacement requires confirmation | Yes | **Passed** |
| Stale inventory revisions and wrong expected identities reject without mutation | Yes | **Passed** |
| Named discard clears only the explicitly confirmed active or stored item | Yes | **Passed** |
| Clean restart clears active slots, backpack, ownership, synergies, modifiers, effects, and old revisions | Yes | **Passed** |
| Reward candidates exclude items owned in either area while preserving stable-ID ordering and equipment-stream ownership | Yes | **Passed** |
| Confirmed Equip, confirmed Store, and Keep Current Build each resolve the paired reward exactly once | Yes | **Passed** |
| Ordinary active-item click opens inspection and emits no mutation intent | Yes | **Passed** |
| A full loadout opens with no default choice or oldest-slot replacement target | Yes | **Passed** |
| Reward item selection, destination selection, exact leave-behind selection, and final confirmation are separate stages | Yes | **Passed** |
| Clear-selection and Keep Current Build are safe exactly-once alternatives | Yes | **Passed** |
| Native viewport is 1280 x 720 with `viewport`/`keep`/`integer`, nearest filtering, unchanged logical world center, and 2× camera zoom | Yes | **Passed** |
| HUD labels/buttons meet the 16-pixel minimum and all root/panel children remain contained | Yes | **Passed** |
| Journey/onboarding names Hideout, Patrol, Fight, Gear, Exit/Boss, and safe item inspection | Yes | **Passed** |
| All nine item icons and all three synergy badges load, are square, and have at least 64-pixel source dimensions | Yes | **Passed** |
| All preserved Milestone 1–4 suites remain green | Existing suites retained | **Passed** |

#### Manual configured-project matrix

- [x] Launched the configured project directly into `/GameRun` at a native 1280 x 720 presentation viewport; logical fight/stage framing remained unchanged.
- [x] Inspected the sharp native HUD and DebugOverlay at 1280 x 720 plus fullscreen scaling; authored containment coverage passed at the design viewport.
- [x] Confirmed Help and the journey strip explain `HIDEOUT → PATROL → FIGHT → GEAR → EXIT/BOSS`, the next objective, and inspection-only item clicks.
- [x] Used real pointer input for item selection, active destination review, named confirmation, and exactly one Confirm; a second confirm could not duplicate application.
- [x] Clicked an active item and confirmed inspection alone did not change equipment or inventory revision.
- [x] Staged a named discard, reviewed the danger text, selected Cancel, and confirmed the item remained owned.
- [x] Re-exercised Hydrant no-target rejection, Help, sound unlock, fullscreen, and the configured `F1`/`F2` handlers.
- [x] Inspected fresh cursor-bounded Godot logs; no current parser error, runtime error, warning, failure, or skip remained.
- [x] Captured `res://docs/screenshots/milestone_4_1_inventory_readability.png`.

Full-six-position eviction, direct Store acquisition, occupied replacement, Keep Current Build, move/swap, confirmed discard, restart, and run-ending combinations were not manually repeated for this correction. Their deterministic M4.1 coverage passed, and the unchanged extraction/defeat/boss/restart behavior retains the recorded Milestone 4 runtime result.

#### Execution record

- Final cumulative automated result: **132/132 tests and 1,584 assertions passed; 0 failures, 0 skips, 11 suites.** This preserves all 75 Milestone 1–3 tests/1,100 assertions and adds 26 dedicated M4.1 tests/249 assertions. The existing 31 M4 tests remain present with 29 strengthened assertions.
- Configured `/GameRun` manual result: **Passed for changed interaction and presentation paths** using the real pointer flow described above; fresh cursor-bounded logs were clean.
- Determinism result: candidate filtering now excludes every owned active/backpack stable ID while preserving sort order and the `equipment` stream. Schema 1 remains valid because pre-backpack candidate states are unchanged, backpack ownership is explicit decision state, and derivation/draw-without-replacement semantics did not change.
- Updated visual evidence: `res://docs/screenshots/milestone_4_1_inventory_readability.png`.
- Local Windows result: fresh release export passed and the executable completed a clean 180-frame headless startup smoke.
- Local Web result: fresh release export rendered the sharp 1280 x 720 UI; sound unlock, reward selection/confirmation, inventory inspection, discard cancellation, Help, fullscreen, and Hydrant input passed with no console warnings/errors.
- Remaining tooling limitations: the portable headless export editor printed an ObjectDB-profiler `user://` directory message after successful exports, but exported runtimes did not reproduce it. Browser automation did not deliver `F1` to the Web canvas; the unchanged configured runtime handler and automated coverage passed.
- Publication/deployment during the M4.1 correction pass: **Not requested and not performed.** The correction was subsequently included in the cumulative Milestone 4–4.2 `main` release from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9` and the successful Pages deployment at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/).

Selling, buyback, and a broader equipment-shop economy are outside the authorized correction and have no M4.1 acceptance claim. District Cards were unimplemented at the time of this historical M4.1 record and were authorized separately for Milestone 5 later.

### Milestone 4.2 — inventory drag and one-backpack clarity correction

Status: **Passed — technical verification on Godot 4.7, 2026-07-19**

This bounded follow-up adds a tactile, non-destructive input surface over the existing M4.1 inventory transactions. It does not alter `SynergySystem` ownership, the three generic active slots, active-only aggregation, reward randomness, or the random schema, and it does not start Milestone 5. The new suite is `milestone_4_2_inventory_drag_suite.gd`.

#### Executed automated coverage matrix

| Contract | Executed result |
| --- | --- |
| UI names one backpack with three ordered inactive slots and does not imply `PACK 1`, `PACK 2`, `PACK 3`, or separate Store/Equip bags | **Passed** |
| Typed payload records origin, stable equipment ID, source/choice position, inventory revision, encounter identity where applicable, and presentation metadata | **Passed** |
| All three active destinations and all three backpack destinations participate in the drag/fallback surface, including empty third-slot targets | **Passed** |
| Inventory drag is disabled for mutation during combat while item inspection remains available | **Passed** |
| Active-to-empty-backpack slot 3 stages one non-replacing move and mutates only after one Confirm | **Passed** |
| Active-to-occupied-backpack stages an atomic swap rather than move/discard | **Passed** |
| Backpack-to-occupied-active stages an atomic swap rather than replacement loss | **Passed** |
| Reward-to-active slot 3 stages the existing exact destination and applies exactly once only after Confirm | **Passed** |
| Reward-to-backpack slot 3 works through click/tap fallback and drag while preserving exact destination forwarding | **Passed** |
| Full inventory requires the exact named leave-behind target or Skip Gear; no oldest-item/default replacement occurs and the paired run reward remains resolvable | **Passed** |
| Same-area, stale-revision, wrong-origin, and invalid-target paths make no inventory mutation | **Passed** |
| An 8-pixel typed mouse/touch threshold fallback enters Godot `force_drag` with the existing payload when native Web/touch motion does not invoke `_get_drag_data`, without selecting or mutating inventory | **Passed — 7 assertions** |
| Touch thresholding preserves the first armed pointer; a second touch cannot steal or start its drag; native drag begins once without selection or mutation | **Passed — 5 assertions** |
| Dynamic reward targets use compact `ACTIVE n` / `BACKPACK [n]` copy; inventory action targets use `ACTIVE` / `STORE SLOT` / `SWAP SLOT`; key prompts stay within two lines; Help states that clicks never discard; action labels are ASCII-safe | **Passed** |
| All six reward destination controls, all six inventory action-target states, and key two-line prompts fit their authored pixel bounds with the longest catalogue item name | **Passed — 20 assertions** |
| All preserved Milestone 1–4.1 suites remain green | **Passed** |

#### Configured-project and export matrix

- [x] Launched the configured project directly into `/GameRun` and confirmed the native 1280 x 720 HUD clearly presents three generic active slots plus one three-slot inactive backpack.
- [x] Used a real `InputEvent` pointer drag to move Magnetic Flail from active slot 3 toward empty backpack slot 3. The drop staged `move_to_backpack`, preserved revision 6, and named that no item would be lost.
- [x] Pressed the separate Confirm once and observed the authority apply at revision 7; a repeated invocation left revision 7 unchanged.
- [x] Inspected the representative inventory panel at 1280 x 720; no visible label/control overflow, border crossing, multiple-pack language, or hidden third-slot target remained.
- [x] Inspected fresh editor output since cursor 158: zero new lines, warnings, or errors. The game log contained only development-helper registration.
- [x] Captured `res://docs/screenshots/milestone_4_2_inventory_drag.png`.
- [x] Produced fresh Windows and Web exports with exit code 0 and no export warning/error.
- [x] Ran the Windows headless smoke with exit code 0; it loaded `game_run.tscn` plus M4.2 scripts/Resources, emitted no stderr, and reported no diagnostic.
- [x] Loaded the final locally served Web build at 1280 x 720, unlocked sound with one ordinary click, and used real pointer drag to stage Hacker Deck reward→active slot 3 without mutation before Confirm.
- [x] Confirmed the reward with one ordinary click, observed the modal close, opened Build inventory, then used real pointer drag to stage active slot 3→empty backpack slot 3 with the named no-loss consequence and confirmed once.
- [x] Verified the final Web inventory state: active slot 3 empty, backpack slot 3 Hacker Deck; compact ASCII copy showed no glyph boxes, overflow, or border crossing; browser warning/error console was empty.

Occupied cross-area swap, invalid/outside drop, combat lockout, and full-inventory Skip Gear were not manually repeated in this M4.2 runtime pass. Their focused M4.2 coverage passed. Reward dragging and owned-item dragging were both exercised through the final Web build, and the underlying confirmed reward/inventory flows retain the recorded M4.1 configured-runtime result.

#### Execution record

- Final cumulative automated result: **145/145 tests and 1,709 assertions passed; 0 failures, 0 skips, 12 suites.** This preserves all 132 Milestone 1–4.1 tests/1,584 assertions and adds 13 dedicated M4.2 tests/125 assertions. Dynamic longest-item-name fit coverage now contributes 20 assertions across all six reward destinations, all six inventory action-target states, and key two-line prompts; `test_pointer_threshold_fallback_starts_native_drag_without_mutation` has seven assertions; `test_touch_threshold_preserves_first_pointer_and_starts_native_drag` adds five.
- Input contract: built-in typed `Control` drag/drop stages existing revisioned requests; an 8-pixel mouse/touch threshold may call `force_drag` into that same transaction when Web/touch motion misses `_get_drag_data`. The first armed touch keeps ownership of that candidate and cannot be stolen by a second touch. Neither path introduces a second inventory authority or applies at drop time. Click/tap/keyboard destination selection remains available.
- Inventory safety contract: active-to-empty-backpack is a move; occupied cross-area transfers are swaps; same-area, stale, invalid, outside, and combat-locked drops reject without mutation. Destructive discard remains a separate named confirmation.
- Full-inventory contract: the player chooses the exact item left behind or **Skip Gear**; skipping equipment preserves the paired standard reward.
- Determinism result: no equipment candidate, stream ownership, stable ordering, draw semantics, or random schema changed.
- Configured `/GameRun` result: **Passed for the changed owned-item drag path.** The drop staged a named lossless move without mutation; Confirm applied once and repeat invocation did not duplicate it.
- Fresh-log/visual result: **Passed.** Cursor-bounded logs were clean and `res://docs/screenshots/milestone_4_2_inventory_drag.png` shows the contained 1280 x 720 one-backpack state.
- Copy/layout hardening result: **Passed automated verification.** Compact reward and action-target labels, key two-line prompt bounds, explicit click safety copy, ASCII action wording, and 20 longest-name pixel-fit assertions are locked by the M4.2 suite.
- Local Windows result: **Passed.** Fresh export and headless runtime smoke exited 0 without warnings, stderr, or diagnostics.
- Local Web result: **Passed.** The fresh 1280 x 720 build completed sound unlock, reward drag/Confirm, owned-item drag/Confirm, exact final inventory-state checks, ASCII glyph/containment review, and an empty warning/error console.
- Publication/deployment during the M4.2 correction pass: **Not requested and not performed.** The owner subsequently committed the cumulative Milestone 4–4.2 baseline to `main`, pushed it, and successfully published it from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9` at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/).

Selling, salvage, buyback, auto-sell/auto-salvage, rarity tiers, uniques, affixes, set items/set bonuses, and category-locked equipment slots are outside M4.2 and remain unimplemented. District Cards were unimplemented at the time of this historical M4.2 record and were authorized separately for Milestone 5 later.

**Milestone 4.2 technical acceptance result: Passed.** Work stopped before Milestone 5 at that time. No semantic version is inferred for the later `1b3d5a5118ad31d864266ec2aefd44e652ffafe9` publication.

### Milestone 5 — District Cards

Status: **Passed technical verification on Godot 4.7, 2026-07-19**

Milestone 5 implements the complete bounded District Cards system without starting Milestone 6. `DistrictCardDefinition` and `CardEffectDefinition` are typed, data-only Resources. `CardSystem` owns finite pile/hand/discard state, card-stream selection, planning and staged placement, pending/resolved effect records, reward acquisition, and exactly-once token ledgers; `PatrolController` owns the authored route position and revisioned future-route modifications; `RunDirector` remains the only Heat/Night Pressure authority; and `GameHUD` remains presentation and typed-intent forwarding only.

#### Executed automated coverage matrix

| Contract | Executed result |
| --- | --- |
| Exactly four valid, unique stable IDs — `arcade`, `convenience_store`, `gang_hideout`, and `subway_entrance` — with `FREE` cost, icons, tags, Heat values, node types, progression copy, and typed effects | **Passed** |
| One-copy four-card deck, deterministic two-card opening draw, capacity-three hand, draw/hand/discard snapshots, immediate discard on confirmed play, and no reshuffle during M5 | **Passed** |
| Restart clears deck, hand, discard, pending/resolved effects, route modifications, modal/planning state, revisions/tokens, reward latches, and `cards`-stream state before rebuilding the deterministic opening hand | **Passed** |
| Exactly five stable future occurrence/route-slot identities, one card per occurrence, route revisions, and no stacking | **Passed** |
| Travel-only versus encounter-only placement rules accept valid future slots and reject wrong-type, current, past, expired, occupied, outside, invalid, and stale placements | **Passed** |
| Every rejection leaves Heat, Night Pressure, hand/draw/discard, pending/resolved route state, rewards, and all stream draw counts unchanged | **Passed** |
| Confirm requires exact hand/route revisions and a one-time token; successful play moves one card to discard, creates one pending effect, and applies its Heat delta exactly once | **Passed** |
| Route effects resolve exactly once only when the stable future occurrence is reached; route/minimap snapshots expose pending and resolved changes | **Passed** |
| Arcade creates one non-recursive standard encounter and advances the resulting standard reward by one eligible authored tier on the existing 0/1/3 ladder, clamped to the catalogue | **Passed** |
| Convenience Store permits at most one purchase using existing finite shop/cooling stock, without replenishing stock or creating another economy | **Passed** |
| Gang Hideout uses the scaled elite-eligible `viper_signal` placeholder and guarantees the normal equipment-choice phase without introducing a Milestone 6 actor | **Passed** |
| Subway Entrance skips exactly one upcoming baseline standard encounter without consuming/replenishing Subway charges | **Passed** |
| Cards never reduce Night Pressure, reopen extraction thresholds, clear/bypass a boss latch or queue, skip extraction progression, or override boss precedence | **Passed** |
| Supplemental card rewards follow, rather than replace or mutate, the standard/equipment reward contract and occur only after eligible baseline non-elite standard encounters | **Passed** |
| Card-created encounters, elite encounters, shops, reroutes, and card effects cannot recursively award cards | **Passed** |
| Card rewards offer up to three remaining valid cards, acquire the selected stable ID once, preserve non-selected cards, and provide **Skip / Keep Hand** at hand capacity | **Passed** |
| Opening and reward candidates are filtered and sorted by stable card ID before selection with only `cards`; `encounters`, `spawns`, `rewards`, `equipment`, `enemy_variants`, and `cosmetic` remain isolated | **Passed** |
| Same-seed opening/reward replay, documented multi-seed variation, cosmetic isolation, other-gameplay-stream isolation, and schema-1 preservation | **Passed** |
| Planning is limited to safe `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE` states; its owned pause prevents eligible time and Night Pressure from advancing | **Passed** |
| Unsafe progression synchronously ends planning and clears the staged token; stale confirmation then rejects before Heat, route, hand, or discard mutation | **Passed** |
| Typed mouse/touch drag, 8-pixel fallback, first-pointer ownership, invalid/outside snap-back, right-click cancellation, and click/tap/keyboard placement share the same validation/confirmation path | **Passed** |
| Card names, placeholder icons, `FREE`, Heat, node effect, tags, progression implications, pile counts, five textual slot statuses, valid highlights, feedback, and pending/resolved route preview remain contained at 1280 x 720 | **Passed** |
| Help, sound unlock, fullscreen, `F1`, `F2`, Hydrant, coins, equipment UI, and inventory drag contracts remain present | **Passed regression coverage** |
| All preserved Milestone 1–4.2 suites remain green | **Passed** |

#### Automated execution record

- `milestone_5_card_system`: **13/13 tests, 307 assertions**.
- `milestone_5_card_ui`: **15/15 tests, 214 assertions**.
- `milestone_5_route_effects`: **15/15 tests, 220 assertions**.
- Milestone 5 addition: **43/43 tests, 741 assertions**.
- Preserved Milestone 1–4.2 baseline: **145/145 tests, 1,709 assertions**.
- Final cumulative result: **188/188 tests and 2,450 assertions passed; 0 failures, 0 skips, 15 suites.**

The resource/system suite locks finite deck state, candidate ordering and stream ownership, reward acquisition, revision/token rejection, immutable invalid transactions, exactly-once discard/Heat behavior, planning-time pause, and clean restart. The UI suite covers typed drag payloads/targets, mouse/touch thresholds and first-pointer ownership, right-click cancellation, invalid/outside return, click/tap/keyboard fallback, focus transfer to Confirm, textual slot states, route/minimap snapshots, and native-view containment. The route-effects suite composes the production run authorities to verify all four authored effects, reward tier advancement, finite shop stock, guaranteed equipment, exact baseline skip, non-recursion, extraction/boss precedence, irreversible Night Pressure, correct future occurrence timing, and ending/restart cleanup.

#### Authored catalogue and resolution contract

| Stable ID | Cost / tags | Valid future node | Confirmed Heat | Exactly-once reached-node effect |
| --- | --- | --- | ---: | --- |
| `arcade` | `FREE`; `FIGHT`, `REWARD` | `travel` | +10 | Starts one standard placeholder fight, grants no card reward, and advances its standard reward exactly one available authored quality tier, clamped. |
| `convenience_store` | `FREE`; `SHOP`, `RECOVERY` | `travel` | -10 | Opens one purchase from the existing two-use, 60-coin/18-Heat finite shop-cooling stock; it neither replenishes stock nor adds an economy. |
| `gang_hideout` | `FREE`; `ELITE`, `EQUIPMENT` | `encounter` | +20 | Starts scaled elite-placeholder encounter `viper_signal`, guarantees its normal eligible equipment choice, and grants no card reward. |
| `subway_entrance` | `FREE`; `REROUTE`, `SKIP` | `encounter` | -15 | Reroutes past exactly that one baseline standard encounter without changing the existing two-charge Subway intervention. |

Confirmed placement applies Heat immediately and once; it does not wait for route resolution. The future encounter, shop, reroute, or reward adjustment resolves once only when the identified occurrence is reached. `RunFlowController` checks extraction/boss progression at the safe boundary first, so a pending card cannot bypass a queued boss or consume an occurrence while an extraction decision is unresolved. Declining extraction returns to that same occurrence.

The specification phrase "increased upgrade choice quality" is implemented, under the owner-approved provisional rule, as one step through the existing authored standard-reward quality tiers `0 -> 1 -> 3`, clamped at tier 3. No new general upgrade system, card currency, card shop, or card economy was introduced.

#### Configured-project and manual record

- [x] Launched the configured project directly into `/GameRun` and observed the deterministic two-card opening hand, two-card draw remainder, empty discard, and five stable future slots.
- [x] Completed an eligible baseline encounter through its existing reward path and observed the separate supplemental card offer; skipping equipment did not lose the ordinary reward, and the card phase did not recurse.
- [x] Opened planning in a safe shop state, selected a hand card and future slot through keyboard focus, staged without mutation, then confirmed Gang Hideout once. Hand/discard/pending state changed once, Heat moved from 4 to 24, Night Pressure remained 10.3456, and card/random-stream draw counts did not change during placement.
- [x] Confirmed the pending Gang Hideout marker and textual occupied route slot were visible in the route/minimap preview at the native 1280 x 720 presentation.
- [x] Fresh Windows and Web release exports completed with exit code 0. The exported Windows runtime and PCK console-template startup smokes exited 0; the runtime emitted only the engine banner and no diagnostic.
- [x] The locally served final Web export opened at 1280 x 720 and unlocked sound. Real pointer input returned Arcade after an outside drop without changing Heat/hand/discard, then staged Arcade on valid occurrence 4 and applied it once on confirmation: Heat 4→14, hand 3→2, discard 0→1. The route slot became textually `OCCUPIED ARCADE`, with pending/current/past state visible.
- [x] The same Web pass rejected Gang Hideout on the occupied Arcade slot without mutation, then used click fallback to place it on occurrence 3 and applied Heat 14→34 once. Reaching that occurrence produced the scaled `VIPER SIGNAL` placeholder, Hydrant remained usable, and the result guaranteed the ordinary equipment-choice phase. Arcade subsequently resolved into `ARCADE AMBUSH`; a later eligible baseline reward separately offered the only remaining Subway Entrance card.
- [x] Convenience Store was placed on future travel occurrence 9 with Heat 52→42 once. It remained pending when Night Pressure queued the boss; after Subway Entrance acquisition, `BOSS INTRO` took precedence and card planning was locked, demonstrating that the pending card did not clear or bypass the boss. Reloading the Web build returned Heat, equipment, pending/resolved route state, and card presentation to a clean run.
- [x] Help, sound unlock, Hydrant, equipment/Skip Gear, supplemental card reward, extraction continuation, route preview, and clean restart were exercised in the Web pass; configured-project checks retained fullscreen, `F1`, `F2`, coins, equipment inventory drag, and the other accepted controls. The final Web warning/error console was empty and no card panel crossed the 1280 x 720 borders.
- [x] Captured and inspected `res://docs/screenshots/milestone_5_district_cards.png`; it shows the confirmed Arcade transaction, exact pile/Heat change, five future slots, occupied text, and current/past/pending route preview without visible overflow.

All four effects, every invalid/current/past/occupied/stale/outside rejection, same-seed/different-seed/isolation cases, planning-time pause, extraction/defeat/boss combinations, and complete restart cleanup were exercised through the composed deterministic suites. They were not all manually replayed in the configured-project pass above, so the record does not mislabel automated scenarios as separate human input observations.

#### Honest limitations and scope

- Card visuals are replaceable placeholder SVG icons and compact text presentation, not Milestone 6 production art, animation, audio, or tutorial content.
- Gang Hideout deliberately reuses the scaled `viper_signal` Street Punk placeholder infrastructure. It does not implement the Viper Enforcer or any later elite actor.
- Route planning is a fixed authored-route overlay with a rolling five-occurrence window. It is not procedural route generation.
- M5 has one copy of four cards, a hand cap of three, no reshuffle, no card currency, no card shop, and no broader economy or persistence.
- The generated Web shell retains the established focused-canvas/browser shortcut limitations; the visible fullscreen control remains the cross-platform presentation path.
- The portable headless export editor may report its known ObjectDB-profiler `user://` directory message after a successful export. That tooling-only message is not suppressed and must be distinguished from exported-runtime output.
- Reproduction is limited to the same supported build, content revision, random-schema version, seed, ordered decisions/effect resolutions, and authoritative timing context; cross-version or bitwise physics replay is not promised.
- The Milestone 5 work remains local to `codex/milestone-5-district-cards`. It has not been committed, pushed, merged, published, or deployed. The public Pages build remains the Milestone 4–4.2 baseline from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`.

**Milestone 5 technical result: Passed.** Milestone 6 and every later system remain unimplemented and unauthorized.

### Milestone 6 — Vertical-Slice Content and Presentation

Status: **Implementation and cumulative automated coverage passed; manual/export technical acceptance remains pending.**

The working implementation is on `codex/milestone-6-vertical-slice`, based on the accepted Milestone 5/main documentation baseline `3ce274518c5ccf79e53ecd12764b5ae4cd822ebd`. Milestone 5 remains the last fully accepted and published milestone. Milestone 6's automated working-tree record is **244/244 tests, 3,234 assertions, 22 suites, 0 failed and 0 skipped**; this does not constitute complete Milestone 6 technical acceptance. Milestone 6 has not been committed, pushed, merged, published, or deployed, and this section does not imply otherwise.

The build under test must retain the owner's separate pre-existing changes: the tracked/enabled 17-file Godot-AI 3.0.5 update and the two `project.godot` deletions of `window/stretch/aspect="keep"` and `textures/default_filters/use_nearest_mipmap_filter=false`. Milestone 6's intentional `project.godot` additions are the non-gameplay `SaveService` and `AppState` Autoloads. Verification must not count the owner changes as M6 work or silently restore either deletion.

#### Authored automated coverage matrix

Every row below identifies automated coverage that exists in the repository and passed in the final cumulative Godot 4.7 run. Manual and qualitative criteria remain separately pending below.

| Contract | Primary suite(s) | Current record |
| --- | --- | --- |
| Exact actor catalogue contains `jax`, `zoey`, `rex`, `street_punk`, `bat_thug`, `bottle_thrower`, `viper_enforcer`, `the_viper`, and temporary ally `backup_runner`, with valid typed scenes/resources and no roster expansion | `milestone_6_combat_content` | **Passed in cumulative automation** |
| Jax, Zoey, and Rex lock their health/speed/damage/resistance/role distinctions, existing one-item starters, authored basic attacks, environmental/elite/boss modifiers, and Zoey intervention cooldown without actor-ID Shock logic | `milestone_6_combat_content`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Production menu access starts with Jax; locked selection rejects; same-seed restart reuses the latched access snapshot; new-seed start recaptures profile access; each run applies exactly one authored starter before any reward draw | `milestone_6_presentation`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Street Punk is low-health medium-speed melee, Bat Thug is slower/heavier with high knockback, and Bottle Thrower holds 125–180 range and launches a slow/readable projectile | `milestone_6_combat_content` | **Passed in cumulative automation** |
| `bottle_projectile` moves at 105 px/s, lives 2.5 seconds, uses radius 8, resolves once, and performs deterministic swept collision so a crossed target is not skipped by a large step | `milestone_6_combat_content` | **Passed in cumulative automation** |
| Viper Enforcer has one required elite spawn, 420 health, light-stagger armour, control resistance, heavy and 0.75-second-telegraphed charge attacks, 120-coin value, guaranteed normal equipment path, and distinct presentation | `milestone_6_combat_content`; preserved `milestone_5_route_effects`; `milestone_6_game_run` | **Passed in cumulative automation** |
| The Viper has a three-hit combo, 0.80-second charge telegraph, one-shot two-basic-enemy summon, 1.10-second/92-radius area warning, 40% enrage with 1.20x damage/1.25x speed, reduced knockback, maximum stun/control lockout, dedicated bar/music transition, and exactly-once victory | `milestone_6_combat_content`; `milestone_6_game_run`; `milestone_6_audio_tutorial`; `milestone_6_presentation` | **Passed in cumulative automation** |
| Boss charge, summon, and area warning expose distinct text plus ground markers; pause freezes their timers; terminal state/restart/main menu clears markers and boss music; old Milestone 3 boss modal does not cover the M6 boss HUD | `milestone_6_game_run`; `milestone_6_presentation` | **Passed in cumulative automation** |
| Fire Hydrant retains the accepted inclusive authority, damage/knockback/cooldown/preview behavior, adds exact 4-second mechanics-neutral `wet`, and rejects invalid/no-target/cooling requests without mutation | preserved M2 suites; `milestone_6_game_run` | **Passed in cumulative automation** |
| Call Backup spawns exactly two registered allies, consumes one of two charges only after full success, advances only through 12 eligible active-combat seconds, uses a 30-second cooldown, handles Zoey's multiplier, removes defeated/expired allies, rolls back failures, and clears on terminal/restart | `milestone_6_call_backup`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Subway validates charge/state/patrol first, applies -15 Heat before the next route dispatch, advances one non-boss travel segment, retains two finite charges, and cannot reduce Night Pressure or bypass extraction/boss precedence; every rejection is immutable | preserved M3/M5 suites; `milestone_6_game_run` | **Passed in cumulative automation** |
| Numeric keys 1/2/3 and HUD buttons forward Hydrant/Backup/Subway intent to the same typed authorities; validity, charge/cooldown, names/icons/tooltips/feedback, ASCII dynamic text, and pixel fit remain presentation-only | `milestone_6_game_run`; `milestone_6_presentation` | **Passed in cumulative automation** |
| Shared combo uses only eligible time, expires after 2.5 seconds, includes ordinary/environmental hits, records highest combo, and presents textual milestones 10/20/30/50 | `milestone_6_runtime_systems`; `milestone_6_presentation`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Vertical-slice lifecycle retains 1.25-second intro/1.0-second extraction, automates a 2.5-second boss intro, delays run completion for a 2.0-second victory presentation, and keeps pause focus-safe around unskippable transitions | `milestone_6_runtime_systems`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Complete summary reports outcome, duration, seed/schema, maximum Heat, final Night Pressure, encounter/enemy/elite counts, boss result, coins, manual collections/streak, secured Scrap, highest combo, build, and synergies; pending clusters settle as base exactly once before victory/extraction/defeat summaries | `milestone_6_runtime_systems`; `milestone_6_game_run`; `milestone_6_presentation` | **Passed in cumulative automation** |
| Restart Run and Return to Main Menu clear actors, boss state, backup, projectiles, telegraphs, combo, interventions, audio, tutorials, modals, route/cards/equipment, stream state, and presentation; same-seed debug restart is inert at main menu | `milestone_6_game_run`; all preserved restart suites | **Passed in cumulative automation** |
| Cadence tracker measures only `RunDirector` eligible active time, locks 10–20/30–60/120–180-second target bands, records only accepted opportunities, and refuses to classify a coin event as strategic | `milestone_6_runtime_systems`; `milestone_6_game_run` | **Passed in cumulative automation; long-form cadence violations remain TODO** |
| Settings expose master/music/SFX volumes, fullscreen/windowed, screen shake, damage numbers, hit-flash reduction, and focus-loss pause; values sanitize/apply to correct buses/presentation and settings persistence reports failures truthfully | `milestone_6_persistence_settings`; `milestone_6_presentation`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Save version 1 supplies defaults for missing optional fields, filters/uniquifies stable IDs, round-trips atomically through an injected path, recovers malformed/wrong-root data in memory, rejects future-version writes, and resets only the configured profile path | `milestone_6_persistence_settings` | **Passed in cumulative automation** |
| Unlock rules are exactly `first_completed_run_zoey`, `first_elite_defeat_hacker_deck`, `first_extraction_gang_hideout`, and `first_victory_rex`; development/test access remains 3 crew/9 equipment/4 cards; no permanent statistical bonus is serialized or applied | `milestone_6_persistence_settings`; `milestone_6_presentation`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Audio catalogue has district and boss music plus every required SFX category, stable Music/SFX buses, deterministic generated waveforms, boss transition/layer, and wired gameplay/UI cues without gameplay-stream consumption | `milestone_6_audio_tutorial`; `milestone_6_game_run` | **Passed in cumulative automation** |
| Seven contextual prompts are typed, stable-priority, queued once per run, nonmodal, written rather than colour-only, and triggered for controls, coins, interventions, equipment, cards, extraction, and boss | `milestone_6_audio_tutorial`; `milestone_6_game_run` | **Passed in cumulative automation** |
| HUD/menu/settings/summary/boss/tutorial/combo/intervention layouts remain contained and readable at native 1280×720 and representative 1920×1080/2560×1440 viewports, including long summary copy | `milestone_6_presentation` | **Automated bounds passed; manual visual inspection pending** |
| Random schema version remains 1; the exact seven streams, stable filtering/sorting, same-seed replay, independent gameplay streams, and cosmetic isolation remain intact; M6 scheduling, persistence, settings, cadence, tutorials, audio, and presentation introduce no unseeded gameplay random call | preserved M3–M5 deterministic suites; `milestone_6_game_run`; static scan | **Passed in cumulative automation** |
| All accepted equipment, synergy, status, reward, cooling, extraction/boss precedence, finite card, route-placement/effect, inventory drag, coin, Hydrant, Help, display, mouse/touch/keyboard, and restart contracts remain green | all 15 accepted Milestone 0–5 suites in cumulative runner | **Passed; accepted 188/188 baseline remained green** |

#### M6 suite inventory and cumulative gate

| Suite | Authored tests | Primary focus | Final result |
| --- | ---: | --- | --- |
| `milestone_6_runtime_systems` | 6 | lifecycle, summary extension, combo, cadence | **Passed** |
| `milestone_6_call_backup` | 6 | authority, lifetime, rollback, cooldown/charges, cleanup | **Passed** |
| `milestone_6_combat_content` | 9 | roster, crew/basic/elite/boss tuning, encounters, projectile/runtime resistance | **Passed** |
| `milestone_6_persistence_settings` | 7 | defaults, version/corruption, atomic save/reset, unlocks, settings | **Passed** |
| `milestone_6_audio_tutorial` | 6 | audio catalogue/generation/controller and contextual tutorials | **Passed** |
| `milestone_6_presentation` | 9 | access/settings/summary/text cues, 720p/1080p/1440p containment, screen shake | **Passed** |
| `milestone_6_game_run` | 13 | composed menu/run/intervention/pause/boss/outcome/summary/restart/spawn-staging integrations | **Passed** |
| **Milestone 6 addition** | **56** | Seven suites | **Passed** |
| **Cumulative result** | **244** | 188 accepted M0–M5 tests plus 56 M6 tests across 22 suites | **3,234 assertions; 0 failed; 0 skipped** |

The final automated gate is `res://tests/run_milestone_6_cumulative.gd`. Godot 4.7 executed all 15 accepted suites followed by all seven M6 suites and exited 0 with **244/244 tests, 3,234 assertions, 0 failed, and 0 skipped across 22 suites**. The configured headless main-scene boot also opened `/GameRun` cleanly with no parser/runtime warnings, errors, leaked objects, or leaked resources. The cumulative single-process runner still printed the inherited/accepted shutdown diagnostic of **48 ObjectDB instances and 4 resources in use**; focused and long-form diagnostic runners also emitted shutdown-object warnings. Re-auditing runner-only cleanup remains a next-session TODO and these diagnostics must not be hidden or confused with the clean configured-project boot.

#### Configured-project, representative-run, and interaction matrix

- [x] Launch the configured Godot 4.7 project headlessly into `/GameRun` and inspect fresh startup output. The configured main scene boot completed with no parser/runtime warning, error, leaked object, or leaked resource.
- [ ] In an interactive configured-project session, confirm the main menu appears before gameplay draws, start a run, and exercise the changed input/presentation paths below.
- [ ] Complete a representative **8–12 minute Victory** run: select a crew member, decline extraction, reach the boss through ordinary safe-boundary progression, exercise combo/charge/summon/area/enrage/anti-lock behaviors, defeat The Viper, observe victory sequence/music transition, and validate every summary ledger field.
- [ ] Complete a representative **8–12 minute Extracted** run: accept an authored extraction window, confirm no boss bypass/state corruption, settle pending base coins, preserve secured Scrap, and validate the extracted summary.
- [ ] Complete a representative **8–12 minute Defeated** run: allow all permanent crew to become incapacitated through ordinary combat, confirm temporary allies cannot replace the crew result, settle pending base coins, and validate the defeated summary. If debug acceleration is used for a separate cleanup check, label it as debug rather than representative gameplay.
- [ ] Exercise Jax, Zoey, and Rex and record visible/mechanical distinctions: Jax environmental knockback, Zoey speed/cooldown plus an authored Tech/Shock build, and Rex resilience plus elite/boss damage.
- [ ] Exercise Street Punk punch, Bat Thug slow heavy/high-knockback swing, Bottle Thrower spacing/readable projectile, Viper Enforcer armour/heavy charge/reward, and every Viper phase/telegraph/summon/enrage behavior.
- [ ] Exercise Hydrant, Call Backup, and Subway from mouse/touch/keyboard paths; include valid use, cooling/active/exhausted/invalid-state/no-target paths, Call Backup expiry and ally defeat, and proof that every rejection leaves charges/cooldown/Heat/Night Pressure/route/actors/streams unchanged.
- [ ] Verify at least three viable equipment/synergy strategies across the representative paths, preserving all nine catalogue entries, active/backpack behavior, reward drag/Confirm, Skip Gear, statuses, and bridge choices.
- [ ] Trigger all seven tutorials naturally without developer explanation; confirm their text is understandable, dismissible/nonmodal, once-per-run, and does not obscure required combat or interaction targets.
- [ ] Exercise every settings control, pause/resume with Space and visible Pause Menu, focus-loss behavior inside and outside unskippable transitions, application of audio/screen-shake/damage-number/hit-flash settings, and persistence after process restart.
- [ ] Exercise missing clean save, ordinary round trip, missing optional fields, malformed JSON, wrong-root JSON, future version/read-only rejection, and development reset. Safeguard any real production profile; test paths must remain injected/isolated. Confirm no active-run state or permanent stat bonus is saved.
- [ ] Validate the complete summary for Victory, Extracted, and Defeated, including exact seed/schema, eligible duration, maximum Heat, final Night Pressure, enemy/elite/boss counts/result, coins/manual/streak, secured Scrap, highest combo, equipment build, and active synergies; click Restart Run and Return to Main Menu.
- [ ] Repeat same-seed and new-seed restarts and confirm no stale run, actor, boss, projectile, telegraph, backup, intervention, combo, audio layer, tutorial, modal, route, random-stream, card, equipment, or save state.
- [ ] Preserve Help, sound unlock, fullscreen/windowed, `F1`, `F2`, cards, inventory drag, Hydrant, coins, extraction, and existing keyboard/touch/mouse behavior.

#### Cadence measurement procedure

A fixed-seed technical probe (`6062026`) using Rex with starter equipment only reached the boss at 584.983 eligible seconds and naturally ended **Defeated** at 589.517 eligible seconds (9m49.5s). Its cadence snapshot was: ambient 47 opportunities, 12.446-second average, 9 violations, last gap 8.150; strategic 13 opportunities, 44.999-second average, 8 violations, last gap 82.650; major 3 opportunities, 194.994-second average, 3 violations, last gap 181.300. This is deterministic technical evidence, not a representative manual run, owner validation, or cadence acceptance; the individual violations remain next-session TODOs even where an average falls inside a target band.

- [ ] Record the `RunCadenceTracker` snapshot from at least one representative ordinary run, using only `RunDirector.run_elapsed_seconds`/eligible active time rather than wall-clock time.
- [ ] Confirm ambient optional opportunities are approximately 10–20 eligible active seconds apart. Coin **presentation** may be ambient; coin collection remains optional and must not be relabelled as strategic.
- [ ] Confirm meaningful strategic decisions are approximately 30–60 eligible active seconds apart and correspond to accepted reward, equipment/card, or shop opportunities rather than repeated/rejected UI actions.
- [ ] Confirm major risk decisions are approximately 120–180 eligible active seconds apart and correspond to extraction/boss-risk opportunities.
- [ ] Exclude pause, reward/card/equipment/shop modals, introductions, extraction/boss/victory transitions, and every other ineligible period. Record early/late violations honestly rather than averaging them away.
- [ ] Ignore all coin clusters during a representative segment and confirm every cluster still settles its full base value, manual collection remains only a modest capped bonus, and ignoring coins does not make the automatic run substantially nonviable.
- [ ] Confirm coin prompts and hit areas do not obscure combat, require precision clicking, or interrupt automatic action.

#### Resolution, export, runtime, and visual matrix

- [ ] Inspect the HUD, main/pause/settings menus, three interventions, tutorial, equipment/cards, boss bar/telegraphs, and long summary at **1280×720**; record any overlap, clipping, colour-only communication, or illegible text.
- [ ] Repeat containment/readability inspection at representative **1920×1080** and **2560×1440** presentation sizes.
- [ ] Produce a fresh Windows release export at `build/milestone_6/windows/NeonLoop.exe` and a fresh Web release export at `build/milestone_6/web/index.html`; stale `build/desktop` or `build/web` output is not evidence.
- [ ] Launch the exported Windows runtime, confirm `/GameRun`/main-menu startup, exercise a representative runtime path, exit cleanly, and inspect fresh console/runtime output.
- [ ] Serve the fresh Web export locally; unlock sound; exercise keyboard, real pointer, and touch-equivalent paths for menus, interventions, Help, equipment/inventory drag, cards, settings, fullscreen, pause, boss, summary, and restart; inspect the final warning/error console.
- [ ] Capture and inspect `res://docs/screenshots/milestone_6_vertical_slice.png`, preferably showing an active/enraged Viper, readable named telegraph and ground marker, dedicated boss bar, three labelled interventions, crew/build state, and contained native HUD.
- [ ] Fix every M6-introduced parser error, runtime error, warning, failed/skipped test, export error, and browser-console warning/error. Record any inherited tooling-only diagnostic separately and do not suppress it.

#### Technical-result boundary and owner validation

Automated resource/runtime tests can establish typed authority, exact authored values, immutability, deterministic ordering, state cleanup, and layout bounds. They cannot decide whether the three crew members feel sufficiently distinct, whether boss telegraphs are readable in ordinary play, whether three builds are meaningfully viable, whether tutorials communicate the game without explanation, or whether 8–12 minute cadence is enjoyable. Those observations must remain **Pending owner validation** until the project owner records them; this plan does not invent a passing human result or reopen the accepted Milestone 1 Human Validation Gate.

Current honest limitations while final verification is pending:

- District/boss music and the SFX catalogue are deterministic generated prototype audio, not commissioned production recordings.
- Actor art, icons, hit effects, telegraph markers, and animation are finished prototype presentation intended to be replaceable; final aesthetic quality is an owner judgment.
- A technical Rex starter-only Defeated trace reached 589.517 eligible seconds, but its cadence snapshot still contains 9 ambient, 8 strategic, and 3 major target-band violations. Representative manual cadence quality remains pending.
- Representative manual Victory, Extracted, and Defeated path timings; crew/enemy/boss/intervention feel and readability; three viable builds; tutorial comprehension; settings/save restart checks; resolution inspection; final exports; browser console; and visual evidence have no passing record in this section yet.
- Cumulative automation passed, but the cumulative single-process runner retained 48 ObjectDB instances and 4 resources at shutdown, and focused/long-form diagnostic runners emitted shutdown-object warnings. Runner cleanup remains a TODO even though the configured `/GameRun` headless boot was clean.
- Persistence is deliberately profile/settings/unlock-only. Mid-run saving/replay, permanent stat bonuses, advanced progression, a tenth equipment item, and a fifth card remain unimplemented and out of scope.
- Reproduction remains limited to the same supported build, content revision, random-schema version, seed, ordered decisions/effect resolutions, and authoritative timing context; cross-version or bitwise physics replay is not promised.

**Milestone 6 automated result: Passed — 244/244 tests and 3,234 assertions, 0 failed, 0 skipped. Full technical acceptance: Pending next-session manual/export/evidence TODOs and runner-cleanup audit.** Stop after that Milestone 6 gate; no post-M6 expansion or publication is authorized.
