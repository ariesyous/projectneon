# Changelog

All notable changes to Neon Loop are documented here. Dates use the local project working date.

## [Unreleased]

### 2026-07-19 — Milestone 4.2: Inventory Drag and Backpack Clarity Correction

#### Added

- Typed `EquipmentDragPayload` presentation data for owned-item and reward origins, stable equipment identity, source/choice position, inventory revision, encounter identity where applicable, and drag-preview metadata.
- Typed `EquipmentDragSlot` buttons using Godot's built-in `Control` drag/drop callbacks, off-tree drag previews, valid-target feedback, and typed drop requests to `GameHUD`.
- Real drag targets for all three generic active slots and all three cells in the single inactive backpack, including empty third-slot destinations.
- Drag staging for equipment rewards through the existing active/backpack destination, exact leave-behind, preview, and exactly-once confirmation flow.
- A dedicated M4.2 integration suite with 13 tests/125 assertions covering terminology, typed payload/target validation, all third-slot paths, combat lockout, lossless move/swap staging, reward forwarding, full-inventory handling, exactly-once confirmation, rejection without mutation, longest-item-name pixel fit, pointer-threshold fallback, and first-touch preservation.

#### Changed

- Reworded the equipment surface as **three generic active slots** plus **one backpack with three inactive slots**. It no longer suggests three separate packs, loadouts, or Store-versus-Equip bags.
- Owned-item cross-area dragging is non-destructive and non-authoritative. Active-to-empty-backpack stages a move; occupied active/backpack drops stage an atomic swap that keeps both items; Confirm remains required before authority changes.
- Reward dragging stages the same revisioned choice/destination request used by click/tap/keyboard input. It cannot bypass the exact consequence preview or tokenized one-time application.
- Same-area, stale-revision, wrong-identity, invalid-target, outside, and combat-locked drops reject or snap back without changing ownership. Destructive discard remains a separate exact-item action with named confirmation.
- Full-inventory guidance now explicitly offers exact leave-behind selection or **Skip Gear**. Skipping the equipment does not discard an owned item and still resolves the paired ordinary run reward.
- Click/tap/keyboard item inspection, destination selection, confirmation, and cancellation remain complete fallbacks for players who do not use drag gestures.
- Dynamic reward destinations now use compact `ACTIVE n` / `BACKPACK [n]` labels; inventory action targets use `ACTIVE` / `STORE SLOT` / `SWAP SLOT`; key consequence prompts are bounded to two lines; Help states `CLICKS ONLY INSPECT; NEVER DISCARD`; and unsupported action-arrow glyphs were replaced by Web-safe words.
- `EquipmentDragSlot` now arms typed mouse/touch input and, after 8 pixels of movement, calls Godot `force_drag` with the same payload/preview when Web or touch motion does not enter `_get_drag_data`. The first armed touch retains its pointer index so a second touch cannot steal or begin that drag. This compatibility fallback adds no selection or authority request and cannot bypass staging or Confirm.

#### Verification

- Passed **145/145 tests and 1,709 assertions with no failures or skips** across 12 suites. All 132 Milestone 1–4.1 tests/1,584 assertions remain preserved; M4.2 adds 13 tests/125 assertions.
- Automated coverage confirms one-backpack terminology; typed stable-ID/revision payloads; all three active/backpack destinations; lossless move/swap semantics; reward drag/click forwarding to slot 3; exact full-inventory leave-behind/skip behavior; exactly-once Confirm; and stale, invalid, same-area, or combat-locked rejection without mutation. Dynamic fit now covers all six reward destination controls, all six inventory action-target states, and key two-line prompts with 20 assertions; the pointer fallback has seven assertions; and touch threshold/first-pointer preservation adds five.
- Configured Godot 4.7 opened `/GameRun`. A real `InputEvent` pointer drag staged Magnetic Flail from active slot 3 to empty backpack slot 3 without changing revision 6, named the no-loss consequence, and required separate Confirm. Confirm applied exactly once at revision 7; a repeated invocation left revision 7 unchanged.
- Fresh editor logs since cursor 158 contained zero new lines/warnings/errors, and the game log contained only development-helper registration. The 1280 x 720 evidence at `res://docs/screenshots/milestone_4_2_inventory_drag.png` showed one backpack, all third-slot controls, and no visible overflow or border crossing.
- Fresh Windows and Web exports exited 0 with no export warning/error. Windows passed a headless smoke that loaded `game_run.tscn` plus M4.2 scripts/Resources, wrote no stderr, and reported no diagnostic. The final local 1280 x 720 Web build unlocked sound; staged Hacker Deck reward→active slot 3 and active slot 3→empty backpack slot 3 through real pointer drags with no pre-Confirm mutation; applied each through one ordinary Confirm click; ended with active slot 3 empty and backpack slot 3 holding Hacker Deck; showed no glyph boxes/overflow; and produced an empty browser warning/error console.

