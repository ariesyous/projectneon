# Neon Loop Implementation Plan

## Current target

**Milestone 0 — Project Foundation: complete**

**Milestone 1 — Combat Lab: technical implementation complete**

**Milestone 2 — Player Intervention: technical implementation and verification complete**

**Milestone 3 — Complete Run Structure: technical implementation and verification complete**

**Milestone 4 — Equipment and Synergies: technical implementation and verification complete**

**Milestone 4.1 — Equipment usability and HUD readability correction: technical implementation and verification complete**

**Milestone 4.2 — Inventory drag and backpack clarity correction: technical implementation and verification complete**

**Milestone 5 — District Cards: technical implementation and verification complete**

**Milestone 6 — Vertical-Slice Content and Presentation: tentatively complete; external playtest and final owner acceptance remain**

**WP00 — Product Rebaseline: owner-approved and documentation-complete on 2026-08-20**

**WP01 — Interface and Visual Language: implemented and technically evidenced on 2026-08-21; owner qualitative checkpoint remains separate; WP02 not started**

The Combat Lab foundation and Fire Hydrant intervention are preserved inside a complete run lifecycle with the verified Milestone 4 equipment/synergy layer, Milestone 4.1 usability/readability correction, bounded Milestone 4.2 drag/backpack-clarity implementation, and the separately verified Milestone 5 District Cards implementation. Technical Milestone 1 acceptance remains the unchanged owner record. Milestone 6 passed its cumulative automated gate, configured headless `/GameRun` boot, and GitHub Pages Web export/deployment. Representative manual paths, real-input browser/device checks, Windows export/runtime, visual evidence, cadence acceptance, and final owner qualitative validation remain under the playtest guide.

**Accepted baseline and playtest publication:** Milestone 5 was merged through PR #4 at `main` commit `da934897cbdee44cb4d1a44b25e91b458558bfbc`; its documentation baseline is `3ce274518c5ccf79e53ecd12764b5ae4cd822ebd`. Milestone 6 was committed on `codex/milestone-6-vertical-slice` as `9c1cdaa` plus `ca3fe18`, and the owner authorized its `main`/Pages playtest publication on 2026-07-22. Milestone 5 remains the last fully accepted result until the owner closes the M6 playtest record.

## WP00-approved prospective roadmap

WP00 preserves all Milestone 0–6 implementation and verification records while superseding Milestone 6's former status as the final prospective boundary. The owner approved the complete D1–D7 package on 2026-08-20: the plan/watch/intervene/push north star; three laps of three blocks; Extract/Push after laps one and two with the second push committing to the boss lap; a two-choice, next-block District Plan backed by a four-card one-copy lap deck; all three crew available on fresh production profiles; breadth/cosmetic/challenge progression only; Environment/Focus/Backup as the permanent combat vocabulary; and the acceptance contract in `TEST_PLAN.md`.

| WP | Prospective outcome | Status after WP00 |
| --- | --- | --- |
| WP00 | Product, architecture, wireframe, and acceptance rebaseline | **Complete; owner approved** |
| WP01 | Interface and visual language | **Implemented and technically evidenced; no gameplay authority change** |
| WP02 | Core three-lap run loop and state clarity | Planned; not started |
| WP03 | Focused District Plan | Planned; not started |
| WP04 | Builds, rewards, and shop consequence | Planned; not started |
| WP05 | Intervention and encounter-variety prototypes | Planned; not started |
| WP06 | World, combat, and presentation polish | Planned; not started |
| WP07 | Integration, balance, and release acceptance | Planned; not started |

The current gameplay/content authority remains Milestone 6 with the WP01 presentation migration integrated. A target statement is not evidence that its owning later work package exists. Each later package requires its own explicit task, branch discipline, tests, runtime verification, documentation, and owner gate where specified.

## WP01 implementation — Interface and Visual Language

**Status: Technical/visual acceptance gate passed on 2026-08-21.** The separate five-person unbriefed roadmap checkpoint remains owner-coordinated qualitative evidence and is not fabricated here. Evidence: `docs/product/WP01_ACCEPTANCE_EVIDENCE.md`.

- [x] Added reusable typography, spacing, surface, border, semantic-state, focus, disabled, touch-target, and animation tokens through `NeonUiTokens`.
- [x] Added one replaceable SVG icon family for resources, phases, common actions/interventions, and equipment/synergy tags.
- [x] Added reusable choice-card, stat-comparison, countdown/status, intervention-button, toast, custom-tooltip, and phase-banner components.
- [x] Converted the live HUD to phase/next-event/countdown first, compact Heat/Night Pressure, compact crew/build inspection, a clear central combat field, and context-sensitive action presentation.
- [x] Added focused current-authority shells for District Plan compatibility, equipment reward, finite shop, current Extract/Push, pause/settings, and summary. Later-package target behavior exists only in the evidence gallery and does not mutate runtime authority.
- [x] Preserved current card/equipment drag, click/tap/keyboard alternatives, first-pointer ownership, right-click cancel, typed signals, revision/token validation, stable ordering, deterministic streams, and current content.
- [x] Added safe-area placement for top/edge/action surfaces, 48-pixel input targets, visible keyboard focus, semantic text/shape cues, long-name ellipsis/tooltips, and progressive disclosure.
- [x] Rendered/inspected eight native states, native safe-area combat, 2560×1440 Web integer scaling, and configured `/GameRun` evidence.
- [x] Passed **254/254 tests and 3,376 assertions** with no failures/skips. The fresh configured `/GameRun` interaction log contains no warning/error/debugger entry.

