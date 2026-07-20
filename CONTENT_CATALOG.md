# Neon Loop Content Catalog

## Catalog status

This catalog reflects the implemented and technically verified **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, **Milestone 2 — Player Intervention**, **Milestone 3 — Complete Run Structure**, **Milestone 4 — Equipment and Synergies**, **Milestone 4.1 equipment usability/readability correction**, **Milestone 4.2 inventory drag/backpack-clarity correction**, and separately authorized **Milestone 5 — District Cards** scope. Milestones 0–4.2 retain their recorded technical acceptance; Milestone 5 passed 188/188 cumulative tests and 2,450 assertions plus configured-project, Windows, Web, console, and visual-evidence checks. Entries explicitly marked as placeholders still reserve later ownership or screen space, and listing deferred vertical-slice content does not authorize it.

The owner confirmed that the cumulative Milestone 4, M4.1, and M4.2 baseline was committed to `main`, pushed, and successfully published from commit `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`. The live build is [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/). This release correction changes no historical acceptance record and introduces no semantic version.

## Implemented foundation content

### Stage

| ID / name | Type | Current state |
| --- | --- | --- |
| Downtown Loop | Fixed district stage | Placeholder nighttime street made from development shapes and labels |
| Back Lane | Debug lane guide / combat lane | Visible development marker at Y 194; used by Combat Lab movement |
| Middle Lane | Debug lane guide / combat lane | Visible development marker at Y 226; used by Combat Lab movement |
| Front Lane | Debug lane guide / combat lane | Visible development marker at Y 258; used by Combat Lab movement |
| Route nodes | Authored patrol route presentation | Five-node loop driven by authoritative four-second segments |
| Spawn points | Authored encounter markers | Deterministic Jax/enemy placement within the shared combat-safe region |
| Interactables container | Stage container | Hosts the functional Fire Hydrant presentation/input scene; gameplay authority remains run-scoped |
| Crew container | Stage container | Hosts the runtime Jax actor |
| Enemy container | Stage container | Hosts capped encounter Street Punks plus short death-cleanup presentation |
| Effects container | Stage container | Hosts replaceable combat feedback, damage numbers, and audio players |
| Loot container | Stage container | Hosts temporary non-authoritative coin-cluster presentation |

### HUD shell

| Region | Reserved presentation |
| --- | --- |
| Minimap | District route, crew location, encounters, extraction point, and pending/resolved card modifications |
| Heat and timer | Heat value/tier and run time |
| Crew status | Compact and expanded crew health/status space |
| Equipment and synergies | Equipment summary and synergy thresholds |
| District cards | Live hand/draw/discard counts, detailed card review/reward choice, and five-slot future-route planning |
| Interventions | Intervention controls and charge/cooldown space |
| Extraction | Extraction action and reward multiplier space |

Run state, route progress, Heat/tier, Night Pressure, elapsed time, extraction/cooling actions, summary, Jax health/state/target, coin total, manual streak, Fire Hydrant state/cooldown, three generic active equipment slots, one clearly named backpack with three inactive slots, item inspection/management, tag/synergy progress, equipment and card reward previews/confirmations, District Card hand/draw/discard state, future route slots/modifications, fullscreen state, and player guidance are live presentation values. The HUD is authored natively at 1280 x 720 with a 16-pixel minimum for labels/buttons, larger ordinary controls/headings, and explicit panel containment. A persistent Downtown journey strip shows `HIDEOUT → PATROL → FIGHT → GEAR → EXIT/BOSS`, current stage, and next objective while Help explains the existing loop and safe inventory/card use. Typed built-in `Control` dragging stages equipment or card intent, while click/tap/keyboard controls remain available and separate confirmation remains mandatory where required. The card surface shows names, placeholder icons, `FREE`, Heat/effect/tags/progression text, explicit route-slot statuses, valid highlights, invalid return feedback, and pending/resolved minimap previews. No HUD region owns authoritative gameplay state.

The HUD presents the Milestone 1 manual coin streak, Milestone 2 Hydrant/onboarding/display state, and Milestone 3 run/escalation/actions/summary state. Seed, schema, named-stream draw counts, encounter/cooling status, and latches are visible through the development overlay.

### Development tools

| Tool | Control | Current state |
| --- | --- | --- |
| DebugOverlay | `F1` | Toggleable development information shell |
| Lane guides | DebugOverlay button or `F2` | Requests that Downtown Loop show or hide all three lane visuals |

### Runtime ownership state