#### Scope

- M4.2 changes only the authorized Milestone 4 equipment interaction/presentation surface. It changes no equipment tuning, active-slot aggregation, candidate ordering, random-stream ownership, or random schema, and it preserves every Milestone 0–4.1 technical acceptance decision plus the owner-recorded Milestone 1 gate.
- Selling, salvage, buyback, auto-sell/auto-salvage, equipment economy, rarity tiers, uniques, affixes, set items/set bonuses, category-locked slots, District Cards, and every other Milestone 5+ system remain unimplemented.
- No commit, push, merge, publication, or deployment is part of this correction unless separately requested.
- Every technical Milestone 4.2 acceptance check passed. Work stopped before Milestone 5.

### 2026-07-19 — Equipment Experience Playtest Direction (Documentation Only)

#### Recorded

- Clarified the implemented model as three generic equipped cells plus three inactive cells in one backpack; `PACK 1/2/3` are not separate bags or loadouts.
- Recorded owner preference for tactile click-and-drag inventory management, with automatic combat remaining visible behind a future Diablo II-style character inventory.
- Recorded **Keep Current Build / Skip** as the current safe full-inventory answer. Selling, salvage, auto-sell, and auto-salvage remain unimplemented future economy decisions; no item should be destroyed automatically by default.
- Added rarity tiers, uniques, affixes, and data-driven set items/set bonuses to the future itemization design backlog.
- The bounded drag/backpack-clarity portion of this direction was subsequently implemented by Milestone 4.2 above; economy, rarity, unique, affix, set, and category-slot ideas remain future design input only.

#### Scope

- Documentation only. This record authorizes no gameplay, UI, economy, random-schema, Milestone 5, or later implementation.

### 2026-07-19 — Milestone 4.1: Equipment Safety and HUD Readability Correction

#### Added

- Exactly three ordered backpack storage slots alongside the three active generic equipment slots. Stored items remain owned but contribute no active tags, modifiers, triggered effects, new triggered status applications, or synergy progress; already-applied actor-owned statuses expire or clear normally.
- Revisioned, typed inventory transactions for reward acquisition, active/backpack swapping, moving active items to storage, and deliberately confirmed discard.
- A staged equipment reward interface: item inspection, explicit Equip or Store destination, exact named consequence review, and separate Confirm. **Keep Current Build** safely resolves the paired ordinary reward without acquiring equipment.
- Generated, replaceable placeholder icons for all nine equipment Resources under `res://assets/ui/equipment/icons/` and badges for Knockback 2, Bleed 2, and Tech 2 under `res://assets/ui/synergies/badges/`.
- A persistent Downtown journey strip and expanded opening guidance for `HIDEOUT → PATROL → FIGHT → GEAR → EXIT/BOSS`, current stage/next objective, and inspection-only inventory clicks.
- Deterministic Milestone 4.1 inventory-safety and HUD/input/layout/icon test suites.

#### Changed