WP01 intentionally implements no lap/block authority, fresh-profile crew migration, District Plan scheduling/legality migration, Focus mechanic, gameplay content, final WP06 stage art, project-setting change, profile mutation, publication, or deployment. WP02 remains unstarted.

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

- [x] Added exactly nine stable-ID `EquipmentDefinition` Resources plus typed modifier, triggered-effect, status, catalogue, synergy, and synergy-catalogue Resources
- [x] Implemented three generic ordered slots with explicit acquire, empty-slot equip, full-slot replacement, removal, duplicate/invalid rejection, and synchronous clean restart
- [x] Implemented stable deterministic tag, modifier, and triggered-effect aggregation independent of UI nodes and equipment-ID branches
- [x] Implemented data-driven Knockback 2, Bleed 2, and Tech 2 thresholds, derived modifiers, immediate recalculation, and deduplicated typed activation/deactivation signals
- [x] Implemented actor-owned Bleed and Shock behavior and shared combat application for health, heavy-hit/conditional damage, movement/attack speed, knockback, environmental damage, and intervention cooldown
- [x] Implemented deterministic three-choice equipment rewards using only the existing `equipment` stream after invalid/duplicate/equipped filtering and stable-ID sorting
- [x] Implemented exactly-once choice application and preserved one ordinary click/tap selection through the live reward flow
- [x] Implemented a 640 x 360 equipment HUD with three slots, item names/tags/effects, tag counts, active/inactive threshold progress/effects, immediate activations, alternative paths, and full-slot replacement losses/gains
- [x] Preserved six Knockback, three Bleed, and six Tech two-item activation pairs plus the Spiked Bat, Magnetic Flail, and Voltaic Blade cross-primary bridge decisions
- [x] Preserved all 75 Milestone 1–3 tests and added 31 Milestone 4 tests: **106/106 tests, 1,306 assertions, no failures or skips**
- [x] Launched `/GameRun`; exercised normal acquisition/replacement/removal, three visibly distinct builds, previews, Heat/Pressure isolation, cooldown rules, same-seed/cosmetic isolation, extraction/defeat/boss flows, restart cleanup, Hydrant, coins, Help, fullscreen path, `F1`, and `F2`
- [x] Produced clean local release Windows and Web exports, passed a Windows headless startup smoke, and verified Web render/audio unlock/one-click equipment selection with no browser-console warnings or errors
- [x] Captured `res://docs/screenshots/milestone_4_equipment_synergies.png`
- [x] Added no gameplay Autoload and no Milestone 5+ card, content, persistence, progression, procedural, or final-boss behavior

**Milestone 4 technical acceptance status: Passed.** Equipment proc chances and later equipment choices intentionally share the specification-owned `equipment` stream, so replay requires identical build decisions and authoritative effect timing as well as build/content/schema/seed equality. Random schema version 1 did not change. The cumulative M4–M4.2 baseline was subsequently committed to `main`, pushed, and published from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`; this later release record does not change the technical acceptance recorded here.

#### Milestone 4.1 — Equipment usability and HUD readability correction

**Status: Authorized follow-up technically complete and verified.** This is a correction to the completed Milestone 4 interaction/presentation surface, not Milestone 5.

- [x] Migrated the true presentation viewport to 1280 x 720 while preserving the established logical 640 x 360 stage/combat coordinates with `Camera2D` centered at `(320, 180)` and zoomed `Vector2(2, 2)`
- [x] Preserved 16:9 aspect, integer viewport scaling, nearest-neighbour canvas filtering, the explicit default mipmap-filter setting, and pixel snapping
- [x] Re-authored HUD/debug presentation natively at 1280 x 720 with no label or button below 16-pixel text, larger ordinary controls/headings, and panel-containment coverage
- [x] Added generated, replaceable placeholder visuals for all nine equipment items and all three primary synergy badges; icon/badge references remain presentation-only
- [x] Added exactly three ordered backpack slots in addition to the three active generic equipment slots
- [x] Excluded stored items from active tags, modifiers, triggered effects, new triggered status applications, and synergy progress; already-applied actor-owned statuses expire/clear normally; enforced unique stable-ID ownership across all six positions
- [x] Replaced direct reward mutation with item inspection, explicit Equip/Store destination selection, named consequence review, and a separate Confirm action
- [x] Moved an outgoing active item to the first empty or explicitly chosen backpack slot; when all six positions are full, require the exact stored leave-behind item rather than auto-evicting an oldest item
- [x] Added **Keep Current Build** so a player can decline equipment while resolving the paired ordinary reward exactly once
- [x] Changed active/stored item clicks to inspection only; no ordinary inventory click removes or replaces equipment
- [x] Added between-fight move-to-backpack, active/backpack swap, and named destructive-discard confirmation flows; combat permits inspection only
- [x] Added inventory-revision and expected-stable-ID validation so stale modal/inspection requests reject without side effects
- [x] Added a persistent Downtown journey strip and expanded opening guidance for `HIDEOUT → PATROL → FIGHT → GEAR → EXIT/BOSS`, current stage/next objective, and safe inventory use
- [x] Kept equipment reward generation on the isolated `equipment` stream with the existing stable-ID ordering and random schema version 1; filtering now covers all owned IDs, while derivation and draw-without-replacement semantics remain unchanged
- [x] Added deterministic inventory-safety and HUD/input/layout/icon suites
- [x] Passed **132/132 tests and 1,584 assertions with no failures or skips** across 11 suites; preserved all 75 Milestone 1–3 tests/1,100 assertions and added 26 dedicated Milestone 4.1 tests/249 assertions
- [x] Launched configured `/GameRun`; exercised real-pointer select/destination/single-confirm application, inspection-only inventory clicks, named discard review/cancel, journey/Help, Hydrant rejection, sound unlock, fullscreen, and preserved `F1`/`F2` handlers with clean fresh cursor-bounded logs
- [x] Captured `res://docs/screenshots/milestone_4_1_inventory_readability.png`
- [x] Produced fresh local release Windows and Web exports; Windows passed a clean 180-frame headless runtime smoke and Web passed reward/inventory/Help/fullscreen/Hydrant interaction with no console warnings/errors