| Class | Current content |
| --- | --- |
| `RunDirector` | Milestone 3 state graph, timer, Heat, Night Pressure, thresholds, scaling, seed, outcomes, and summaries |
| `RunRandomStreams` | Seven isolated, schema-versioned deterministic stream states; run-scoped child of `RunDirector` |
| `PatrolController` | Authored route progress, safe boundaries, encounter pauses, finite Subway reroute movement, five stable future occurrence slots, route revisions, and exactly-once pending/resolved route modifications |
| `CombatDirector` | Actor registration, targeting, reservations, hit resolution, hit-stop, equipment modifier/effect application, cleanup, safe-space assignment, and typed environmental-hit authority |
| `RewardDirector` | Coin ledger, at-most-once clusters/manual streak, standard rewards, deterministic equipment choices, exactly-once Equip/Store/Keep Current Build resolution, and supplemental card reward presentation/application coordination without using the `rewards` stream for card selection |
| `RunEncounterController` | Encounter identity, deterministic spawning/lanes, scaling, caps, completion, and cleanup |
| `RunCoolingController` | Finite Subway charges and finite priced shop-cooling stock |
| `RunFlowController` | Typed run/patrol/encounter/reward/equipment/cooling/card coordination, safe planning pause, exactly-once Heat application, non-recursive reward-source gating, and future-node effect dispatch |
| `FireHydrantController` | Milestone 2 circle validation, deterministic area resolution, rejection, and cooldown authority |
| `DisplayController` | Presentation-only fullscreen, landscape, and safe-area integration |
| `CardSystem` | Finite four-card draw pile, three-card-cap hand, discard, deterministic `cards`-stream draws/reward choices, placement/acquisition tokens and revisions, validation, pending/resolved effects, and clean restart |
| `SynergySystem` | Three active generic slots, one three-slot ordered inactive backpack, unique ownership, active-only deterministic aggregation, revisioned inventory transactions, synergy thresholds/signals, and non-mutating choice previews |

## Assets

Milestones 1–5 use project-native code-drawn placeholder actors, health/target/status indicators, hit/death/spawn/water effects, damage numbers, Hydrant and coin presentation, generated equipment/synergy visuals, four replaceable District Card SVG icons, and deterministic generated PCM cues. These are deliberately replaceable evaluation assets, not production sprites or audio. Equipment/card visuals are presentation-only Resource references; replacing them changes no gameplay identity, rule, or deterministic order. No production character sprites, enemy sprites, equipment art, card art, or music are cataloged as implemented.

### Generated equipment and synergy placeholders

The following square transparent PNGs are presentation-only references in typed Resources. Labels, tags, effects, and stable IDs remain authoritative; replacing these visuals changes no gameplay interface or deterministic ordering.

| Content ID | Placeholder visual |
| --- | --- |
| `spiked_bat` | `res://assets/ui/equipment/icons/spiked_bat.png` |
| `shock_gloves` | `res://assets/ui/equipment/icons/shock_gloves.png` |
| `reinforced_jacket` | `res://assets/ui/equipment/icons/reinforced_jacket.png` |
| `hacker_deck` | `res://assets/ui/equipment/icons/hacker_deck.png` |
| `steel_toe_boots` | `res://assets/ui/equipment/icons/steel_toe_boots.png` |
| `serrated_wraps` | `res://assets/ui/equipment/icons/serrated_wraps.png` |
| `magnetic_flail` | `res://assets/ui/equipment/icons/magnetic_flail.png` |
| `voltaic_blade` | `res://assets/ui/equipment/icons/voltaic_blade.png` |
| `chain_sneakers` | `res://assets/ui/equipment/icons/chain_sneakers.png` |
| `knockback_2` | `res://assets/ui/synergies/badges/knockback_2.png` |
| `bleed_2` | `res://assets/ui/synergies/badges/bleed_2.png` |
| `tech_2` | `res://assets/ui/synergies/badges/tech_2.png` |

The existing project icon and Godot MCP addon files are project/development support, not Neon Loop gameplay content.

### District Card placeholders

| Stable card ID | Placeholder visual |
| --- | --- |
| `arcade` | `res://assets/ui/cards/icons/arcade.svg` |
| `convenience_store` | `res://assets/ui/cards/icons/convenience_store.svg` |
| `gang_hideout` | `res://assets/ui/cards/icons/gang_hideout.svg` |
| `subway_entrance` | `res://assets/ui/cards/icons/subway_entrance.svg` |

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

The visual-direction reference is stored at `res://docs/reference/neon_loop_gameplay_mockup.png`; it is inspiration only and does not authorize the later systems depicted in it. Milestone 1 evidence is stored at `res://docs/screenshots/milestone_1_combat_lab.png`. Milestone 2 evidence is stored at `res://docs/screenshots/milestone_2_player_intervention.png`. Milestone 3 evidence is stored at `res://docs/screenshots/milestone_3_complete_run_structure.png`. Milestone 4 evidence is stored at `res://docs/screenshots/milestone_4_equipment_synergies.png`. Milestone 4.1 evidence is stored at `res://docs/screenshots/milestone_4_1_inventory_readability.png`. Milestone 4.2 evidence is stored at `res://docs/screenshots/milestone_4_2_inventory_drag.png`.

## Implemented Combat Lab content

