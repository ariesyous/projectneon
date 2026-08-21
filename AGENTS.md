# Neon Loop Agent Guide

This repository is a Godot 4.x project. `GameSpecifications.md` is the product source of truth. Read it in full before changing gameplay, scenes, project settings, architecture, or content.

## Canonical specification path and casing

- The tracked canonical specification is `GameSpecifications.md`, with that exact casing.
- A task brief that says `gamespecifications.md`, `gamespec.md`, or uses another casing is referring to the tracked `GameSpecifications.md`; it does not identify a second specification.
- On case-sensitive filesystems, always open and link the exact tracked filename. Do not create a lowercase alias, rename the canonical file, or attempt to reconcile the mismatch by copying or rewriting the specification.

## WP00-approved product rebaseline

The project owner explicitly approved the complete WP00 recommended D1–D7 package on 2026-08-20. `GameSpecifications.md` section 0 is the prospective product source of truth for WP01–WP07; `docs/product/WP00_DECISION_PACKET.md` records the alternatives/tradeoffs and `docs/product/WP00_ACCEPTANCE_EVIDENCE.md` records the documentation-only gate.

Approved direction:

- North star: plan the next block, watch the automatic build execute, intervene decisively, and Extract or Push through escalating district laps.
- One boss run uses three laps of three blocks. Extract/Push follows laps one and two; pushing after lap two commits to lap three and the boss. Boss-run target is 8–12 eligible minutes.
- District Plan is a focused two-card next-block choice with a lap-scoped one-copy finite deck, resolved history, and no release-facing persistent combat hand/five-slot legality planner.
- Jax, Zoey, and Rex are fresh-production-profile defaults. Historical Zoey/Rex unlocks remain M6 facts but are retired prospectively; Hacker Deck and Gang Hideout remain breadth unlocks.
- Progression may add separately approved breadth, cosmetics, compendium knowledge, optional goals, and challenge contracts, but no permanent statistical power or required grind. Scrap is summary-only until separately specified.
- Permanent combat vocabulary is Environment, Focus, and Backup. Fire Hydrant is an Environment action, Call Backup is Backup, Subway Reroute becomes strategic travel vocabulary, and Rally remains an unpromised WP05 prototype candidate.
- Qualitative gates use five unbriefed participants with the approved 4/5 clarity/consequence/variety/replay thresholds; timing targets are fight 20–45 seconds, block 45–90, lap 120–180, boss run 8–12 minutes, and ambient coins 10–20.

The implementation remains the Milestone 6 codebase until each owning work package lands. Never describe an approved target as already implemented. Preserve all historical M0–M6 verification and current runtime contracts while migrating them prospectively through the correct owner. There is no Milestone 7; the approved future sequence is WP01–WP07, and this WP00 task must not begin WP01.

## Required reading order

1. `GameSpecifications.md`
2. `AGENTS.md`
3. `ARCHITECTURE.md`
4. `IMPLEMENTATION_PLAN.md`
5. The files owned by the requested task

If documentation and implementation disagree with the specification, stop and resolve the conflict instead of silently inventing behavior.

## Current verified state