**Milestone 4.1 technical acceptance status: Passed.** The portable headless export editor emitted an ObjectDB-profiler `user://` directory message after successful exports, but neither exported runtime reproduced it. Browser automation did not deliver `F1` to the Web canvas; the unchanged configured runtime handler and preserved automated coverage passed. This correction is included in the later published M4–M4.2 baseline at `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`.

Selling, buyback, and a broader equipment shop/economy were deliberately not implemented: they exceed the authorized correction and require a separate product/economy decision. District Cards were later authorized only through the bounded Milestone 5 scope below; final-boss content, progression/persistence, procedural generation, and every Milestone 6+ system remain unimplemented.

#### Milestone 4.2 — Inventory drag and backpack clarity correction

**Status: Technical implementation and verification complete.** This is a bounded interaction follow-up to completed Milestone 4.1, not Milestone 5.

- [x] Reworded the inventory surface as one unmistakable backpack containing three ordered inactive slots beside the unchanged three generic active slots
- [x] Added typed `EquipmentDragPayload` data for owned-item and reward origins, stable equipment identity, source/choice position, inventory revision, encounter identity where applicable, and presentation metadata
- [x] Added typed `EquipmentDragSlot` controls using Godot's built-in `Control` drag/drop callbacks, off-tree previews, and valid-target highlighting
- [x] Added an 8-pixel typed mouse/touch threshold fallback that calls Godot `force_drag` with the same payload/preview when Web or touch motion does not enter `_get_drag_data`; it adds no authority path and still requires staging plus Confirm
- [x] Preserved the first armed touch index so a second touch cannot steal or start that pointer's drag transaction
- [x] Kept every drag non-authoritative: a valid drop stages the destination/action and still requires the existing Confirm step
- [x] Made active-to-empty-backpack dragging stage a lossless move, and occupied active/backpack cross-area dragging stage an atomic swap that preserves both items
- [x] Kept same-area drops, invalid targets, outside drops, stale revisions, wrong identities, and combat-locked management non-mutating
- [x] Routed reward dragging through the existing revisioned exact-choice, active/backpack destination, and full-inventory leave-behind flow rather than adding a second acquisition path
- [x] Kept click/tap/keyboard selection and destination controls as the complete fallback; destructive discard remains a separate named confirmation
- [x] Made the full-inventory explanation explicit: choose the exact item left behind or **Skip Gear**, which declines equipment while preserving the paired run reward
- [x] Shortened dynamic reward targets to `ACTIVE n` / `BACKPACK [n]`, inventory action targets to `ACTIVE` / `STORE SLOT` / `SWAP SLOT`, bounded key consequence prompts to two lines, made Help state `CLICKS ONLY INSPECT; NEVER DISCARD`, and replaced unsupported action-arrow glyphs with Web-safe words
- [x] Added coverage for all three active/backpack targets, including third-slot reward and inventory paths, exactly-once confirmation, and non-mutating rejection cases
- [x] Added 20 runtime pixel-fit assertions using the longest catalogue item name across all six reward destination controls, all six inventory action-target states, and key two-line prompts
- [x] Added seven assertions proving the pointer-threshold fallback enters native drag without mutating inventory, plus five verifying touch thresholding and first-pointer preservation
- [x] Passed **145/145 tests and 1,709 assertions with no failures or skips** across 12 suites; all 132 Milestone 1–4.1 tests/1,584 assertions remain preserved and M4.2 adds 13 tests/125 assertions
- [x] Launched configured `/GameRun`; used real `InputEvent` pointer drag to stage Magnetic Flail from active slot 3 to empty backpack slot 3 without mutation, then confirmed exactly once (revision 6→7; repeat stayed 7)
- [x] Inspected fresh cursor-bounded logs with no new warning/error and captured the contained 1280 x 720 state at `res://docs/screenshots/milestone_4_2_inventory_drag.png`
- [x] Produced fresh Windows and Web exports with exit code 0/no export warnings or errors; Windows passed a clean headless load of `game_run.tscn` and the M4.2 scripts/Resources
- [x] Verified the final locally served 1280 x 720 Web build: sound unlock; real pointer reward→active slot 3 staging with no pre-Confirm mutation; one-click application/modal close; active slot 3→empty backpack slot 3 named no-loss staging; one-click Confirm; no glyph boxes/overflow; empty warning/error console