| Content ID | Type | Authored Milestone 1 values |
| --- | --- | --- |
| `jax` | Crew actor | 520 health, 112 movement speed, 20 base damage, rewardless |
| `jax_basic_punch` | Basic attack | 0.20s windup, 0.08s active, 0.34s recovery, visible 155-force knockback, 0.075s hit-stop |
| `street_punk` | Enemy actor | 58 health, 86 movement speed, 2 base damage, fixed 40-coin reward |
| `street_punk_basic_punch` | Basic attack | 0.31s windup, 0.08s active, 0.42s recovery, visible 68-force knockback, 0.04s hit-stop |
| Milestone 1 coin cluster | Ambient interaction | 2.5s auto-collect, 3.0s manual streak window, basis-point bonus schedule capped at 10% |

## Implemented Player Intervention content

| Content ID | Type | Authored Milestone 2 values |
| --- | --- | --- |
| `downtown_loop_combat_space` | Combat-space Resource | Inclusive actor origins X 164–456, Y 194–258; lanes Y 194/226/258; includes worst-case safe-area HUD inset |
| `fire_hydrant` | Environmental intervention | 112px fixed circle, 18 deterministic area damage, fixed leftward 300-force knockback for 0.30s, 8.0s cooldown |
| Fire Hydrant presentation | World/HUD feedback | 36px world interaction radius, exact range preview, 0.55s water, 0.28s impact, 0.50s rejection timing |
| Combat Lab onboarding | Nonmodal HUD help | Auto combat, manual/full-value-auto coins, Hydrant use, fullscreen, and honest no-spending-yet purpose text |
| Sound unlock | Web presentation | One-shot click/tap/key affordance; the same gesture primes generated audio without pausing or restarting combat |
| Fullscreen and mobile support | Display presentation | Visible control, F11 fallback, fullscreen-only Escape, 16:9 letterboxing, landscape guidance, conservative safe-area insets |

### Milestone 2 technical content record

- The authored Hydrant presentation radius and authoritative gameplay radius are the same 112-pixel inclusive circle; the world interaction itself remains a generous 36-pixel target.
- The authored combat-safe actor-origin rectangle is X 164–456 and Y 194–258, with lane centers Y 194/226/258. Spawning, approach, reservations, knockback, recovery, replacement cleanup, coin placement, and lane visualization share this Resource.
- The complete deterministic suite passed 46/46 tests and 694 assertions with no failures: preserved Milestone 1 coverage is 30 tests/348 assertions, and Milestone 2 adds 16 tests/346 assertions.
- A 315.3046-second runtime soak produced 113 spawns and 98 defeats, ended with five enemies, six live actors, and six live reservations, and retained every origin inside the safe region. The 3,920-coin total exactly matched 98 fixed 40-coin rewards.
- Editor and local Windows/Web checks exercised the intervention, coins, Help, audio unlock, fullscreen, Escape, 16:9/mobile-landscape layout, `F1`, and `F2`. The standard Web shell retained its browser-zoom restriction; fullscreen remains the presentation-scale alternative.
- These outputs and the screenshot are local technical evidence. No Milestone 2 GitHub Pages build was published or deployed.

## Implemented Complete Run Structure content

### Run and route definitions

| Content ID | Type | Authored Milestone 3 values |
| --- | --- | --- |
| `milestone_3_heat` | `HeatDefinition` | Exact tiers 0/20/40/60/80/100; spawn additions 0/1/2/3/4/5; damage 1.00/1.05/1.10/1.15/1.20/1.30; reward quality 0/0/1/2/3/4; reward multipliers 1.00/1.05/1.10/1.20/1.35/1.50; elites at tier 3 |
| `milestone_3_escalation` | `RunEscalationDefinition` | 0.25 Pressure/eligible second; completion +6 standard/+10 elite-flagged; +1% health, +0.5% damage, +1.25% spawn budget per Pressure; global cap 30; extraction 18/36; boss 50 |
| `milestone_3_cooling` | `RunCoolingDefinition` | 2 Subway charges, -15 Heat/use; 2 shop purchases, 60 coins and -18 Heat/use |
| `milestone_3_random_schema` | `RunRandomSchemaDefinition` | Schema 1, `fnv1a32_utf8_v1`, canonical UTF-8 input prefix `neon-loop` |
| `downtown_loop_route` | `PatrolRouteDefinition` | Five stable route nodes, four-second segments, deterministic loop progression |

### Encounters

| Content ID | Type | Authored values |
| --- | --- | --- |
| `alley_scuffle` | `EncounterDefinition` | Heat tier 0 / Pressure 0, base budget 3, concurrent cap 3, completion +4 Heat |
| `arcade_ambush` | `EncounterDefinition` | Heat tier 1 / Pressure 8, base budget 4, concurrent cap 4, completion +4 Heat |
| `viper_signal` | `EncounterDefinition` | Heat tier 3 / Pressure 20, base budget 5, concurrent cap 5, elite eligible, completion +8 Heat |

All Milestone 3 encounters reuse the existing Street Punk actor presentation. Heat and Night Pressure scale their budget, health, and damage through typed definitions. Per-encounter caps and the global cap apply after deterministic non-negative round-half-up budget scaling.