- Migrated the true presentation viewport from 640 x 360 to 1280 x 720 while preserving the established logical 640 x 360 stage/combat coordinate system through a camera centered at `(320, 180)` with `Vector2(2, 2)` zoom.
- Re-authored `GameHUD` and `DebugOverlay` at the native presentation size. Labels/buttons use at least 16-pixel text, ordinary controls and headings use a larger hierarchy, and tests inspect root/panel containment.
- Preserved 16:9 aspect, viewport stretch, integer scale mode, nearest-neighbour canvas filtering, the explicit default mipmap-filter setting, and pixel snapping.
- Equipment reward candidates now exclude stable IDs owned in either active or backpack positions while preserving stable-ID sorting and consumption of only the existing `equipment` stream. Destination review consumes no random draws. Random schema version 1 remains unchanged because pre-backpack candidate states retain the same order, backpack ownership is explicit decision state, and stream derivation/draw-without-replacement semantics are unchanged.
- Equipping over an occupied active slot now stores the outgoing item in the first empty or explicitly selected backpack position. A full six-position inventory requires the player to choose the exact stored item left behind; no oldest item or replacement slot is selected automatically.
- Ordinary active/backpack item clicks now inspect only. Between encounters, move, swap, or discard remains disabled until a destination/action is selected and its named consequences are explicitly confirmed; combat permits inspection only.
- Inventory requests carry the inspected revision and, for discard, the expected stable ID. Stale, mismatched, incomplete, duplicate, or unconfirmed requests reject without mutation.

#### Verification

- Automated suite definitions cover finite three-slot storage, active-only aggregation, cross-area duplicate rejection, atomic outgoing-item storage, full-inventory rejection/confirmation, exact leave-behind selection, move/swap/discard safety, stale-revision rejection, restart cleanup, owned-item candidate filtering, exactly-once Equip/Store/Keep Current Build paths, inspection-only clicks, no default full-loadout replacement, 1280 x 720/camera/filter contracts, minimum typography/containment, journey guidance, and all twelve placeholder visuals.
- Passed **132/132 tests and 1,584 assertions with no failures or skips** across 11 suites. All 75 Milestone 1–3 tests/1,100 assertions remain preserved; 26 dedicated Milestone 4.1 tests add 249 assertions, and existing Milestone 4 coverage gained 29 strengthened assertions.
- Launched configured `/GameRun` at native 1280 x 720 and used real pointer input to select a reward without mutation, choose a destination, confirm one application exactly once, inspect inventory without mutation, and stage/cancel a named discard. Journey/Help, Hydrant rejection, sound unlock, fullscreen, and preserved `F1`/`F2` handlers passed; fresh cursor-bounded logs were clean. Evidence: `res://docs/screenshots/milestone_4_1_inventory_readability.png`.
- Fresh local Windows and Web exports succeeded. Windows completed a clean 180-frame headless startup smoke; Web completed sound unlock, reward confirmation, inventory inspection, discard cancellation, Help, fullscreen, and Hydrant input with no console warnings/errors. The portable export editor's ObjectDB-profiler `user://` message did not reproduce in exported runtimes; browser automation did not deliver `F1` to the Web canvas, while the unchanged runtime handler and automated coverage passed.

#### Scope

- This is an owner-authorized usability/readability correction to completed Milestone 4. It preserves every Milestone 0–4 technical acceptance decision and does not reopen or reinterpret the owner-recorded Milestone 1 Human Validation Gate.
- Equipment selling, buyback, and a broader shop economy were deliberately not implemented because they exceed this correction. District Cards, final-boss content, progression/persistence, procedural generation, and every other Milestone 5+ system remain absent.
- No commit, push, merge, publication, or deployment is part of this correction unless separately requested.

### 2026-07-18 — Milestone 4: Equipment and Synergies (Technical)

#### Added