**Milestone 4.2 technical acceptance status: Passed.** No random draw, candidate order, inventory authority, active-slot aggregation rule, random schema, or Milestone 0–4.1 acceptance decision changed. The owner later confirmed successful `main` publication of the cumulative M4–M4.2 baseline from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9` to [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/).

Selling, salvage, buyback, auto-sell/auto-salvage, equipment economy, rarity tiers, uniques, affixes, set items/set bonuses, and category-locked equipment slots remain deliberately unimplemented. Milestone 5 adds only the District Cards scope below; every Milestone 6+ system remains unimplemented.

#### Future equipment experience direction — design backlog, not authorized

The completed behavior remains explicit: **Equip** places an item in one of three generic active slots and powers Jax; **Store** places it in one of three inactive cells in a single backpack; cross-area dragging stages a non-destructive move or swap and still requires Confirm; **Skip Gear / Keep Current Build** safely skips a new item when the six owned positions are full while preserving the paired run reward. There is no current selling, salvage, auto-sell, or auto-salvage behavior.

Owner playtest direction to carry into a separately authorized itemization/UX milestone:

- Evolve the implemented one-backpack/three-active-cell surface toward a fuller Diablo II-style character sheet only if a later product pass demonstrates that more space or deeper item management is needed.
- Preserve the implemented non-destructive drag contract, valid-target feedback, snap-back behavior, and click/tap/keyboard destination/confirmation fallback. Any future leave-behind, salvage, or sale must name the affected item and require deliberate intent.
- Keep **Skip / Keep Current Build** as the always-available full-inventory answer. Later economy work may compare explicit sell, explicit salvage, or player-configured auto-salvage rules, but must not silently destroy an item by default.
- Explore a Diablo II-style character inventory that can be opened while the automatic fight remains visible. A later design must decide whether management is live, slowed, or paused during combat before changing the current between-encounter mutation rule.
- Consider rarity tiers, uniques, affixes, and data-driven set items/set bonuses in a later equipment-content milestone. Stable IDs, deterministic instance/roll ownership, balance, economy, and presentation must be specified before implementation.
- The current active slots remain generic. Category-locked weapon/armor/boots slots would be a separate product change and must preserve valid synergy-build paths if later authorized.

This record captures product direction only. It does not authorize further itemization work or any Milestone 6+ system, and it does not change random schema version 1. The separately authorized Milestone 5 work below is confined to District Cards.

### Milestone 5 — District Cards

**Status: Separately authorized technical implementation and verification complete.** No Milestone 6 or later gameplay/content scope is included.

Implemented data and authority:

- [x] Added typed `DistrictCardDefinition` and `CardEffectDefinition` Resources plus a validated four-entry catalogue with unique lowercase stable IDs, player-facing names/descriptions, replaceable icons, `FREE`/cost `0`, authored Heat deltas, valid node types, uppercase tags, progression implications, and typed effect payloads.
- [x] Authored exactly one copy each of Arcade (`arcade`), Convenience Store (`convenience_store`), Gang Hideout (`gang_hideout`), and Subway Entrance (`subway_entrance`); no additional card, district, card currency, card shop, or card economy was added.
- [x] Made `CardSystem` own the finite draw pile, three-card-cap hand, discard pile, staged/confirmed placement tokens, pending/resolved effect records, reward-choice tokens, revisions, and `cards`-stream draws. A run opens with two cards, confirmed plays move immediately from hand to discard, and discarded cards are never reshuffled in Milestone 5.
- [x] Added supplemental card reward opportunities only after the existing core reward contract for eligible baseline non-elite standard encounters. Card-created encounters, elite encounters, shops, reroutes, and card effects cannot recursively award cards. Each opportunity offers up to three remaining valid draw-pile cards and supports selection exactly once or **Skip / Keep Hand**, including when the hand is full; unselected choices remain in the draw pile.
- [x] Made `PatrolController` own five fixed future route-occurrence slots. Stable slot IDs use `<route-id>::route_slot::<occurrence-index>` and stable occurrence IDs use `<route-id>::occurrence::<occurrence-index>`; snapshots include target position, loop, node identity/type, status, occupation, and route revision.
- [x] Enforced one card per future occurrence and no stacking. Invalid, wrong-node, current, past, expired, occupied, out-of-window, stale-revision, duplicate-token, and outside drops reject without changing Heat, route state, hand/discard state, rewards, or random streams.
- [x] Kept placement transactional: the HUD forwards stable card/slot identity plus hand and route revisions; `CardSystem` stages a confirmation token; confirmation registers the revisioned route modification, moves the card to discard, and then `RunFlowController` asks the sole Heat authority, `RunDirector`, to apply the card delta exactly once. Cancel and invalid/outside drops return the visual card to the unchanged hand.
- [x] Resolve a pending modification exactly once when its authored future route occurrence becomes current, before baseline node dispatch. The placed effect replaces that occurrence's baseline handling, updates pending/resolved route snapshots, and cannot reopen extraction thresholds, clear or bypass a queued boss, change boss precedence, or decrease Night Pressure.

Authored card tuning:

| Stable ID / card | Cost | Heat | Valid future node | Tags | Stable effect ID / exact effect |
| --- | ---: | ---: | --- | --- | --- |
| `arcade` / Arcade | `FREE` (`0`) | `+10` | `travel` | `FIGHT`, `REWARD` | `arcade_standard_encounter_reward_boost`: replaces the reached travel occurrence with one non-recursive standard encounter; its standard reward advances by one eligible authored quality tier and clamps at the existing catalogue maximum. It creates no general upgrade system. |
| `convenience_store` / Convenience Store | `FREE` (`0`) | `-10` | `travel` | `SHOP`, `RECOVERY` | `convenience_store_existing_stock_purchase`: replaces the reached travel occurrence with a shop/recovery visit allowing at most one purchase from the run's existing finite shop/cooling stock. It neither replenishes stock nor creates a broader economy. |
| `gang_hideout` / Gang Hideout | `FREE` (`0`) | `+20` | `encounter` | `ELITE`, `EQUIPMENT` | `gang_hideout_viper_signal_elite`: replaces the reached baseline encounter with the existing scaled `viper_signal` elite-eligible placeholder and guarantees an equipment choice. It adds no Viper Enforcer or other Milestone 6 actor/content. |
| `subway_entrance` / Subway Entrance | `FREE` (`0`) | `-15` | `encounter` | `REROUTE`, `SKIP` | `subway_entrance_reroute_skip`: reroutes the reached future segment and skips exactly that one upcoming baseline standard encounter. It consumes and replenishes no Subway intervention charge, does not reduce Night Pressure, and cannot skip extraction progression or bypass boss precedence. |

Determinism, flow, and presentation:

- [x] Filter invalid/duplicate candidates, sort by stable card ID, and draw only from the existing run-scoped `cards` stream for both the opening hand and reward choices. No card selection consumes `encounters`, `spawns`, `rewards`, `equipment`, `enemy_variants`, or `cosmetic`; extra cosmetic draws cannot change card outcomes. Random schema version 1 and its derivation remain unchanged.
- [x] Limit card planning to safe `PATROLLING`, `SHOP`, and `EXTRACTION_AVAILABLE` states outside active combat. Planning entered from patrol owns a run pause; eligible time and Night Pressure do not advance while that modal pause is active. Unsafe progression synchronously ends planning and clears the staged token, and stale confirmation is rejected before Heat or route mutation.
- [x] Keep the native 1280 x 720 HUD and logical 640 x 360 combat world. The card panel shows hand/draw/discard counts, names, placeholder icons, `FREE`, Heat, node effect, tags, progression implications, five stable future slots, node type/position, explicit status text, valid-placement highlighting, confirmation, and immediate rejection/return feedback. Minimap and route preview snapshots visibly distinguish pending and resolved changes.
- [x] Use typed native `Control` drag payloads/targets with an 8-pixel mouse/touch threshold fallback and first-pointer ownership. Right-click cancels the active native drag; click/tap selection, explicit target buttons, focus navigation, and keyboard activation remain complete alternatives.
- [x] Clear deck, hand, discard, staged/reward tokens, pending/resolved card records, planning/modal state, route modifications, and run-scoped cards-stream state on clean same-seed or new-seed restart.

Final technical acceptance record:

- [x] Passed the full cumulative matrix at **188/188 tests and 2,450 assertions with no failures or skips across 15 suites**, preserving the accepted 145-test/1,709-assertion Milestone 0–4.2 baseline and adding 43 M5 tests/741 assertions.
- [x] Launched configured `/GameRun` and combined direct interaction with the composed deterministic suites to cover the supplemental reward, all four effects, immutable invalid/stale/current/past/occupied/outside paths, cancellation, replay/isolation, restart, extraction/defeat/boss precedence, preserved equipment/Hydrant/coin/Help/display/debug behavior, and 1280 x 720 containment. Automated cases are not mislabelled as separate manual observations.
- [x] Produced fresh release Windows and Web exports. The Windows runtime smoke exited 0; the local Web build passed real pointer drag, click fallback, outside return, occupied rejection, preserved controls, clean restart, and an empty warning/error-console check.
- [x] Captured and inspected `res://docs/screenshots/milestone_5_district_cards.png`; fixed every task-introduced parser/runtime/test failure found during verification and recorded the remaining placeholder/fixed-route/no-reshuffle scope limits honestly.