### Standard rewards

| Content ID | Type | Authored values |
| --- | --- | --- |
| `street_cache` | `StandardRewardDefinition` | Quality 0, 20 coins, 2 scrap |
| `neon_stash` | `StandardRewardDefinition` | Quality 1, 30 coins, 3 scrap |
| `viper_cache` | `StandardRewardDefinition` | Quality 3, 45 coins, 5 scrap |

Standard reward candidates are quality-filtered, empty/duplicate stable IDs are excluded, remaining IDs are sorted, and the isolated `rewards` stream selects the result. Current Heat reward multipliers then use deterministic integer rounding. Eligible reward moments also offer three equipment definitions selected without replacement by the isolated `equipment` stream after stable-ID sorting. Milestone 5 adds a separate supplemental card opportunity after the core reward contract only for eligible baseline non-elite standard encounters; card choices consume only the isolated `cards` stream and do not replace or mutate standard/equipment rewards.

### Run lifecycle and technical record

- `RunDirector` implements `INITIALIZING`, `INTRO`, `PATROLLING`, `ENCOUNTER_ACTIVE`, `REWARD_SELECTION`, `SHOP`, `EXTRACTION_AVAILABLE`, `EXTRACTING`, `BOSS_INTRO`, `BOSS_ACTIVE`, `VICTORY`, `DEFEAT`, `RUN_SUMMARY`, and `PAUSED`.
- Night Pressure and the run timer advance only during eligible active simulation. Modal choices, pause, introduction, extraction/boss transitions, terminal states, and summary add zero.
- The two extraction thresholds and boss threshold latch permanently for the run. A queued boss begins at the next safe boundary and wins a same-update crossing unless extraction was already confirmed.
- Exactly two Subway and two shop cooling uses are available per run; cooling changes Heat only and cannot alter Night Pressure or latched progression.
- `RunRandomStreams` exposes exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Equipment choices/effect chances consume `equipment`; opening card draws and card reward choices consume `cards`. Candidate sets are filtered and sorted by stable ID before any card draw, and all other streams remain isolated.
- Technical verification passed 75/75 tests and 1,100 assertions with no failures or skips, preserved all 46 Milestone 1–2 tests, and completed clean local Windows/Web smoke checks. No build was published or deployed.

## Remaining specified content and contracts

The following names and contracts come from `GameSpecifications.md`. Named crew/enemies and later systems remain deferred unless a subsection explicitly identifies implemented Milestone 1–5 behavior.

### Crew

- Zoey — Tech Fighter
- Rex — Bruiser

### Enemies

- Bat Thug
- Bottle Thrower
- Viper Enforcer (elite)
- The Viper (boss)

### Remaining interventions

- Call Backup
- Subway Reroute — implemented as two per-run route/cooling charges; cannot reduce Night Pressure or bypass its thresholds

Wet application and combo continuation remain future compatibility contracts only. Milestone 4 implements only the typed Bleed and Shock subset needed by equipment; no Wet, combo-meter, or combo-reward system is implemented.

### Equipment

The Milestone 4 catalogue contains exactly nine typed, validated `EquipmentDefinition` Resources. Percentages below are additive multiplier deltas unless stated otherwise.

| Stable content ID / name | Tags | Authored Milestone 4 tuning |
| --- | --- | --- |
| `spiked_bat` / Spiked Bat | `MELEE`, `BLEED`, `KNOCKBACK` | +25% heavy-hit damage; 25% heavy-hit chance to apply 1 Bleed stack for 4.0s; +15% knockback distance |
| `shock_gloves` / Shock Gloves | `TECH`, `SHOCK`, `FAST` | 25% chance on any hit to apply Shock for 3.0s; +8% attack speed |
| `reinforced_jacket` / Reinforced Jacket | `DEFENCE`, `STREET` | +20% maximum health while preserving current-health ratio; -20% knockback received |
| `hacker_deck` / Hacker Deck | `TECH`, `INTERVENTION` | -10% intervention cooldown; +1.5s Shock duration |
| `steel_toe_boots` / Steel-Toe Boots | `KNOCKBACK`, `MOBILITY` | +10% movement speed; +15% environmental collision damage |
| `serrated_wraps` / Serrated Wraps | `BLEED`, `FAST` | +1 maximum Bleed stack; +15% damage against bleeding enemies |
| `magnetic_flail` / Magnetic Flail | `TECH`, `KNOCKBACK` | +20% environmental knockback; +10% environmental collision damage |
| `voltaic_blade` / Voltaic Blade | `TECH`, `BLEED` | Every hit applies 1 Bleed stack for 4.0s; +20% damage against Shocked enemies |
| `chain_sneakers` / Chain Sneakers | `FAST`, `KNOCKBACK` | +6% movement speed; +6% attack speed; +10% knockback follow-up damage |

