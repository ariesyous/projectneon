# Neon Loop Test Plan

## Purpose

Testing is milestone-scoped. Milestone 0 verifies the project foundation; Milestone 1 verifies the narrow Combat Lab, automatic combat, and coin-cluster accounting; Milestone 2 verifies the Fire Hydrant intervention, combat-safe space, and targeted presentation/usability improvements. Later checklists do not pretend that deferred gameplay systems are implemented.

## Error policy

- A parser error or runtime error introduced by the current task is a release blocker.
- Warnings must be investigated and either fixed or reported with their cause; they must not be hidden merely to clean the log.
- Visual acceptance requires a running-project check and screenshot when supported.
- Test status must distinguish static inspection from a verified Godot launch.

## Status convention

- **Passed** means the recorded check was actually executed against the stated build.
- **Planned** means the test is a downstream acceptance contract only; an unchecked planned item is not evidence that its system exists or works.
- **Owner-recorded** means only the project owner may enter the result.

Milestone 1 and Milestone 2 technical checks are recorded as executed. Milestone 3 and later suites remain **Planned**; their presence does not start or authorize those milestones. The Milestone 1 Human Validation Gate result is separately labelled as an owner-recorded qualitative decision.

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

### Milestone 3 — Heat and Night Pressure

Status: **Planned — not implemented or executed**

Heat separation and tiers:

- [ ] Heat is clamped to 0–100 and maps exactly to tiers 0 at 0–19, 1 at 20–39, 2 at 40–59, 3 at 60–79, 4 at 80–99, and 5 at 100.
- [ ] Heat changes immediate encounter composition, elite availability, danger, reward quality, and alert presentation without mutating already-earned Night Pressure.
- [ ] Heat 100 does not itself start the boss or permanently close extraction.

Night Pressure invariants and scaling:

- [ ] Night Pressure is non-negative and monotonically increasing throughout a run; cards, shops, interventions, reroutes, extraction decisions, and Heat reduction cannot decrease it.
- [ ] Only ending or restarting a run resets Night Pressure.
- [ ] Eligible active simulation time advances Night Pressure according to the data definition; paused states, modal reward choices, modal shop choices, and non-interactive introductions add exactly zero.
- [ ] Each authoritative encounter completion applies its configured Night Pressure gain exactly once, including duplicate or retried completion notifications.
- [ ] Enemy health, enemy damage, and spawn budget use the active `RunEscalationDefinition` coefficients, clamps, and a documented deterministic spawn-budget rounding rule.
- [ ] Scaled spawn budgets respect both encounter concurrency caps and the global limit of 30 active ordinary enemies.

Thresholds and precedence:

- [ ] Tests immediately below, exactly at, and immediately above every configured extraction threshold and the boss threshold produce the expected single transition.
- [ ] Each extraction or boss threshold latches on first crossing and cannot reopen, clear, or fire twice after Heat reduction, cooling, rerouting, or later updates.
- [ ] Crossing the boss threshold at an unsafe transition boundary sets `boss_queued` and starts the boss exactly once at the next valid boundary.
- [ ] When an extraction threshold and the boss threshold are crossed in the same authoritative update, the boss takes precedence unless extraction was already confirmed before that update.
- [ ] Continued eligible active play and encounter completions eventually reach the boss threshold even when Heat is repeatedly reduced.

Finite cooling and anti-farming:

- [ ] Subway Reroute consumes a finite charge or explicit consumable, has data-driven acquisition and per-run caps, and does not regenerate merely through elapsed time.
- [ ] A zero-charge Subway Reroute request is rejected without changing Heat, Night Pressure, route state, thresholds, or boss queue state.
- [ ] Shop cooling has meaningful cost plus finite stock or an explicit per-run purchase limit; increasing price alone is not treated as a sufficient finite limit.
- [ ] Convenience Store permits only its defined purchase opportunity, and all cooling cards and purchases affect Heat only.
- [ ] Exhausting every cooling card, shop purchase, and reroute can provide temporary tactical relief but cannot postpone the boss indefinitely, reopen a spent extraction window, unlatch a threshold, or clear a queued boss.

### Milestone 3 — deterministic seed and named-stream suite

Status: **Planned — not implemented or executed**