Milestone 5 deliberately excludes Milestone 6 crew/enemy/elite-actor/boss/intervention/content/presentation/audio/tutorial/settings/persistence/final-summary work; procedural route generation; additional districts/cards; a card currency/economy; equipment selling/salvage/rarity/uniques/affixes/sets; and broad progression or persistence. No Milestone 5 commit, push, merge, publication, or deployment is recorded by this plan.

### Milestone 6 — Vertical-Slice Content and Presentation

**Status: Tentatively complete for external Pages playtesting.** Implementation, authored coverage, the cumulative automated result, and the clean configured headless boot are recorded. The owner-authorized playtest uses `MILESTONE_6_PLAYTEST.md` to collect representative outcome, interaction, browser/device, cadence, presentation, and qualitative evidence without claiming final acceptance in advance.

Implemented vertical-slice content:

- [x] Added an exact nine-entry actor-scene catalogue: permanent crew `jax`, `zoey`, and `rex`; basic enemies `street_punk`, `bat_thug`, and `bottle_thrower`; elite `viper_enforcer`; boss `the_viper`; and temporary intervention ally `backup_runner`.
- [x] Added typed `ActorDefinition`, `AttackDefinition`, and `ProjectileDefinition` fields for roles, ranges, armour/control resistance, elite/boss damage, intervention cooldowns, starting equipment, delivery/impact kinds, special cooldowns, telegraphs, summons, areas, and projectiles. Actor scenes remain composed rather than introducing a combat inheritance hierarchy.
- [x] Made the run begin at a main-menu crew choice with one permanent crew member and exactly one existing starter item. Production defaults expose Jax while the minimal profile gates Zoey and Rex; development/test access exposes all three without adding statistical bonuses.
- [x] Replaced the Milestone 5 `viper_signal` placeholder actor with the actual Viper Enforcer while preserving the encounter's stable ID, authored reward/equipment contract, route-card semantics, Heat/progression protections, and deterministic spawn ownership.
- [x] Added boss encounter `viper_showdown`, exactly one `the_viper`, the existing 50 Night Pressure safe-boundary trigger, a 2.5-second boss introduction, dedicated textual health/phase bar, district-to-boss music transition, 2.0-second victory presentation, and summary transition.

