# Neon Loop Content Catalog

## Catalog status

This catalog reflects the implemented **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, **Milestone 2 — Player Intervention**, and **Milestone 3 — Complete Run Structure**. Entries explicitly marked as placeholders still reserve later ownership or screen space; listing deferred vertical-slice content does not authorize it.

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
| Minimap | District route, crew location, encounters, extraction point |
| Heat and timer | Heat value/tier and run time |
| Crew status | Compact and expanded crew health/status space |
| Equipment and synergies | Equipment summary and synergy thresholds |
| District cards | Card hand and route-placement space |
| Interventions | Intervention controls and charge/cooldown space |
| Extraction | Extraction action and reward multiplier space |

Run state, route progress, Heat/tier, Night Pressure, elapsed time, extraction/cooling actions, summary, Jax health/state/target, coin total, manual streak, Fire Hydrant state/cooldown, fullscreen state, and player guidance are live presentation values. Their native-scale typography, meters, and framing are enlarged for common 16:9 displays; compact labels preserve the central fight area. Equipment/synergy and district-card displays remain placeholders. No HUD region owns authoritative gameplay state.

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
| `PatrolController` | Authored route progress, safe boundaries, encounter pauses, and reroute movement |
| `CombatDirector` | Actor registration, targeting, reservations, hit resolution, hit-stop, cleanup, safe-space assignment, and typed environmental-hit authority |
| `RewardDirector` | Coin ledger, at-most-once clusters/manual streak, and Milestone 3 standard reward selection/accounting |
| `RunEncounterController` | Encounter identity, deterministic spawning/lanes, scaling, caps, completion, and cleanup |
| `RunCoolingController` | Finite Subway charges and finite priced shop-cooling stock |
| `RunFlowController` | Typed run/patrol/encounter/reward/cooling coordination |
| `FireHydrantController` | Milestone 2 circle validation, deterministic area resolution, rejection, and cooldown authority |
| `DisplayController` | Presentation-only fullscreen, landscape, and safe-area integration |
| `CardSystem` | Typed responsibility description only |
| `SynergySystem` | Typed responsibility description only |

## Assets

Milestones 1–3 use project-native code-drawn placeholder actors, health/target indicators, hit/death/spawn/water effects, damage numbers, Hydrant and coin presentation, and deterministic generated PCM cues. These are deliberately replaceable evaluation assets, not production sprites or audio. No production character sprites, enemy sprites, equipment icons, card art, or music are cataloged as implemented.

The existing project icon and Godot MCP addon files are project/development support, not Neon Loop gameplay content.

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

The visual-direction reference is stored at `res://docs/reference/neon_loop_gameplay_mockup.png`; it is inspiration only and does not authorize the later systems depicted in it. Milestone 1 evidence is stored at `res://docs/screenshots/milestone_1_combat_lab.png`. Milestone 2 evidence is stored at `res://docs/screenshots/milestone_2_player_intervention.png`. Milestone 3 evidence is stored at `res://docs/screenshots/milestone_3_complete_run_structure.png`.

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

Standard reward candidates are quality-filtered, empty/duplicate stable IDs are excluded, remaining IDs are sorted, and the isolated `rewards` stream selects the result. Current Heat reward multipliers then use deterministic integer rounding. Equipment/card rewards remain absent.

### Run lifecycle and technical record

- `RunDirector` implements `INITIALIZING`, `INTRO`, `PATROLLING`, `ENCOUNTER_ACTIVE`, `REWARD_SELECTION`, `SHOP`, `EXTRACTION_AVAILABLE`, `EXTRACTING`, `BOSS_INTRO`, `BOSS_ACTIVE`, `VICTORY`, `DEFEAT`, `RUN_SUMMARY`, and `PAUSED`.
- Night Pressure and the run timer advance only during eligible active simulation. Modal choices, pause, introduction, extraction/boss transitions, terminal states, and summary add zero.
- The two extraction thresholds and boss threshold latch permanently for the run. A queued boss begins at the next safe boundary and wins a same-update crossing unless extraction was already confirmed.
- Exactly two Subway and two shop cooling uses are available per run; cooling changes Heat only and cannot alter Night Pressure or latched progression.
- `RunRandomStreams` exposes exactly `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Reserved equipment/card streams are compatibility infrastructure only.
- Technical verification passed 75/75 tests and 1,100 assertions with no failures or skips, preserved all 46 Milestone 1–2 tests, and completed clean local Windows/Web smoke checks. No build was published or deployed.

## Remaining specified content and contracts

The following names and contracts come from `GameSpecifications.md`. Named crew/enemies and later systems remain deferred unless a subsection explicitly identifies implemented Milestone 1, Milestone 2, or Milestone 3 behavior.

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

Wet application and combo continuation remain future compatibility contracts only. No general status-effect, Wet, combo-meter, or combo-reward system is implemented through Milestone 3.

### Equipment

The vertical-slice catalogue contains these nine definitions. None is implemented through Milestone 3.

| Equipment | Tags | Primary-synergy role |
| --- | --- | --- |
| Spiked Bat | `MELEE`, `BLEED`, `KNOCKBACK` | Bleed/Knockback bridge |
| Shock Gloves | `TECH`, `SHOCK`, `FAST` | Tech candidate |
| Reinforced Jacket | `DEFENCE`, `STREET` | Defensive non-primary option |
| Hacker Deck | `TECH`, `INTERVENTION` | Tech candidate |
| Steel-Toe Boots | `KNOCKBACK`, `MOBILITY` | Knockback candidate |
| Serrated Wraps | `BLEED`, `FAST` | Bleed candidate |
| Magnetic Flail | `TECH`, `KNOCKBACK` | Tech/Knockback bridge |
| Voltaic Blade | `TECH`, `BLEED` | Tech/Bleed bridge |
| Chain Sneakers | `FAST`, `KNOCKBACK` | Knockback candidate |

The vertical slice uses three generic equipment slots so any distinct pair above can form a valid combination. One persistent unlock may gate one of these nine entries; it does not imply a required tenth item.

### Synergies

| Synergy | Eligible catalogue items | Valid two-item combinations | Required minimum |
| --- | ---: | ---: | ---: |
| Knockback 2 | 4 | 6 | 3 |
| Bleed 2 | 3 | 3 | 3 |
| Tech 2 | 4 | 6 | 3 |

There are three cross-primary bridge items—Spiked Bat, Magnetic Flail, and Voltaic Blade—exceeding the requirement for at least two. Future reward and synergy UI must preview both immediate activation and progress toward alternative paths. These counts describe the specified catalogue only; no tags, thresholds, modifiers, or UI previews are implemented yet.

### District cards

- Arcade
- Convenience Store — one shop/recovery purchase; cooling must remain finite
- Gang Hideout
- Subway Entrance — finite reroute/cooling effect; cannot reduce Night Pressure or skip extraction/boss progression

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

Listing deferred content does not authorize its implementation beyond Milestone 3.