- [ ] `RunDirector` establishes one authoritative integer seed, accepts an optional supplied seed, and records or generates it before the first gameplay random draw.
- [ ] The seed and `random_schema_version` appear in development diagnostics; the seed appears in the run summary and same-seed restart path.
- [ ] `RunRandomStreams` is run-scoped rather than an Autoload and exposes exactly the declared streams `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic` by `StringName`.
- [ ] Known-vector tests lock the documented, versioned, platform-stable sub-seed derivation for every declared stream and reject dependence on process-unstable hashes.
- [ ] A static gameplay-code check rejects direct calls to `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, and `Array.pick_random()`.
- [ ] With the same build, content revision, random-schema version, seed, decisions, and authoritative timing, two runs produce identical encounter, spawn, reward, equipment, card, and enemy-variant selections.
- [ ] A same-seed restart resets every named stream to its expected initial state rather than continuing previous draw positions.
- [ ] Extra `cosmetic` draws do not change encounter, spawn, reward, equipment, card, or enemy-variant outcomes.
- [ ] Extra draws in one named gameplay stream do not perturb the state or outcomes of the other named streams.
- [ ] Candidate filtering followed by stable content-ID sorting produces the same choice when dictionary insertion, scene-tree insertion, source-container, or presentation order changes.
- [ ] Different seeds produce meaningfully different sequences across a documented sample; the assertion does not rely on one possibly coincidental pair.
- [ ] Reproduction reports include seed, build/content/schema versions, ordered gameplay decisions, and authoritative timing context; no test promises cross-version or bitwise physics replay.

### Milestone 4 — nine-item equipment and synergy matrix

Status: **Planned — not implemented or executed**

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

- [ ] Enumerate all 36 unordered pairs of distinct catalogue items through the same tag aggregation path used at runtime; generic slots allow every pair to be evaluated.
- [ ] Knockback 2 activates for the six expected pairs among Spiked Bat, Steel-Toe Boots, Magnetic Flail, and Chain Sneakers.
- [ ] Bleed 2 activates for exactly the three pairings among Spiked Bat, Serrated Wraps, and Voltaic Blade.
- [ ] Tech 2 activates for the six expected pairs among Shock Gloves, Hacker Deck, Magnetic Flail, and Voltaic Blade.
- [ ] Each primary synergy therefore has at least three valid two-item activation combinations without hard-coded equipment-ID branches.
- [ ] The bridge tags are present on Spiked Bat (`BLEED`/`KNOCKBACK`), Magnetic Flail (`TECH`/`KNOCKBACK`), and Voltaic Blade (`TECH`/`BLEED`), satisfying the requirement for at least two cross-category bridge items.
- [ ] Equipping or replacing an item recalculates once, emits correct activation/deactivation events, and removing an item can deactivate a threshold.
- [ ] Equipment modifier aggregation remains independent of concrete UI nodes.

Preview and presentation checks:

- [ ] For every candidate against every legal current loadout, the preview reports all synergies activated immediately and progress opened toward every alternative primary synergy.
- [ ] Preview results exactly match a non-mutating `SynergySystem` evaluation and do not equip the item, consume a reward, or change authoritative tags.
- [ ] The UI shows tag name, current count, threshold, active state/effect, immediate activation, and alternative-path progress without relying on colour alone.
- [ ] Manual build review demonstrates at least three visibly distinct builds and confirms bridge choices create a legible tradeoff between completing one synergy and opening another.

### Milestone 5 — District Cards

Status: **Planned — not implemented or executed**

- [ ] Card placement validation accepts only valid route-node types and returns invalid cards to the hand with immediate feedback.
- [ ] Played cards resolve at the correct route time, move to discard, and update the minimap.
- [ ] Card Heat changes are correct, while no card reduces Night Pressure or bypasses latched extraction/boss progression.
- [ ] Card selection consumes only the deterministic `cards` stream after stable-ID candidate ordering.

### Milestone 6 — cadence and vertical-slice manual checks

Status: **Planned — not implemented or executed**

- [ ] During a representative run, optional ambient opportunities occur approximately every 10–20 seconds of eligible active play.
- [ ] Meaningful strategic decisions remain approximately 30–60 eligible active seconds apart and are not inflated by relabelling coin clicks as strategic choices.
- [ ] Major risk decisions remain approximately 2–3 eligible active minutes apart.
- [ ] Cadence measurements exclude paused time, modal reward/shop choices, and non-interactive introductions.
- [ ] Ignoring all coin clusters preserves full base rewards and does not make the run substantially nonviable; manual collection remains a modest, capped benefit.
- [ ] Coin prompts and hit areas do not obscure combat, require precision clicking, or interrupt automatic action.

### Later persistence work

Status: **Planned — not implemented or executed**

- [ ] Save defaulting, version migration, and corrupt-save handling fail safely.
- [ ] Any future mid-run save or replay preserves the authoritative seed, build/content/schema versions, state or draw position for every named stream, authoritative run state, and ordered decisions with relevant timing.