Authored permanent-crew tuning:

| Stable ID | Role-defining actor values | Basic attack | Existing starter |
| --- | --- | --- | --- |
| `jax` | 520 health, 112 movement, 20 base damage, 0.18 knockback resistance, 0.15 stagger resistance, 55 light-stagger armour, 1.25x environmental-collision damage | `jax_basic_punch`: 0.20 windup, 0.08 active, 0.34 recovery, 0.22 cooldown, 52 range, 155 knockback | `spiked_bat` |
| `zoey` | 400 health, 124 movement, 12 base damage, 0.10 knockback/stagger resistance, 35 light-stagger armour, 0.85 intervention-cooldown multiplier | `zoey_rapid_strike`: 0.12 windup, 0.06 active, 0.20 recovery, 0.12 cooldown, 52 range, 70 knockback | `shock_gloves` |
| `rex` | 720 health, 84 movement, 30 base damage, 0.55 knockback resistance, 0.65 stagger resistance, 120 light-stagger armour, 1.25x damage against elites and bosses | `rex_heavy_hook`: 0.38 windup, 0.10 active, 0.52 recovery, 0.42 cooldown, 56 range, 125 knockback | `reinforced_jacket` |

Zoey's authored Shock path continues to use the existing equipment/synergy authority rather than embedding a Shock rule in her actor ID. The three starter items are existing catalogue entries, consume no random draw, and are reapplied after the inventory authority resets on every run.

Authored enemy, elite, and boss tuning:

| Stable ID | Actor/reward values | Authored behavior |
| --- | --- | --- |
| `street_punk` | 58 health, 86 movement, 2 base damage, 40 coins | `street_punk_basic_punch`: 0.31 windup, 52 range, 68 knockback; low-health medium-speed melee baseline. |
| `bat_thug` | 110 health, 64 movement, 8 base damage, 60 coins | `bat_thug_heavy_swing`: 0.58 windup, 56 range, 185 knockback; slow heavy melee attack. |
| `bottle_thrower` | 50 health, 78 movement, 5 base damage, 50 coins; preferred range 125–180 | `bottle_throw`: 0.62 windup, 1.20 cooldown; `bottle_projectile`: speed 105, 2.5-second lifetime, radius 8; deterministic swept collision prevents tunnelling without frame randomness. |
| `viper_enforcer` | 420 health, 78 movement, 15 base damage, 120 coins; 0.55 knockback and 0.50 stagger resistance, 170 light-stagger armour, 0.75-second maximum stun and 0.80-second control lockout | `viper_enforcer_heavy` plus 3.5-second-special-cooldown `viper_enforcer_charge`; the 0.75-second charge telegraph, 240 travel/knockback, increased reward, and distinct palette/outline identify the elite. |
| `the_viper` | 1,800 health, 96 movement, 12 base damage; 0.85 knockback and 0.75 stagger resistance, 220 light-stagger armour, 0.35-second maximum stun and 2.0-second control lockout | `viper_melee_combo` has three hits; `viper_charge` has a 0.80-second telegraph, 4.5-second special cooldown, and 280 travel; one-shot `viper_summon` calls `street_punk` plus `bat_thug` after 0.90 seconds; `viper_area_warning` marks a 92-radius area for 1.10 seconds; at 40% health the boss enters `enraged`, gains 1.20x damage and 1.25x attack speed, and retains anti-lock protections. |