There are exactly three active generic ordered equipment slots plus exactly three ordered backpack storage slots. Any distinct item may occupy any position, but only active items contribute tags, modifiers, triggered effects, new triggered status applications, and synergy progress. Stored items remain owned and are excluded from active aggregation; statuses already applied to actors remain actor-owned and expire or clear normally. Duplicate items/IDs are rejected across all six positions.

Reward acquisition begins with non-mutating item selection, then an explicit Equip or Store destination and a named Confirm step. A reward item may be dragged to any valid active/backpack destination, but the drop only stages this existing flow and never bypasses exact consequence review or Confirm. Equipping over an active item moves the outgoing item to the first empty backpack slot or an explicitly selected backpack slot. If all six positions are occupied, no oldest item is selected or discarded automatically: the player must choose the exact stored leave-behind item and confirm all consequences, or select **Skip Gear / Keep Current Build**. Skipping equipment still resolves the paired ordinary run reward. Direct Store to an occupied backpack position follows the same named leave-behind rule.

Ordinary clicks on active or stored items inspect only. In `INTRO`, `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE`, the player may drag or use the click/tap/keyboard fallback to stage an active item into an empty backpack slot or swap an item across occupied active/backpack positions. Cross-area dragging is lossless, same-area dragging is not a reorder operation, dropping outside valid targets is non-destructive, and every valid stage still requires Confirm. The player may deliberately discard the exact named item only through the separate destructive-confirmation action; during combat management controls reject while inspection remains available. Every mutation validates the inspected inventory revision and expected identity so stale, invalid, or mismatched requests reject without side effects. Successful active changes recalculate all build state immediately; backpack-only changes do not. No persistent unlock gates this development/test catalogue.

### Implemented status subset

| Stable status ID | Authored values | Behavior |
| --- | --- | --- |
| `bleed` | 4.0s base duration, 3 base maximum stacks, 1.0s tick, 2 damage per stack per tick | Reapplication adds stacks up to the derived maximum and refreshes duration; red actor marker/count; clears on actor/run cleanup |
| `shock` | 3.0s base duration, 1 maximum stack, no damage tick | Reapplication refreshes duration; cyan actor marker; Hacker Deck/Tech 2 extend the applied duration; clears on actor/run cleanup |

### Synergies

| Stable synergy ID / threshold | Derived effects | Eligible items | Valid two-item combinations |
| --- | --- | ---: | ---: |
| `knockback_2` / 2 `KNOCKBACK` | +20% knockback distance; +25% environmental collision damage | 4 | 6 |
| `bleed_2` / 2 `BLEED` | +2 maximum Bleed stacks; +20% crew damage against bleeding enemies | 3 | 3 |
| `tech_2` / 2 `TECH` | -15% intervention cooldown; +1.5s Shock duration | 4 | 6 |

Thresholds are `SynergyDefinition` data rather than item-ID checks; the evaluator accepts future 2/4/6 threshold definitions. The three cross-primary bridge items are Spiked Bat (`BLEED`/`KNOCKBACK`), Magnetic Flail (`TECH`/`KNOCKBACK`), and Voltaic Blade (`TECH`/`BLEED`). Every equipment change aggregates tags in stable order, emits typed activation/deactivation edges only when state changes, and publishes the rebuilt modifiers/effects immediately.

Reward choices filter invalid, duplicate, and already-owned active/backpack definitions, sort by stable content ID, and draw three without replacement from only the run-scoped `equipment` stream. Previews use the same non-mutating active-slot aggregation path as equip: they identify immediate activations, deactivations from replacement, and current-to-prospective progress for every inactive primary synergy. Destination and leave-behind review consumes no random draw. Equipment proc chances also consume the specification-owned `equipment` stream; identical later choices therefore require the same build decisions and authoritative effect timing. Random schema version 1 remains unchanged: pre-backpack candidate states retain the same ordered IDs, backpack ownership is explicit player-decision state, and stream derivation plus draw-without-replacement semantics are unchanged.

The native 1280 x 720 HUD shows all three active slots and all three slots in one backpack, item icons/names/details/tags/effects, current primary tag counts, active/inactive synergy badges/thresholds/effects, immediate activation, alternative progress, and full-slot consequences. An ordinary reward-item click selects for review only; Equip/Store destination and final Confirm are separate. Dragging provides a parallel typed staging gesture, not a second application path. Confirmation is tokenized and exactly once. Inventory clicks inspect only, valid cross-area drags stage lossless moves/swaps, and destructive discard requires a named confirmation.

### Milestone 4 technical content record