- Exactly nine typed, stable-ID equipment Resources: Spiked Bat, Shock Gloves, Reinforced Jacket, Hacker Deck, Steel-Toe Boots, Serrated Wraps, Magnetic Flail, Voltaic Blade, and Chain Sneakers.
- Typed equipment modifier, triggered-effect, status-effect, equipment/synergy definition, and catalogue Resources with validation and stable ordering.
- Three generic ordered equipment slots with acquisition, explicit replacement, removal, duplicate/invalid rejection, immediate derived-state rebuilding, and clean restart.
- A full `SynergySystem` authority for deterministic tag/modifier/effect aggregation, data-driven thresholds, non-mutating previews, and typed activation/deactivation/build signals.
- Knockback 2 (+20% knockback distance, +25% environmental collision damage), Bleed 2 (+2 maximum Bleed stacks, +20% crew damage against bleeding enemies), and Tech 2 (-15% intervention cooldown, +1.5s Shock duration).
- Actor-owned Bleed (4.0s, base maximum 3, 1.0s ticks, 2 damage per stack) and Shock (3.0s, one stack, no tick damage) behavior, visual marks, snapshots, and cleanup.
- Deterministic three-choice equipment rewards using only the run-scoped `equipment` stream after invalid/duplicate/equipped filtering and stable-ID sorting, with tokenized exactly-once application.
- A compact 640 x 360 equipment UI showing three slots, names, tags/effects, counts, active/inactive threshold progress/effects, immediate activations, alternative paths, and replacement losses/gains.
- Two Milestone 4 suites containing 31 tests/206 assertions and visual evidence at `res://docs/screenshots/milestone_4_equipment_synergies.png`.

#### Authored tuning

- Spiked Bat: `MELEE`/`BLEED`/`KNOCKBACK`; +25% heavy-hit damage, 25% heavy-hit Bleed chance, +15% knockback distance.
- Shock Gloves: `TECH`/`SHOCK`/`FAST`; 25% hit Shock chance for 3.0s, +8% attack speed.
- Reinforced Jacket: `DEFENCE`/`STREET`; +20% maximum health, -20% knockback received.
- Hacker Deck: `TECH`/`INTERVENTION`; -10% intervention cooldown, +1.5s Shock duration.
- Steel-Toe Boots: `KNOCKBACK`/`MOBILITY`; +10% movement speed, +15% environmental collision damage.
- Serrated Wraps: `BLEED`/`FAST`; +1 maximum Bleed stack, +15% damage against bleeding enemies.
- Magnetic Flail: `TECH`/`KNOCKBACK`; +20% environmental knockback, +10% environmental collision damage.
- Voltaic Blade: `TECH`/`BLEED`; every hit applies one 4.0s Bleed stack, +20% damage against Shocked enemies.
- Chain Sneakers: `FAST`/`KNOCKBACK`; +6% movement speed, +6% attack speed, +10% knockback follow-up damage.

#### Changed

- `GameRun` now wires `SynergySystem`, `RewardDirector`, combat/status authorities, Hydrant cooldown scaling, and `GameHUD` while keeping each owner scene-scoped.
- `CombatDirector` applies stable aggregated health, heavy-hit/conditional damage, movement/attack speed, knockback, environmental damage, triggered Bleed/Shock, and follow-up modifiers without item-specific combat branches.
- Equipment changes preserve current-health ratio where maximum health changes and never mutate Heat or irreversible Night Pressure.
- Tech modifiers scale the existing finite intervention cooldown without regenerating resources or changing Subway/shop cooling rules.
- Equipment choices and equipment effect chances share the existing specification-owned `equipment` stream. Extra cosmetic draws remain isolated; later equipment-choice reproduction additionally requires identical equipment decisions, proc resolutions, and authoritative timing. Random schema version 1 is unchanged.
- Existing fixture helpers now compose the actor-owned `StatusController` required by the production actor scene; all prior acceptance behavior remains covered.

#### Verification