Implemented interventions:

| Stable ID | Authored tuning | Authority and rejection contract |
| --- | --- | --- |
| `fire_hydrant` | 112 radius, 18 damage, 300 fixed-left knockback for 0.30 seconds, 8.0-second cooldown, 4.0-second `wet` status, 0.55/0.28/0.50-second water/impact/rejection presentation | Preserves `FireHydrantController` authority and the accepted inclusive area query, adds completed icon/name/tooltip/validity/preview/feedback, and applies mechanics-neutral Wet to surviving affected enemies. Invalid/no-target/cooling requests remain non-mutating. |
| `call_backup` | Two `backup_runner` allies, 160 health and 10 base damage each; two charges; 12.0 eligible active-combat seconds; 30.0-second base cooldown | `CallBackupController` owns tokens, charges, cooldown, eligible lifetime, spawn/registration rollback, defeated/expired removal, terminal cleanup, and restart cleanup. Zoey's 0.85 cooldown multiplier is applied through typed configuration. Rejected, exhausted, already-active, invalid-state, failed-spawn, and failed-registration requests spend nothing. |
| Subway Reroute | Existing `subway` source, two finite charges and -15 Heat | `RunCoolingController` validates state, charge, and patrol eligibility before spending; accepted use applies cooling before the next authored encounter dispatch, ends the current non-boss travel segment, and advances to the next route node. It cannot reduce Night Pressure, skip an active/queued boss, bypass extraction/boss precedence, replenish charges, or mutate on rejection. |

Implemented runtime, presentation, and persistence systems:

- [x] Added `milestone_6_vertical_slice_escalation`: 0.07 passive Night Pressure per eligible second, 1.5 per standard encounter, 3.0 per elite encounter, extraction thresholds 18/36, boss threshold 50, and the preserved 1% health/0.5% damage/1.25% spawn-budget scaling per pressure point with a 30-enemy global cap. This is a separate authored vertical-slice resource; the accepted Milestone 3 resource remains unchanged.
- [x] Added shared `milestone_6_combo`: a 2.5-second eligible-time expiry and textual milestones 10/20/30/50. Ordinary and environmental hits continue the same combo; pauses and ineligible time do not consume it.
- [x] Added measurement-only `RunCadenceTracker` and `milestone_6_cadence` target bands: ambient 10–20, strategic 30–60, and major 120–180 eligible active seconds. Coin-cluster presentation is ambient; coin collection is explicitly rejected as strategic. Shop, reward, extraction, and boss opportunities are recorded only after their authoritative action succeeds.
- [x] Completed the native HUD/menu/pause/settings/summary presentation with three labelled interventions, one permanent-crew strip, combo, contextual tutorial queue, dedicated boss bar, named ground telegraphs, textual status in addition to colour, screen-shake control, damage-number/hit-flash settings, lossless reward-modal pause/resume, and containment logic for 1280×720, 1920×1080, and 2560×1440.
- [x] Added deterministic generated prototype audio with district loop `music_district_loop`, boss variation/layer `music_boss_layer`, and required cues `sfx_light_hit`, `sfx_heavy_hit`, `sfx_knockback`, `sfx_environment_collision`, `sfx_coin_auto_collect`, `sfx_coin_manual_collect`, `sfx_coin_streak_increase`, `sfx_card_placement`, `sfx_intervention_activation`, `sfx_heat_tier_increase`, `sfx_night_pressure_warning`, `sfx_extraction_available`, `sfx_boss_introduction`, `sfx_victory`, `sfx_defeat`, `sfx_ui_hover`, and `sfx_ui_confirm`. Audio presentation consumes no gameplay random stream.
- [x] Added seven once-per-run nonmodal contextual prompts: `tutorial_run_controls`, `tutorial_coin_cluster`, `tutorial_interventions`, `tutorial_equipment`, `tutorial_district_cards`, `tutorial_extraction`, and `tutorial_boss`. Prompts use explicit text and never become gameplay authority.
- [x] Added master/music/sound-effects volumes, fullscreen/windowed, screen-shake intensity, damage-number toggle, hit-flash reduction, and pause-on-focus-loss. Focus loss emits typed pause intent; intro and boss intro finish before a latched focus pause applies, and ordinary pause remains unavailable during other unskippable transitions.
- [x] Added version-1 JSON profile persistence at `user://neon_loop_profile_v1.json`, safe defaults for missing optional fields, sanitization/stable ordering, atomic replacement, in-memory defaults for corrupt/invalid saves without silently overwriting them, read-only handling for future versions, and a development reset path scoped to the configured profile file. `SaveService` and `AppState` are non-gameplay Autoloads for profile/settings/menu access; active run, Heat, Night Pressure, thresholds, random streams, and outcomes remain scene-scoped under their accepted authorities.
- [x] Kept production unlock scope exact: completing any run unlocks `zoey`; a completed run with an elite defeat unlocks existing equipment `hacker_deck`; extraction unlocks existing card `gang_hideout`; victory over The Viper unlocks `rex`. Production starts with Jax, the other eight existing equipment entries, and the other three existing cards; development/test profiles retain all 3/9/4 catalogue entries. No tenth item, fifth card, permanent stat bonus, progression tree, or mid-run save was added.
- [x] Extended the immutable run summary with result (`VICTORY`, `EXTRACTED`, or `DEFEATED`), eligible duration, seed/schema, maximum Heat, final Night Pressure, encounters, enemy/elite counts, boss result, coins, manual collections, maximum streak, secured Scrap, highest combo, equipment build, and active synergies. Pending coin clusters settle once as base value before every terminal summary; buttons forward Restart Run or Return to Main Menu intent to run authorities.
- [x] Preserved random schema version 1 and the exact seven named streams. Existing encounter/spawn/reward/equipment/card selection keeps its established stream and stable candidate ordering; M6 combat schedules, telegraphs, cadence measurement, settings, persistence, tutorials, and cosmetic/audio activity add no unseeded gameplay draw.