- Nine cumulative suites passed **106/106 tests and 1,306 assertions with no failures or skips**, preserving all 75 Milestone 1–3 tests and adding 31 Milestone 4 tests/206 assertions.
- Normal reward selection, acquisition, replacement, removal, threshold activation/deactivation, all 15 required primary two-item pairs, the three bridge decisions, preview accuracy, exactly-once input, Heat/Pressure isolation, and clean restart were exercised in the configured run.
- Representative live builds were Bat/Boots/Chain (movement, knockback, environmental collision), Bat/Wraps/Blade (six-stack Bleed and conditional damage), and Gloves/Hacker/Blade (6.0s Shock, 6.0s Hydrant cooldown, Shock interaction).
- Extraction, defeat, and boss-threshold flows remained valid with equipment active. Hydrant, coins, Help, sound unlock, fullscreen delivery path, `F1`, and `F2` remained functional.
- Fresh release Windows/Web exports succeeded; Windows passed a headless startup smoke, and locally served Web accepted sound unlock and a one-click equipment reward with no console warnings/errors. The embedded runner itself supports only windowed mode. This work was later included in the cumulative M4–M4.2 baseline published from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`.

### Milestone 4.1 correction content record

- The true presentation viewport is 1280 x 720. A camera at logical center `(320, 180)` with 2× zoom preserves the established 640 x 360 world framing; 16:9, integer scaling, nearest filtering, the explicit default mipmap-filter setting, and pixel snapping remain configured.
- Exactly three ordered backpack positions complement the three active generic slots. Storage is finite, inactive for build aggregation, unique by stable ID across ownership, and cleared on restart.
- Reward and between-fight inventory flows use explicit destinations, named consequences, revision validation, and separate confirmation. A full inventory never auto-evicts the oldest item, and **Keep Current Build** provides a non-acquisition path.
- Nine generated equipment icons and three synergy badges are integrated as replaceable presentation-only Resource references.
- The Downtown journey strip and opening Help communicate the existing run stages and safe inventory behavior without adding route-card or later gameplay authority.
- Eleven suites passed **132/132 tests and 1,584 assertions with no failures or skips**, preserving all 75 Milestone 1–3 tests/1,100 assertions and adding 26 dedicated Milestone 4.1 tests/249 assertions. The configured `/GameRun` real-pointer flow, native 1280 x 720 presentation, clean cursor-bounded logs, updated screenshot, fresh Windows 180-frame smoke, and locally served Web interactions/console were verified. The portable export editor's ObjectDB-profiler `user://` message was not present in either exported runtime. This work was later included in the cumulative M4–M4.2 published baseline.
- Selling/buyback is not implemented. A broader equipment-shop economy and every Milestone 6+ system remain outside this correction; Milestone 5 was separately authorized only for District Cards.

### Milestone 4.2 interaction content record