- Passed **106/106 tests and 1,306 assertions with no failures or skips**. All 75 Milestone 1–3 tests/1,100 assertions remain preserved; Milestone 4 adds 31 tests/206 assertions.
- Covered exactly nine definitions/unique IDs, Resource validation, three slots, equip/replace/remove/rejection, stable aggregation, immediate recalculation, exact threshold effects/signals/deactivation, future threshold data, all two-item matrices/bridges, stream ownership/order/replay/variation/isolation, all preview modes, exactly-once one-click selection, combat modifiers/statuses, and clean restart.
- Acquired Bat, Blade, and Flail through normal choices to activate all three synergies, replaced Bat with Gloves after a correct loss/gain preview, and removed bridge items to deactivate invalidated thresholds.
- Verified seed 424242 reproduced `steel_toe_boots`, `serrated_wraps`, and `hacker_deck` after 20 extra cosmetic draws; same-seed restart cleared slots, tags, synergies, modifiers, statuses, modal/token state, and all seven draw counts.
- Exercised visibly distinct Bat/Boots/Chain Knockback, Bat/Wraps/Blade Bleed, and Gloves/Hacker/Blade Tech builds in live combat. Observed increased displacement/environmental damage, live Bleed stacks/conditional damage, and 6.0-second Shock plus a 6.0-second Hydrant cooldown.
- Exercised extraction, defeat, and boss-threshold flows with equipment active. Hydrant, coins, Help, sound unlock, fullscreen delivery, `F1`, and `F2` remained functional.
- Launched the configured Godot 4.7 main scene directly into `/GameRun`; fresh editor/game output contained no task-introduced parser errors, runtime errors, warnings, failures, or skips.
- Fresh local release Windows and Web exports succeeded. Windows passed a 180-frame headless startup smoke. Locally served Web rendered the equipment UI, accepted sound unlock, applied Serrated Wraps with one ordinary click, closed the modal, and produced no browser-console warnings or errors.

#### Limitations

- Numerical equipment/status balance is provisional and data-driven. Presentation uses text/code-drawn placeholders; production equipment icons/art/audio remain later presentation work.
- Bleed and Shock are the only Milestone 4 statuses. Wet, combo systems, additional statuses, district cards, final-boss content, progression/persistence, procedural generation, and every Milestone 5+ system remain deliberately absent.
- The embedded editor runner supports windowed mode only and reports that informational limitation for fullscreen; exported/browser fullscreen delivery paths are preserved. The generated Web shell retains its focused-canvas zoom limitation.
- Reproduction is limited to the same supported build, content revision, schema version, seed, ordered decisions/effect resolutions, and authoritative timing context.

#### Scope

- Every explicitly authorized technical Milestone 4 criterion passed. Work stopped before Milestone 5.
- All Milestone 0–3 technical acceptance decisions and the owner-recorded Milestone 1 Human Validation Gate were preserved without reopening or reinterpretation.
- Milestone 4 changes, local exports, and verification evidence were not committed, pushed, merged, published, or deployed. GitHub Pages was not redeployed.

### 2026-07-18 — Milestone 3: Complete Run Structure (Technical)

#### Added

- A run-scoped `RunDirector` authority with an explicit typed lifecycle covering initialization, introduction, patrol, encounters, reward/shop choices, extraction, boss trigger, victory/defeat, summary, pause, invalid-transition rejection, and clean restart.
- A data-driven patrol loop and deterministic encounter controller with stable encounter/spawn/lane selection, scaled actor creation, per-encounter concurrency limits, and a global 30-enemy cap.
- Separate tactical Heat and irreversible Night Pressure authorities. Heat is clamped to 0–100 with exact six-tier boundaries; Night Pressure advances only during eligible active simulation and exactly-once encounter completion.
- Data Resources for Heat, Night Pressure/scaling/thresholds, cooling, random schema, patrol route, three encounters, and three standard rewards.
- Latched extraction thresholds at Night Pressure 18 and 36, an unavoidable boss threshold at 50, same-update boss precedence unless extraction was already confirmed, and safe queued boss transition through `BOSS_INTRO` to `BOSS_ACTIVE`.
- Finite cooling: two Subway Reroute charges removing 15 Heat each and two 60-coin shop purchases removing 18 Heat each, with zero-stock/funds rejection and no time regeneration.
- One authoritative supplied-or-generated integer run seed and a non-Autoload `RunRandomStreams` child exposing exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`.
- Random schema version 1 using platform-stable `fnv1a32_utf8_v1` over canonical UTF-8 input, locked derivation vectors, stable-ID filtering/sorting/deduplication, stream isolation, and same-seed restart.
- Standard reward accounting, typed run summaries, same-seed/new-seed restart actions, live run HUD/diagnostics, and deterministic Milestone 3 run/randomness suites.
- Updated visual evidence at `res://docs/screenshots/milestone_3_complete_run_structure.png`.

#### Changed