Verification record and remaining work:

- [x] Added 56 deterministic M6 tests across seven suites: runtime systems (6), Call Backup (6), combat content (9), persistence/settings (7), audio/tutorial (6), presentation (9), and composed `GameRun` integration (13).
- [x] Added and executed `tests/run_milestone_6_cumulative.gd`, which composes all 15 accepted Milestone 0–5 suites with the seven M6 suites and fails on any failure or skip. Godot 4.7 passed **244/244 tests and 3,234 assertions with 0 failed and 0 skipped across 22 suites**, preserving the accepted 188-test/2,450-assertion Milestone 5 baseline.
- [x] Launched the configured project headlessly into its `/GameRun` main scene. The boot completed with no parser error, runtime error, warning, or leaked-object/resource diagnostic.
- [x] Ran a fixed-seed technical long-form probe (`6062026`) with Rex and starter equipment only. It reached the boss at 584.983 eligible seconds and naturally ended **Defeated** at 589.517 eligible seconds (9m49.5s). This is automation evidence, not a representative manual path or owner validation.
- [x] Fast-forwarded Milestone 6 to `main`; Pages run 29960250903 successfully completed the official Godot 4.7 Web export and deployment. The live page loaded title `Neon Loop`, a visible 1280×720 canvas, and no warning/error console entries.
- [ ] Re-audit test-runner shutdown cleanup. The cumulative single-process runner exited 0 but retained the inherited/accepted shutdown report of 48 ObjectDB instances and 4 resources in use; focused and long-form diagnostic runners also emitted shutdown-object warnings. Do not suppress these diagnostics or conflate them with the clean configured-project boot.
- [ ] Exercise all changed mouse/touch/keyboard paths in the configured project plus preserved Help, sound unlock, fullscreen, `F1`, `F2`, cards, inventory drag, Hydrant, coins, and extraction behavior.
- [ ] Complete and time representative 8–12 minute victory, extraction, and defeat paths; measure cadence only from eligible active time; manually establish three viable builds; and exercise every crew member, enemy, elite behavior, boss phase, intervention, tutorial, setting, save-recovery path, summary outcome, and repeated restart.
- [ ] Resolve or explicitly accept the remaining cadence violations. The fixed-seed technical probe recorded ambient 47 opportunities, 12.446-second average, 9 violations, last gap 8.150; strategic 13 opportunities, 44.999-second average, 8 violations, last gap 82.650; and major 3 opportunities, 194.994-second average, 3 violations, last gap 181.300. Target-band averages alone are not acceptance, and the trace is not a manual or qualitative result.
- [ ] Complete real-input Web playtesting at 1280×720, 1920×1080, 2560×1440, and touch/mobile where available; produce and smoke a fresh Windows export/runtime; and capture fresh Milestone 6 visual evidence. The official Pages Web export, live 1280×720 canvas load, and empty warning/error console already passed.
- [ ] Leave actor feel, telegraph readability, tutorial comprehension without explanation, cadence quality, build viability, and representative-run quality clearly identified for owner validation. Automated implementation checks cannot invent those qualitative results.

Working-tree provenance remains separate from Milestone 6: the owner's pre-existing tracked Godot-AI 3.0.5 update across 17 addon files remains tracked and enabled, and the owner's two pre-existing `project.godot` deletions (`window/stretch/aspect="keep"` and `textures/default_filters/use_nearest_mipmap_filter=false`) remain preserved. The M6 non-gameplay Autoload additions above are the only intentional overlap in `project.godot`; no owner change is counted as new M6 work.

## Scope gate

Milestone 6 remains the implemented runtime boundary. WP00 supersedes only its former **prospective** stopping-boundary language with the approved WP01–WP07 roadmap; it does not start or implement any package. Procedural generation, additional districts/cards/crew/enemies/bosses, multiplayer, controller support, localization, achievements, daily scheduling/leaderboards/rewards, advanced meta-progression, permanent stat trees, mid-run saving/replay, broader equipment/card economies, and every undocumented system remain out of scope. Run-seed and named-stream infrastructure remains schema version 1 unless a later owning package proves and records an incompatible semantics change.

The owner-authorized 2026-07-22 Milestone 6 Pages publication remains a historical tentative-playtest record. The 2026-08-20 WP00 approval authorizes the bounded roadmap as planning, not implementation, commits, pushes, publication, deployment, or unreviewed content expansion. WP01 may begin only under a separate explicit request.