- The active equipment model remains three generic ordered slots. Presentation now unambiguously shows one backpack with three ordered inactive slots; there are no multiple bags or swappable loadouts.
- `EquipmentDragPayload` and `EquipmentDragSlot` are typed presentation helpers using Godot's built-in `Control` drag/drop contract. Payloads carry stable identity, source/choice position, revision/encounter context, and presentation metadata; the HUD remains non-authoritative.
- An 8-pixel typed mouse/touch threshold calls Godot `force_drag` with that same payload and preview when Web/touch motion does not enter `_get_drag_data`. The first armed touch retains its pointer index, so a second touch cannot steal or start that drag. It is only a native-drag compatibility fallback and cannot select equipment, mutate ownership, bypass staging, or bypass Confirm.
- Owned-item dragging works only across active/backpack areas. Active-to-empty-backpack stages a move; occupied cross-area drops stage an atomic swap that retains both items. Same-area, stale, invalid, outside, and combat-locked drops do not mutate inventory.
- Reward dragging stages the existing exact item/destination/leave-behind selection. Confirm remains mandatory and exactly once. A full inventory can choose an exact loss or **Skip Gear**, which declines the item while preserving the paired run reward.
- Click/tap/keyboard selection and destination controls remain complete fallbacks. Destructive discard remains separate and requires the exact named-item confirmation.
- Dynamic reward targets use compact `ACTIVE n` / `BACKPACK [n]` labels; inventory action targets use `ACTIVE` / `STORE SLOT` / `SWAP SLOT`; key consequence prompts are bounded to two lines; Help states `CLICKS ONLY INSPECT; NEVER DISCARD`; and action labels use ASCII wording supported by the Web font path. Longest-catalogue-name coverage checks all six reward destination controls, all six inventory action-target states, and key two-line prompts against their authored pixel bounds.
- Twelve suites passed **145/145 tests and 1,709 assertions with no failures or skips**, preserving the full 132-test/1,584-assertion Milestone 1–4.1 result and adding 13 M4.2 tests/125 assertions. Dynamic fit contributes 20 assertions; the pointer-threshold fallback has seven assertions; and the touch-threshold/first-pointer test adds five.
- Configured Godot 4.7 opened `/GameRun`. A real pointer drag staged Magnetic Flail from active slot 3 to empty backpack slot 3 with revision 6 unchanged and a named no-loss consequence; Confirm applied exactly once at revision 7, and a repeat stayed at revision 7. Fresh logs were clean and the 1280 x 720 evidence showed no visible overflow or border crossing.
- Fresh Windows/Web exports completed with exit code 0 and no export warning/error. The Windows headless smoke loaded `game_run.tscn` and the M4.2 scripts/Resources with empty stderr and no diagnostic. The final local 1280 x 720 Web build unlocked sound; staged Hacker Deck reward→active slot 3 and active slot 3→empty backpack slot 3 through real pointer drags without pre-Confirm mutation; applied each through one ordinary Confirm click; ended with active slot 3 empty and backpack slot 3 holding Hacker Deck; showed no glyph boxes/overflow; and produced an empty warning/error console.
- M4.2 itself added no tuning, catalogue entry, random draw, random-schema change, economy, rarity, unique, set, category-slot, card, or other later content. The cumulative M4–M4.2 baseline was subsequently committed to `main`, pushed, and published from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9` to [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/).

### Deferred equipment-experience design input

Owner playtesting favors a fuller Diablo II-style character inventory in which the automatic fight remains visible while the character sheet is open. M4.2 now supplies the small baseline: one unambiguous backpack, three generic equipped cells, non-destructive cross-area drag staging, and click/tap/keyboard fallback. The current full-six-position answer is **Skip Gear / Keep Current Build**: the new item is skipped and the paired ordinary reward still resolves. No sale or salvage occurs.

Future itemization work may evaluate explicit sell/salvage, opt-in auto-salvage rules, rarity tiers, uniques, affixes, and typed data-driven set items/set bonuses. The implemented non-destructive drag/snap-back and click/tap/keyboard confirmation contracts must be preserved. A larger character sheet, combat-time management policy, category-specific equipment slots, deterministic item-instance rolls, economy values, and set thresholds remain unresolved design decisions. This backlog record does not add implemented content or authorize a later milestone.

### District cards

Milestone 5 implements exactly four validated `DistrictCardDefinition` Resources and four typed `CardEffectDefinition` payloads. The authored deck contains one copy of each card. Every cost is `0` and is displayed as `FREE`; no card currency, shop, or broader economy exists.

| Stable ID / name | Heat | Valid future node | Tags | Stable effect ID / typed effect and progression contract |
| --- | ---: | --- | --- | --- |
| `arcade` / Arcade | `+10` | `travel` | `FIGHT`, `REWARD` | `arcade_standard_encounter_reward_boost` / `ADD_STANDARD_ENCOUNTER`: replace the reached travel occurrence with one non-recursive standard encounter; advance its resulting standard reward by exactly one eligible authored quality tier, skipping absent tiers and clamping to the existing catalogue maximum. This is not a general upgrade system. |
| `convenience_store` / Convenience Store | `-10` | `travel` | `SHOP`, `RECOVERY` | `convenience_store_existing_stock_purchase` / `OPEN_ONE_PURCHASE_SHOP`: replace the reached travel occurrence with a shop/recovery visit allowing at most one purchase from the run's existing finite cooling stock. It cannot replenish stock or create a broader economy. |
| `gang_hideout` / Gang Hideout | `+20` | `encounter` | `ELITE`, `EQUIPMENT` | `gang_hideout_viper_signal_elite` / `ADD_ELITE_ENCOUNTER`: replace the reached baseline encounter with the existing scaled `viper_signal` elite-eligible placeholder and guarantee an equipment choice. It does not add the Milestone 6 Viper Enforcer actor or other later enemy content. |
| `subway_entrance` / Subway Entrance | `-15` | `encounter` | `REROUTE`, `SKIP` | `subway_entrance_reroute_skip` / `REROUTE_SKIP_STANDARD`: reroute the reached future segment and skip exactly that one baseline standard encounter. It consumes/replenishes no Subway intervention charge, reduces no Night Pressure, and cannot skip extraction progression, clear a queued boss, or bypass boss precedence. |

The finite state contract is an opening draw of two, hand capacity three, a draw pile containing the two cards not opened, immediate hand-to-discard movement on confirmed placement, and no discard reshuffle during Milestone 5. A successful reward acquisition moves exactly one selected card from draw pile to hand; choices not selected remain in the draw pile. Clean restart reconstructs the one-copy deck and clears hand, discard, pending/resolved effects, placement/acquisition tokens, route modifications, modal/planning state, and cards-stream state before the deterministic opening draw.

Opening draws and reward choices first reject invalid/duplicate content, then sort by stable card ID and draw only from the run-scoped `cards` stream. A supplemental opportunity follows the existing core reward contract for each eligible baseline non-elite standard encounter while valid cards remain. It offers up to three remaining cards; **Skip / Keep Hand** is available, including at the three-card hand cap. Card-created encounters, elite encounters, shops, reroutes, and card effects never generate recursive card rewards. The feature consumes no `encounters`, `spawns`, `rewards`, `equipment`, `enemy_variants`, or `cosmetic` draw for card selection; schema version 1 is unchanged. Reproduction remains bounded to an identical supported build, content revision, schema version, seed, gameplay decisions, and authoritative timing.

`PatrolController` exposes exactly five current-window future route slots identified as `<route-id>::route_slot::<occurrence-index>`, paired with stable `<route-id>::occurrence::<occurrence-index>` identities. Each snapshot carries the future route index, loop, node ID/type, status, occupied card/effect, token, and route revision. One card may occupy an occurrence. Wrong-node, current, past, expired, occupied, out-of-window, stale-revision, duplicate-token, invalid, and outside placements reject without authoritative mutation.

The player stages a card/slot pair with expected hand and route revisions, then confirms its token. Only confirmation moves the card to discard, registers the pending route effect, and makes `RunFlowController` ask `RunDirector` to apply the card's Heat delta exactly once. On reaching that authored future occurrence, `CardSystem` and `PatrolController` consume the pending record exactly once before baseline node dispatch; the card effect replaces that occurrence's baseline behavior and moves into resolved route history. No card directly changes Night Pressure or its extraction/boss latches.

Planning opens only during safe `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE` states outside active combat. Patrol planning owns a pause, so eligible time and Night Pressure do not advance. An unsafe progression transition ends planning and clears its staged token synchronously; stale confirmation then rejects before Heat or route mutation. The 1280 x 720 HUD shows hand/draw/discard counts, all required card detail, five target slots and explicit statuses, valid-target highlights, staged confirmation, invalid/outside return feedback, and pending/resolved route/minimap changes. Typed native drag/drop includes an 8-pixel mouse/touch fallback and first-pointer ownership; right-click cancels an active drag. Click, tap, focus, keyboard activation, and explicit target buttons provide the full alternative path.

Milestone 5 passed **188/188 cumulative tests and 2,450 assertions with no failures or skips across 15 suites**: the preserved 145-test/1,709-assertion baseline plus 43 M5 tests/741 assertions. Configured `/GameRun`, fresh Windows/Web exports, Windows runtime smoke, real Web pointer/click/rejection flows, clean Web restart, 1280 x 720 containment, and an empty Web warning/error console passed. Evidence: `res://docs/screenshots/milestone_5_district_cards.png`. This technical acceptance is local only; the M5 branch is uncommitted, unpushed, unmerged, unpublished, and undeployed, while the public Pages build remains the published M4–M4.2 commit above.