- `GameRun` now composes run, patrol, encounter, reward, cooling, combat, intervention, HUD, and debug owners while remaining assembly/wiring rather than a second gameplay authority.
- The former fixed Combat Lab orchestration is replaced in the configured run by scheduled encounters, while existing Jax/Street Punk combat, safe-space movement, damage, feedback, cleanup, coin clusters, and Hydrant behavior are preserved.
- Heat tier tuning changes immediate spawn additions (0/1/2/3/4/5), enemy damage (1.00/1.05/1.10/1.15/1.20/1.30), reward quality (0/0/1/2/3/4), reward multiplier (1.00/1.05/1.10/1.20/1.35/1.50), and elite availability (tier 3+).
- Night Pressure applies +1% enemy health, +0.5% enemy damage, and +1.25% spawn budget per point. Spawn budget uses deterministic non-negative round-half-up, `floor(scaled + 0.5)`, before caps.
- Encounter completion IDs and standard reward IDs are authoritative and at-most-once; duplicate/empty content IDs are excluded before random selection.
- Restart cleanup is synchronous for run-owned actors and loot, preventing queued stale nodes or reservations from leaking into the next run.
- Playtest follow-up keeps run-action button enabled/text state stable across frames, so one ordinary press/release claims a reward instead of an intermediate disabled assignment cancelling the click. The same stable presentation path now covers Subway, shop, and extraction buttons.
- The Run Resources value text uses tighter line spacing, a slightly smaller font, and shorter `AUTO • FULL VALUE` copy so its third line remains inside the panel border.

#### Verification

- Passed **75/75 tests and 1,100 assertions with no failures or skips**. All 46 Milestone 1–2 tests and 694 assertions remain preserved; Milestone 3 adds 29 tests and 406 assertions.
- Covered the complete state graph and rejection paths, every Heat boundary, Heat/Pressure separation, eligible-time rules, exactly-once completion gains, scaling/rounding/caps, threshold latching/precedence/queueing, finite cooling, seeds, stable ordering, named-stream isolation, rewards, results, summaries, and composed restart cleanup.
- Launched the configured Godot 4.7 main scene directly into `/GameRun` with clean current game/editor output. Accelerated representative runs reached extracted, defeated, and boss-triggered summaries.
- Verified repeated Heat cooling never reduced Night Pressure, modal/pause/introduction time added no Pressure, cooling stock exhausted, same-seed selections replayed, and 50 extra cosmetic draws did not change gameplay selections.
- Exercised Fire Hydrant damage/cooldown, coin collection, Help, fullscreen, `F1`, and `F2` during the new lifecycle.
- Reproduced `REWARD_SELECTION` after the owner playtest report and verified one physical mouse press/release applied the 20-coin/2-scrap Street Cache and immediately continued the run. A fresh 640 x 360 capture confirmed the Run Resources copy remains inside its panel.
- Exported local Windows and Web builds successfully. Windows passed headless and hidden-window startup smoke checks. A locally served Web build rendered the live Milestone 3 HUD, unlocked audio, toggled Help, entered/exited fullscreen, and produced no browser-console warnings or errors.

#### Limitations

- Milestone 3 deliberately implements only boss threshold latching, safe queueing, intro, and active transition behavior. The final-boss actor/encounter, presentation, and production victory path remain later content work.
- Existing Street Punk presentation stands in for the current authored encounter set; elite eligibility is active tuning infrastructure without later Viper Enforcer content.
- Equipment, synergies, district cards, general shop content, saving/progression, procedural generation, and other Milestone 4+ systems remain unimplemented. The `equipment` and `cards` random streams are compatibility infrastructure only.
- The generated Web shell retains its existing focused-canvas zoom limitation; the exercised fullscreen control remains the presentation-scale alternative.

#### Scope

- Every explicitly authorized technical Milestone 3 criterion passed. Work stopped before Milestone 4.
- The owner-recorded Milestone 1 Human Validation Gate and the separate Milestone 2 technical acceptance record were preserved without reopening or reinterpretation.
- Changes, local exports, and verification evidence were not committed, pushed, merged, published, or deployed. GitHub Pages was not redeployed.

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