The last fully accepted baseline is **Milestone 5 — District Cards** on top of completed **Milestone 4.2 — Inventory drag and backpack clarity correction**, **Milestone 4.1 — Equipment usability and HUD readability correction**, and **Milestone 4 — Equipment and Synergies**. **Milestone 6 — Vertical-Slice Content and Presentation** passed its cumulative automated gate and the owner marked it tentatively complete for a GitHub Pages playtest release. Pages run [29960250903](https://github.com/ariesyous/projectneon/actions/runs/29960250903) successfully exported and deployed the Web build from `main` on 2026-07-22. Representative outcome/manual validation, cadence conformance, broader browser/device inspection, and final owner acceptance remain explicitly pending; use `MILESTONE_6_PLAYTEST.md` to collect them without inventing a pass.

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

Milestone 5 adds typed card/effect Resources, exactly four stable-ID `FREE` cards, a finite one-copy authored deck, a deterministic two-card opening hand with capacity three and no reshuffle, five stable future-route slots plus current/past route history, revision/token-validated placement and resolution, supplemental baseline-encounter card rewards, and native drag plus click/tap/keyboard planning presentation. Godot 4.7 verification passed **188/188 tests and 2,450 assertions with no failures or skips across 15 suites**. This preserves all 145 Milestone 1–4.2 tests/1,709 assertions and adds 43 Milestone 5 tests/741 assertions: card system 13/307, card UI 15/214, and route effects 15/220. Configured `/GameRun`, fresh logs, 1280 x 720 containment, Windows export/runtime smoke, and the final local Web pointer/click interaction plus empty warning/error console all passed. Evidence: `res://docs/screenshots/milestone_5_district_cards.png`.

Milestone 5 was implemented in feature commit `7ac7fa0794e79cfc60781b84ce7181f61e16bf7f`, merged through [PR #4](https://github.com/ariesyous/projectneon/pull/4), and published from `main` merge commit `da934897cbdee44cb4d1a44b25e91b458558bfbc`. [GitHub Pages run 29713282074](https://github.com/ariesyous/projectneon/actions/runs/29713282074) completed successfully, and the live 1280 x 720 build at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/) passed its post-deployment smoke check with an empty warning/error console. This supersedes the Milestone 4–4.2 publication from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`, which remains an unchanged historical baseline.

The Milestone 6 working-tree implementation adds the complete three-member crew selection, three basic enemy actors, Viper Enforcer elite, The Viper boss encounter and victory sequence, all three interventions, shared combo and cadence measurement, contextual tutorials, generated district/boss audio, settings/accessibility, version-1 profile/unlocks, complete summary/menu flows, and expanded native 1280 x 720 presentation while retaining the fixed route and every Milestone 5 card/equipment contract. The historical Milestone 3 boss boundary ended at threshold latching and `BOSS_ACTIVE`; Milestone 6 now supplies the boss actor, encounter, telegraphs, music transition, outcome, and delayed victory presentation on the local branch.

## Current scope boundary

Milestone 6 Vertical-Slice Content and Presentation is the implemented runtime boundary and remains the tentative playtest baseline. Its former status as the final prospective stopping boundary was superseded by the owner-approved WP00 roadmap. Only WP01–WP07 work needed to realize the approved product direction is eligible for separate authorization, package by package and behind each owner/acceptance gate.

Procedural route generation; additional districts or broad card/crew/enemy/elite/boss content; multiplayer; controller support; localization; achievements; daily-run scheduling/rewards/leaderboards; permanent statistical progression or stat trees; mid-run saving/replays; equipment selling, salvage, rarity, uniques, affixes, or sets; a card currency/shop/economy; direct character control; and every other undocumented expansion remain out of scope. Future breadth content is a permitted progression category, not pre-authorized content.

Milestone 6 implementation commits are `9c1cdaa` for the separately preserved owner-carried changes and `ca3fe18` for the vertical slice; `a147f93` adds the external playtest guide and tentative-release record. `main` was fast-forwarded through `a147f93`, and Pages run 29960250903 succeeded. That publication authorized only the historical M6 playtest build. WP00 later approved the documentation-defined work-package roadmap as planning, not implementation, new publication, or unbounded post-M6 expansion.

## Owner-carried working-tree changes

- The tracked and enabled Godot-AI addon has a pre-existing owner-carried 3.0.5 update across 17 addon files. It remains development tooling and must not be removed, untracked, ignored, replaced, or described as Milestone 6 gameplay work.
- `project.godot` has two pre-existing owner deletions: `window/stretch/aspect="keep"` and `textures/default_filters/use_nearest_mipmap_filter=false`. Milestone 6 preserves those deletions. They are not part of the Milestone 6 change set and must not be silently restored or attributed to it.
- The Milestone 6 `SaveService` and `AppState` application/persistence Autoload entries are separate authorized additions. They own no active-run gameplay state, Heat, Night Pressure, outcome, or random stream; `_mcp_game_helper` remains Godot-AI development tooling.

## Milestone 5 invariant contracts

These are current implemented compatibility contracts. WP03 may migrate the release-facing hand/five-slot model only after the approved focused District Plan authority, deterministic vectors, stale/replay rejection, safe-boundary precedence, and input evidence exist. Until then, the implementation and tests below remain authoritative facts.

- `DistrictCardDefinition` and `CardEffectDefinition` are typed, data-only Resources. The exactly four one-copy stable IDs are `arcade` (`FREE`, travel, +10 Heat), `convenience_store` (`FREE`, travel, -10 Heat), `gang_hideout` (`FREE`, encounter, +20 Heat), and `subway_entrance` (`FREE`, encounter, -15 Heat); each has validated tags, effect payload, progression copy, and a replaceable icon.
- `CardSystem` owns the finite draw pile, capacity-three hand, discard pile, deterministic two-card opening draw, no-reshuffle rule, planning/staged-placement state, pending/resolved effects, card reward choices/acquisition, hand revisions, and confirmation/token ledgers. Restart clears all of them before resetting the `cards` stream and rebuilding the opening hand.
- `PatrolController` owns current route position and exactly five fixed future modification slots with monotonic occurrence/slot identities, a route revision, one card per occurrence, and textual `valid`, `occupied`, `current`, `past`, `expired`, or `invalid` status. It applies and resolves revisioned modifications; no card/UI code procedurally generates routes.
- Placement is staged, then confirmed with exact hand/route revisions and a confirmation token. Only successful confirmation moves the card to discard, creates the pending route effect, and asks `RunDirector` to apply the card's Heat delta exactly once. Invalid, stale, current, past, expired, wrong-type, occupied, cancelled, or outside drops change no Heat, Night Pressure, pile, route, reward, or random-stream state.
- `RunFlowController` checks extraction/boss precedence at the safe boundary before dispatching the exact current route occurrence. The pending card effect resolves once only when that occurrence is reached; declining extraction returns to the same occurrence. Cards never reduce Night Pressure, reopen extraction, clear/bypass a boss latch or queue, or override boss precedence.
- Arcade creates a non-recursive standard fight and advances its standard reward exactly one existing authored tier, clamped; Convenience Store permits one purchase from existing finite cooling/shop stock without replenishment; Gang Hideout uses the scaled `viper_signal` elite placeholder and guarantees the normal eligible equipment-choice phase; Subway Entrance skips exactly one upcoming baseline standard encounter without consuming/replenishing Subway charges.
- Supplemental card rewards occur only after the existing reward contract for an eligible baseline non-elite standard encounter. They offer up to three remaining valid cards, selected only with `cards` after stable-ID filtering/sorting, acquire once, and support **Skip / Keep Hand**. Card-created encounters, elite encounters, shops, reroutes, and card effects cannot recursively offer cards.
- Planning is available only in safe `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE` states. Patrol planning uses a `RunDirector`-owned pause that ordinary pause input cannot release, so eligible time and Night Pressure do not advance. Any unsafe progression transition synchronously ends planning and clears the staged token; a stale confirmation is then authority-rejected before Heat or route mutation. `GameHUD` only presents hand/piles, typed card details, stable slots, textual validity/highlights, feedback, and pending/resolved minimap changes; typed native drag, 8-pixel mouse/touch fallback, first-touch ownership, right-click cancel, and click/tap/keyboard placement all forward the same validated intent.

## Milestone 6 implementation contracts

These contracts describe the current runtime and historical automated baseline. The WP00 target supersedes only the prospective product choices named above; it does not pretend that all-crew defaults, district laps, focused District Plan, Focus, or the new HUD already exist.

- The exact permanent crew IDs are `jax`, `zoey`, and `rex`; each run selects one member before the first gameplay draw and equips exactly one authored starter. Jax has 520 health, 112 movement speed, 20 base damage, 1.25x environmental-collision damage, and Spiked Bat. Zoey has 400 health, 124 movement speed, 12 base damage, a 0.85 intervention-cooldown multiplier, and Shock Gloves. Rex has 720 health, 84 movement speed, 30 base damage, 0.55 knockback resistance, 0.65 stagger resistance, 1.25x damage against elites/bosses, and Reinforced Jacket.
- The exact basic enemy IDs are `street_punk`, `bat_thug`, and `bottle_thrower`. Street Punk is the 58-health/86-speed basic melee unit; Bat Thug is the 110-health/64-speed heavy melee unit with a 0.58-second windup and 185 knockback force; Bottle Thrower is the 50-health ranged unit that maintains 125–180 pixels and fires the deterministic `bottle_projectile` at 105 pixels/second with a 2.5-second lifetime.
- `viper_enforcer` is the only elite: 420 health, 170 light-stagger armour, 0.75-second maximum stun, 0.80-second control lockout, 120 authored coins, an ordinary heavy attack, and a 0.75-second-telegraphed 240-pixel charge with a 3.5-second special cooldown. `viper_signal` now requires one Enforcer and may add the three basic enemies; its ordinary eligible equipment reward remains authoritative.
- `the_viper` is the only boss: 1,800 health, 0.85 knockback resistance, 0.75 stagger resistance, 220 light-stagger armour, a 0.35-second maximum stun, and a 2.0-second control lockout. Its authored attacks are `viper_melee_combo` (three hits), `viper_charge` (0.80-second telegraph, 280-pixel charge, 4.5-second special cooldown), one-shot `viper_summon` (exactly `street_punk` plus `bat_thug`), and `viper_area_warning` (1.10-second telegraph, 92-pixel radius, 6.0-second special cooldown). At 40% health it enrages to 1.20x damage and 1.25x attack speed. `viper_showdown` is the sole boss encounter and completes only when The Viper is defeated.
- Fire Hydrant keeps its Milestone 2 authority and exact 112-pixel radius, 18 damage, 300-force/0.30-second leftward knockback, and 8.0-second base cooldown. Milestone 6 adds its replaceable icon, complete validity/cooldown/target/tooltip feedback, and one 4.0-second `wet` marker without changing Night Pressure, rewards, or random streams.
- `call_backup` has exactly two finite charges and a 30.0-second base cooldown. A successful tokenized request registers exactly two `backup_runner` temporary allies; their 12.0-second lifetime advances only during eligible combat, and each leaves on expiry, defeat, terminal outcome, or restart. Spawn/registration failure, invalid state, active use, cooldown, and exhaustion reject without consuming the charge/token ledger. Crew and equipment cooldown multipliers compose for Hydrant and Backup.
- Subway Reroute remains the existing finite `RunCoolingController` authority: two charges, -15 Heat, valid only during reroutable non-boss `PATROLLING`, and one fixed-route occurrence advance. Validation completes before mutation; rejection consumes no charge, Heat, route, or random state. It never lowers Night Pressure or clears/bypasses extraction or boss precedence.
- `ComboTracker` owns one presentation-only shared combo. Successful permanent-crew hits and environmental hits continue it, it expires after 2.5 eligible active seconds, retains the run high, and emits milestones at 10/20/30/50. Combo never changes damage, rewards, Heat, Night Pressure, or random-stream state.
- `RunCadenceTracker` records authoritative eligible-time opportunities without scheduling gameplay. Ambient targets are 10–20 seconds, strategic targets 30–60 seconds, and major-risk targets 120–180 seconds. Coin-cluster presentation is ambient only and is explicitly rejected as a strategic event; ignoring coins still grants the full base reward.
- Milestone 6 changes the working-branch escalation rate to 0.07 passive Night Pressure/eligible second, +1.5 per standard encounter, and +3.0 per elite encounter while retaining extraction thresholds 18/36, boss threshold 50, Heat separation, scaling formulae, and the global 30-enemy cap. Non-boss encounters stage their first spawn after 3.0 eligible seconds and later spawns every 12.0 eligible seconds. Lifecycle presentation durations are 1.25 seconds for intro, 1.0 for extraction, 2.5 for boss intro, and 2.0 for victory.
- `GameSettingsData` version 1 owns only presentation/accessibility preferences: Master 0.80, Music 0.65, SFX 0.80, windowed by default, screen shake 0.75, damage numbers on, hit-flash reduction 0.0, and pause-on-focus-loss on. Pause remains a `RunDirector` decision and is unavailable during unskippable intro/extraction/victory transitions. Important state is reinforced with text, shape, labels, and telegraphs rather than colour alone.
- The exact contextual tutorial IDs are `tutorial_run_controls`, `tutorial_coin_cluster`, `tutorial_interventions`, `tutorial_equipment`, `tutorial_district_cards`, `tutorial_extraction`, and `tutorial_boss`. They are stable, once per run, nonmodal, dismissible presentation; they never pause or mutate gameplay.
- The exact generated-audio IDs are looping `music_district_loop` and `music_boss_layer` plus `sfx_boss_introduction`, `sfx_card_placement`, `sfx_coin_auto_collect`, `sfx_coin_manual_collect`, `sfx_coin_streak_increase`, `sfx_defeat`, `sfx_environment_collision`, `sfx_extraction_available`, `sfx_heat_tier_increase`, `sfx_heavy_hit`, `sfx_intervention_activation`, `sfx_knockback`, `sfx_light_hit`, `sfx_night_pressure_warning`, `sfx_ui_confirm`, `sfx_ui_hover`, and `sfx_victory`. Audio and deterministic screen shake are presentation-only and consume no gameplay random stream.
- The version-1 profile path is `user://neon_loop_profile_v1.json`. Production defaults expose Jax, eight existing equipment entries, and three existing cards; only Zoey, Rex, existing `hacker_deck`, and existing `gang_hideout` are gated. The four exact idempotent rules are first completed run -> Zoey, first completed run containing an elite defeat -> Hacker Deck, first extraction -> Gang Hideout, and first victory -> Rex. There is no tenth equipment item, fifth card, permanent stat bonus, mid-run save, or broad progression tree. Debug/development profiles retain full access to all three crew, all nine equipment entries, and all four cards.
- Missing optional profile fields use safe defaults; malformed or wrong-root saves recover in memory without being overwritten; future save versions load read-only; writes use an atomic temporary/backup replacement; and the visible reset-save action is development-only and touches only the configured profile path and its own temporary siblings.
- The complete summary contains Victory/Extracted/Defeated, eligible duration, seed/schema, maximum Heat, final Night Pressure, enemies/elites, textual boss result, coins, manual clusters, maximum streak, Scrap, highest combo, equipment build, and active synergies. It offers same-seed restart, new-seed restart, and Return to Main Menu; terminal/restart/menu paths synchronously clear actors, boss state, temporary allies, projectiles, combo, cadence, interventions, audio/presentation, cards, equipment, and modal state.
- Random schema version remains **1**. Milestone 6 adds no stream and changes no derivation or draw semantics: encounter candidates still use `encounters`, spawn/lane choices use `spawns`, rewards use `rewards`, equipment uses `equipment`, cards use `cards`, enemy variation uses `enemy_variants`, and presentation uses `cosmetic` only where applicable. Boss actions, summons, projectiles, combo, cadence, tutorials, audio synthesis, and screen shake are authored/deterministic and use no unseeded gameplay randomness.

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

Milestone 3 implements the deterministic randomness contract, and the Milestone 6 implementation leaves random schema version 1 unchanged. All gameplay must preserve it.

- `RunDirector` owns one authoritative integer run seed and a run-scoped `RunRandomStreams` child. `RunRandomStreams` is never an Autoload.
- The named streams are exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`.
- A gameplay system may consume only the stream appropriate to its responsibility. Encounter selection uses `encounters`; spawn-table and lane choices use `spawns`; standard rewards use `rewards`; equipment choices and equipment procs use `equipment`; opening card draws and card reward choices use `cards`. Milestone 6 boss actions/summons, Bottle projectiles, Call Backup, combo, cadence, tutorials, generated audio, and screen shake are authored/deterministic and consume no gameplay stream.
- Gameplay code must never call unseeded global randomness such as `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, or `Array.pick_random()`.
- Do not route all systems through one shared random sequence. Extra `cosmetic` draws must never change gameplay outcomes.
- Before a gameplay draw, filter candidates deterministically and sort them by stable content ID. Dictionary iteration order, scene-tree insertion order, Resource order, and presentation order are not selection contracts.
- Random schema version 1 uses `fnv1a32_utf8_v1`: FNV-1a 32-bit over the UTF-8 bytes of `neon-loop|schema:<version>|seed:<integer>|stream:<name>`, with unsigned 32-bit wrap after each multiply.
- Do not change `random_schema_version` unless derivation or draw semantics change incompatibly; document and test any schema change with locked vectors.
- Reproduction claims are limited to the same supported build, content revision, random-schema version, seed, gameplay decisions, and authoritative timing context.

## Current runtime ownership

- `RunDirector`: state graph, eligible time, Heat, Night Pressure, scaling, threshold latches/precedence, card-planning pause ownership, seed, lifecycle/boss/victory timing, outcomes, and summaries
- `RunRandomStreams`: seven isolated deterministic stream states and stable-ID selection
- `PatrolController`: authoritative route position, stable route-occurrence/slot identities, revisioned future-route modifications, safe boundaries, encounter pauses, and finite reroute movement
- `RunEncounterController`: encounter identity, deterministic spawn tables/lanes, selected starting crew, temporary-ally registration/removal, elite/boss accounting, boss encounter dispatch/summons, scaling, caps, completion, and cleanup
- `RunCoolingController`: finite Subway and shop-cooling resources
- `RunFlowController`: typed coordination between run, patrol, encounter, reward, cooling, cards, interventions, combo/cadence snapshots, boss dispatch, route-effect resolution, progression precedence, terminal summary, and presentation intent
- `CombatDirector`: actors, targeting, reservations, authored attack selection, deterministic projectile sweeps, boss telegraphs/summons/enrage/control resistance, hits, equipment modifiers/effects, environmental effects, and combat cleanup
- `RewardDirector`: standard/equipment reward selection and application coordination, card-reward presentation/application delegation without card selection authority, authored reward-tier advancement, coin ledger, at-most-once clusters, and manual streak
- `FireHydrantController`: Hydrant validation, area resolution, rejection, and cooldown
- `CallBackupController`: finite charges, cooldown, tokenized two-ally registration, eligible-combat lifetime, immutable rejection, and exact defeat/terminal/restart cleanup
- `ComboTracker`: presentation-only shared hit count, eligible-time expiry, milestones, run high, and reset
- `RunCadenceTracker`: measurement-only eligible-time opportunity timestamps, category/gap validation, and coin-not-strategic enforcement
- `DisplayController`: presentation-only fullscreen, landscape, and safe-area integration
- `ApplicationSettingsController`: audio/window/accessibility application and focus-pause intent; it never directly pauses gameplay
- `AudioPresentationController`: generated district/boss music and categorized SFX presentation on `Music`/`SFX` buses
- `TutorialPromptController`: stable once-per-run, queued, nonmodal contextual guidance
- `ScreenShakeController`: deterministic presentation-only shake scaled by the persisted accessibility setting
- `ProfileSaveService` (autoloaded as `SaveService`) and `NeonAppState` (autoloaded as `AppState`): versioned JSON persistence, safe recovery, settings, lifetime counters, minimal unlocks, and pre-run content-access snapshots; they are application Autoloads, not active-run gameplay authorities
- `VerticalSliceOverlay` and `GameHUD`: main/pause/settings/summary/boss/tutorial/intervention/build presentation plus typed intent forwarding; neither owns gameplay authority
- `CardSystem`: finite draw pile/hand/discard state, hand capacity, `cards`-stream selection, planning state, placement validation/staging, pending route effects, reward acquisition tokens, exactly-once resolution coordination, and clean restart
- `SynergySystem`: three active equipment slots, one three-slot inactive backpack, unique ownership, revisioned inventory transactions, deterministic active-only aggregation, threshold state/signals, and non-mutating previews

The active run remains scene-scoped. `SaveService` and `AppState` persist only profile/settings/unlock data outside a run; no Neon Loop gameplay Autoload owns run state, Heat, Night Pressure, outcomes, or random streams.

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

Do not describe the implemented Milestone 3–6 directors as logic-free Milestone 0 shells. `CardSystem` is an implemented Milestone 5 authority, and the Milestone 6 actor/boss/intervention/persistence/presentation components above are implemented working-tree systems rather than future placeholders. The automated M6 gate is complete; do not describe full Milestone 6 acceptance as complete until the deferred manual/export/evidence TODO record is resolved.

## Verification requirements

For WP00, verification is documentation-only: prove owner approval, cross-document agreement, valid/rendered wireframes, unchanged gameplay/project/save/external state, and preservation of unrelated changes. Do not launch or mutate the game merely to claim a documentation gate. The runtime requirements below apply when an implementation package changes the project.

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

- **Milestone 5:** 188/188 cumulative tests and 2,450 assertions passed with no failures or skips across 15 suites. The 43 new tests/741 assertions verify the four-card catalogue, finite piles/hand cap/no reshuffle, deterministic opening/reward selection and stream isolation, revision/token-protected placement/acquisition/resolution, immutable rejection paths, all four reached-node effects, progression precedence, planning pause and authority-driven modal cleanup, native drag and pointer/touch/keyboard fallbacks, current/past/expired route history, minimap/preview changes, and clean restart. Configured Godot 4.7 opened `/GameRun`; the final Windows and Web release exports succeeded; the Windows runtime smoke exited 0; and the locally served Web build exercised sound unlock, supplemental acquisition, invalid/outside return, real pointer placement, occupied rejection, click fallback, Gang Hideout's placeholder encounter/equipment result, Hydrant, boss precedence with a pending card, Help, and clean reload. The final local Web warning/error console was empty and the 1280 x 720 panel remained contained. Feature commit `7ac7fa0794e79cfc60781b84ce7181f61e16bf7f` was merged through PR #4 to `main` at `da934897cbdee44cb4d1a44b25e91b458558bfbc`; Pages run 29713282074 succeeded, and the live build passed a 1280 x 720 smoke check with an empty warning/error console. Evidence: `res://docs/screenshots/milestone_5_district_cards.png`.

- **Milestone 6 (tentative playtest release):** Godot 4.7 passed **244/244 cumulative tests and 3,234 assertions with no failures or skips across 22 suites**, preserving all 188 accepted Milestone 0–5 tests and adding 56 M6 tests. A configured headless boot opened `/GameRun` without parser/runtime warnings, errors, or leaks. Pages run 29960250903 successfully exported and deployed the Web build; the live page loaded a visible 1280×720 canvas with title `Neon Loop` and an empty warning/error console. Browser screenshot capture timed out on the continuously rendered WebGL canvas, so fresh visual evidence and real-input browser flows remain playtest work rather than an invented pass. The cumulative runner-only 48-ObjectDB/four-resource shutdown report remains a cleanup-audit TODO. External sessions follow `MILESTONE_6_PLAYTEST.md` for Victory/Extraction/Defeat, actor/boss/intervention/settings/save/restart checks, cadence, resolutions, browsers/touch, and qualitative evidence.

There is no Milestone 7 or later milestone. WP00 replaces the former no-future-work statement with the approved WP01–WP07 sequence in `docs/product/ROADMAP.md`. After WP00, WP01 is the next eligible package, but it must begin only on an explicit owner request; do not start it as part of WP00. Historical M6 playtest evidence remains valid and must not be relabelled as final rebaseline acceptance.