### Implemented optional coin clusters

Coin clusters are the implemented optional Combat Lab ambient interaction under `LootContainer`.

- Each coin-rewarding defeated enemy creates one cluster; explicitly rewardless enemies create none.
- Milestone 1 clusters retain fixed authored base values; Milestone 3 standard reward selection separately uses the `rewards` stream.
- Ignored clusters auto-collect after approximately 2.5 seconds for the full base value.
- A successful manual collection is immediate and may advance an approximately 3-second streak.
- Manual streak bonus tuning is data-driven and capped at 10% of that cluster's base value; auto-collection receives no manual bonus.
- Click and timeout are mutually exclusive resolutions of one authoritative award, so the base value is credited at most once.
- `RewardDirector`, not the cluster presentation or combat actor, owns the coin ledger, resolution state, and streak.
- The presentation uses a 32px mouse/touch shape, pointer cursor, pulse, hover response, and persistent `CLICK / TAP` affordance.
- Combat Lab placement enforces a 76px center exclusion around the Hydrant so the two generous interaction areas do not overlap.

### Escalation and finite cooling

| Value | Authority | Implemented behavior |
| --- | --- | --- |
| Heat | `RunDirector` | Tactical district alert clamped to 0–100; exact tiers change immediate danger/reward conditions and receive finite cooling |
| Night Pressure | `RunDirector` | Non-negative and irreversible during a run; eligible time and exactly-once completions advance scaling, extraction latches, and unavoidable boss queueing |

Night Pressure thresholds latch when crossed. A boss reached at an unsafe transition is queued until the next valid boundary, and the boss takes precedence when it and an extraction threshold are reached by the same authoritative update unless extraction was already confirmed. Cooling cannot reduce Night Pressure, reopen a spent extraction threshold, or clear a queued boss.

Shop cooling costs 60 coins and has two purchases per run. Subway Reroute starts with two charges and does not regenerate merely through elapsed time. Both reduce Heat only; zero-stock requests reject without mutation.

### Run-scoped deterministic streams

`RunDirector` owns one authoritative integer seed and a non-Autoload `RunRandomStreams` child with seven streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Schema 1 derives sub-seeds with `fnv1a32_utf8_v1` from canonical UTF-8 text. Gameplay candidates are deterministically filtered, duplicate/empty stable IDs are excluded, and remaining IDs are sorted before selection. The `cosmetic` stream is isolated so presentation draws cannot alter gameplay outcomes.

Milestone 5 authorizes only the District Cards content above. Milestone 6 crew, enemy/elite actor, boss, intervention, content/presentation/audio/tutorial/settings/persistence/final-summary work; procedural route generation; additional districts/cards; card currency/economy; equipment selling/salvage/rarity/uniques/affixes/sets; and broad progression or persistence remain unimplemented and unauthorized.
