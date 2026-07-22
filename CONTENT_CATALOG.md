# Neon Loop Content Catalog

## Catalog status

This catalog reflects the implemented **Milestones 0–6**. Milestone 5 remains the last fully accepted 188-test/2,450-assertion baseline. Milestone 6 passed its 244-test/3,234-assertion automated gate and configured headless boot, and the owner marked it tentatively complete for Pages playtesting. Representative outcomes, cadence acceptance, browser/device/presentation checks, and final owner-manual acceptance remain explicit `MILESTONE_6_PLAYTEST.md` work; this catalogue does not invent a qualitative result.

Milestone 5 was merged through PR #4 and published from `main` commit `da934897cbdee44cb4d1a44b25e91b458558bfbc`; it remains the last fully accepted baseline. Milestone 6 was committed on `codex/milestone-6-vertical-slice` as `9c1cdaa` plus `ca3fe18`, and the owner authorized its tentative [GitHub Pages playtest](https://ariesyous.github.io/projectneon/) publication on 2026-07-22.

The working tree separately carries the owner's tracked 17-file Godot-AI 3.0.5 update and the owner's `project.godot` deletions of `window/stretch/aspect="keep"` and `textures/default_filters/use_nearest_mipmap_filter=false`. Godot-AI remains enabled development tooling, not Neon Loop content or run authority. Milestone 6 adds only the specification-authorized `SaveService` and `AppState` Autoloads; it does not claim the owner-carried changes as milestone content.

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
| Crew container | Stage container | Hosts the selected Jax/Zoey/Rex actor plus temporary Backup Runners |
| Enemy container | Stage container | Hosts capped mixed basic encounters, Viper Enforcer, The Viper, and boss summons |
| Effects container | Stage container | Hosts replaceable combat feedback, optional damage numbers, projectiles, and labelled boss ground telegraphs |
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

Run state, route progress, Heat/tier, Night Pressure, elapsed time, extraction/cooling actions, selected-crew health/state/target, coins/streak, all three intervention states, combo, boss health/phase/named warnings, three generic active equipment slots, one clearly named three-slot backpack, tag/synergy progress, equipment/card reward flows, contextual tutorial prompts, settings, final summary, fullscreen state, and player guidance are live presentation values. The native 1280 × 720 HUD retains the logical 640 × 360 world and a 16-pixel minimum for ordinary labels/buttons. `VerticalSliceOverlay` adds the crew menu, pause/settings surfaces, boss strip, tutorial/combo strips, victory treatment, and complete summary. Validity, cooldowns, warnings, locks, and progression state always include text rather than colour alone. No HUD or overlay region owns authoritative gameplay state.

The HUD presents the Milestone 1 manual coin streak, Milestone 2 Hydrant/onboarding/display state, and Milestone 3 run/escalation/actions/summary state. Seed, schema, named-stream draw counts, encounter/cooling status, and latches are visible through the development overlay.

### Development tools

| Tool | Control | Current state |
| --- | --- | --- |
| DebugOverlay | `F1` | Toggleable development information shell |
| Lane guides | DebugOverlay button or `F2` | Requests that Downtown Loop show or hide all three lane visuals |

### Runtime ownership state

| Class | Current content |
| --- | --- |
| `RunDirector` | State graph, eligible timer, Heat, Night Pressure, thresholds, pause ownership, boss/victory timing, seed, outcomes, and summaries |
| `RunRandomStreams` | Seven isolated, schema-versioned deterministic stream states; run-scoped child of `RunDirector` |
| `PatrolController` | Authored route progress, safe boundaries, encounter pauses, finite Subway reroute movement, five stable future occurrence slots, route revisions, and exactly-once pending/resolved route modifications |
| `CombatDirector` | Actor registration, targeting, reservations, hit resolution, projectiles, charge/area/summon dispatch, boss phase events, hit-stop, equipment modifier/effect application, cleanup, safe-space assignment, and environmental-hit authority |
| `RewardDirector` | Coin ledger, at-most-once clusters/manual streak, standard rewards, deterministic equipment choices, exactly-once Equip/Store/Keep Current Build resolution, and supplemental card reward presentation/application coordination without using the `rewards` stream for card selection |
| `RunEncounterController` | Actor-catalogue/crew/ally/enemy spawning, deterministic roster/lanes, scaling, caps, boss summons/results, defeat counts, coin requests, completion, and cleanup |
| `RunCoolingController` | Finite Subway route/cooling charges and finite priced shop-cooling stock; no Night Pressure access |
| `RunFlowController` | Typed run/patrol/encounter/reward/equipment/cooling/card/boss/summary coordination, starter equipment, safe planning pause, exactly-once Heat application, non-recursive reward gating, and future-node dispatch |
| `FireHydrantController` | Circle validation, area damage/knockback/Wet resolution, immutable rejection, and cooldown authority |
| `CallBackupController` | Two-charge/two-ally transaction, cooldown, combat-only lifetime, defeat/terminal/restart cleanup, and immutable rejection |
| `ComboTracker` | Shared crew/environmental combo, eligible-time expiry, highest value, and presentation milestones only |
| `RunCadenceTracker` | Measurement-only ambient/strategic/major opportunity timestamps against eligible time |
| `DisplayController` | Presentation-only fullscreen, landscape, and safe-area integration |
| `CardSystem` | Finite four-card draw pile, three-card-cap hand, discard, deterministic `cards`-stream draws/reward choices, placement/acquisition tokens and revisions, validation, pending/resolved effects, and clean restart |
| `SynergySystem` | Three active generic slots, one three-slot ordered inactive backpack, unique ownership, active-only deterministic aggregation, revisioned inventory transactions, synergy thresholds/signals, and non-mutating choice previews |
| `ApplicationSettingsController` | Applies sanitized audio/display/accessibility presentation and forwards focus-pause intent to `RunDirector` |
| `TutorialPromptController` | Stable-ID once-per-run nonmodal contextual prompt coordination |
| `AudioPresentationController` | Generated district/boss music and 17 SFX cues on Music/SFX buses |
| `SaveService` / `AppState` | Versioned profile I/O and application-level settings/unlocks only; never active-run authority |

## Assets

Milestones 1–6 use project-native code-drawn actor variants, health/target/status indicators, state poses, hit/death/spawn/water/projectile/telegraph effects, optional damage numbers, generated equipment/synergy visuals, four replaceable District Card SVG icons, three replaceable intervention SVG icons, and deterministic generated PCM music/SFX. These are deliberately replaceable finished-prototype assets, not claimed final production sprites or recorded audio. Replacing presentation references changes no gameplay identity, rule, or deterministic order.

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

### Intervention icons

| Stable intervention ID | Replaceable visual |
| --- | --- |
| `fire_hydrant` | `res://assets/icons/interventions/fire_hydrant.svg` |
| `call_backup` | `res://assets/icons/interventions/call_backup.svg` |
| `subway_reroute` | `res://assets/icons/interventions/subway_reroute.svg` |

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

The visual-direction reference is stored at `res://docs/reference/neon_loop_gameplay_mockup.png`; it remains inspiration rather than a source of extra scope. Milestone 1 evidence is stored at `res://docs/screenshots/milestone_1_combat_lab.png`. Milestone 2 evidence is stored at `res://docs/screenshots/milestone_2_player_intervention.png`. Milestone 3 evidence is stored at `res://docs/screenshots/milestone_3_complete_run_structure.png`. Milestone 4 evidence is stored at `res://docs/screenshots/milestone_4_equipment_synergies.png`. Milestone 4.1 evidence is stored at `res://docs/screenshots/milestone_4_1_inventory_readability.png`. Milestone 4.2 evidence is stored at `res://docs/screenshots/milestone_4_2_inventory_drag.png`. Milestone 5 evidence is stored at `res://docs/screenshots/milestone_5_district_cards.png`. Fresh Milestone 6 visual evidence has not yet been accepted and is not claimed here.

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
| `milestone_6_vertical_slice_escalation` | `RunEscalationDefinition` | **Configured M6 tuning:** 0.07 Pressure/eligible second; +1.5 standard/+3.0 elite; preserved +1% health/+0.5% damage/+1.25% budget per Pressure, cap 30, extraction 18/36, boss 50 |
| `milestone_6_run_lifecycle` | `RunLifecycleDefinition` | Intro 1.25s; extraction 1.0s; boss intro 2.5s; victory presentation 2.0s |
| `milestone_6_starting_loadout` | `RunLoadoutDefinition` | Start with exactly 1 crew; maximum active crew 3; selectable IDs `jax`, `zoey`, `rex` |
| `milestone_6_cadence` | `RunCadenceDefinition` | Ambient 10–20, strategic 30–60, major 120–180 eligible active seconds |

`milestone_3_escalation` remains tracked as the accepted historical M3 Resource. Configured `GameRun` now assigns `milestone_6_vertical_slice_escalation`; Heat, cooling, route, and random-schema Resources remain the accepted definitions above.

### Encounters

| Content ID | Type | Authored values |
| --- | --- | --- |
| `alley_scuffle` | `EncounterDefinition` | Heat tier 0 / Pressure 0; budget 3; cap 3; +4 Heat; reward `street_cache`; minimum 1 `street_punk`, then stable budget choices from `bat_thug` (max 3) / `street_punk`; first spawn 3.0s, then one every 12.0s |
| `arcade_ambush` | `EncounterDefinition` | Heat tier 1 / Pressure 8; budget 4; cap 4; +4 Heat; rewards `street_cache`,`neon_stash`; minimum 1 `street_punk`, then `bat_thug` (max 3) / `bottle_thrower` / `street_punk`; first spawn 3.0s, then one every 12.0s |
| `viper_signal` | `EncounterDefinition` | Heat tier 3 / Pressure 20; budget 5; cap 5; elite; +8 Heat; rewards `neon_stash`,`viper_cache`; minimum 1 `viper_enforcer`, then all three basic IDs (`bat_thug` max 3); first spawn 3.0s, then one every 12.0s |
| `viper_showdown` | `EncounterDefinition` | Boss; Pressure 50; budget 1; cap 3 (boss plus two summons); lane 1; exactly 1 `the_viper`; immediate 0s/0s entry; no ordinary reward table; 0 Heat; completion `boss_defeated` |

Each spawn entry costs one budget. Entries and eligible IDs are validated/deduplicated/sorted by actor ID; `enemy_variants` constructs the complete ordered actor-ID plan at encounter start, and `spawns` selects a stable lane when each queued actor is released. The three non-boss encounters stage that queue after the authored 3.0-second entry delay at one actor per 12.0-second interval; a full concurrency cap retries the elapsed spawn when a slot is available, and encounter completion waits for both the queue and live enemies. These timers consume no random draw. Heat and Night Pressure still scale budget, health, and damage through typed definitions. Per-encounter and global caps apply after deterministic non-negative round-half-up budget scaling. The boss spawns immediately after its separate intro; The Viper's one-shot summon adds the two authored basic IDs `bat_thug` and `street_punk` in stable order.

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

## Implemented Milestone 6 vertical-slice content

### Stable actor catalogue

`milestone_6_actor_catalogue` maps exactly nine stable actor IDs to composed scenes: `backup_runner`, `bat_thug`, `bottle_thrower`, `jax`, `rex`, `street_punk`, `the_viper`, `viper_enforcer`, and `zoey`. Lookup validates non-empty unique IDs and returns IDs in stable lexical order. Code-drawn `ActorVisual` variants provide distinct palettes/silhouettes and state poses; they remain replaceable presentation rather than gameplay identity.

All actor definitions use base `damage_multiplier = 1.0` and `damage_taken_multiplier = 1.0`. Unless a row says otherwise, maximum stun duration is 5.0 seconds and control lockout is 0.0. Permanent crew and Backup Runner are rewardless; the boss is rewardless.

| Actor ID | Initial lane | Attack hitbox | Hurtbox capsule (radius / height) | Visual variant |
| --- | ---: | --- | --- | --- |
| `jax` | 1 | 34×22 | 10 / 46 | Jax |
| `zoey` | 0 | 32×20 | 9 / 44 | Zoey |
| `rex` | 2 | 38×24 | 12 / 50 | Rex |
| `backup_runner` | 1 | 32×20 | 9 / 44 | Backup |
| `street_punk` | 1 | 32×20 | 10 / 44 | Street Punk |
| `bat_thug` | 1 | 40×24 | 11 / 46 | Bat Thug |
| `bottle_thrower` | 0 | 26×18 | 9 / 42 | Bottle Thrower |
| `viper_enforcer` | 1 | 42×26 | 13 / 52 | Viper Enforcer |
| `the_viper` | 1 | 48×30 | 15 / 58 | The Viper |

Presentation palettes use `main / dark / accent / skin` hex values: Jax `19d9e7/07526d/d5fbff/f1a36f`; Zoey `b84dff/3c176f/5ff6ff/d88b61`; Rex `ff9d2e/793612/fff0a6/a96948`; Street Punk `ef3f8f/66214f/ff9a3d/d48756`; Bat Thug `d14a72/56152f/ffd45a/b9704d`; Bottle Thrower `4bd08a/145b48/aaffdf/d08a5f`; Viper Enforcer `7ad33b/203f18/e9ff62/9e6548`; The Viper `a72ee8/35125d/fff28a/c27b54`; Backup Runner `4f83ff/18366e/e8f2ff/d99a6b`. The Enforcer adds a 17px bright arc at 3px width; The Viper adds a 20px bright arc at 4px width, a pink crown line, and 1.16× body scale.

#### Crew and temporary ally definitions

| Stable ID / role | Health | Move | Base damage | Knockback / stagger / light armour | Authored role modifiers | Existing starter / cleanup |
| --- | ---: | ---: | ---: | --- | --- | --- |
| `jax` / Jax, Brawler | 520 | 112 | 20 | 0.18 / 0.15 / 55 | 1.25× environmental-collision damage | `spiked_bat`; 0s |
| `zoey` / Zoey, Tech Fighter | 400 | 124 | 12 | 0.10 / 0.10 / 35 | 0.85× intervention cooldown | `shock_gloves`; 0s |
| `rex` / Rex, Bruiser | 720 | 84 | 30 | 0.55 / 0.65 / 120 | 1.25× damage against elites; 1.25× against bosses | `reinforced_jacket`; 0s |
| `backup_runner` / temporary ally | 160 | 104 | 10 | 0.12 / 0 / 0 | no reward; temporary-ally role | none; immediate authority cleanup |

Every selectable crew member enters with exactly one existing catalogue item. No tenth equipment item or permanent statistical unlock is introduced. `milestone_6_starting_loadout` starts exactly one of `jax`,`zoey`,`rex` and retains the maximum active crew size of three.

#### Enemy definitions

| Stable ID / role | Health | Move | Base damage | Knockback / stagger / light armour | Control / range / enrage | Reward / cleanup |
| --- | ---: | ---: | ---: | --- | --- | --- |
| `street_punk` / basic | 58 | 86 | 2 | 0.02 / 0 / 0 | melee defaults | 40 coins; 0.65s |
| `bat_thug` / basic | 110 | 64 | 8 | 0.12 / 0.10 / 0 | melee defaults | 60 coins; 0.70s |
| `bottle_thrower` / basic ranged | 50 | 78 | 5 | 0.02 / 0 / 0 | prefers 125–180px | 50 coins; 0.65s |
| `viper_enforcer` / elite | 420 | 78 | 15 | 0.55 / 0.50 / 170 | stun cap 0.75s; control lockout 0.80s | 120 coins; 0.85s |
| `the_viper` / boss | 1,800 | 96 | 12 | 0.85 / 0.75 / 220 | stun cap 0.35s; 2.0s lockout; enrage at 40% health: 1.20× damage and 1.25× attack speed | 0 coins; 1.20s |

Light knockback with force at or below `light_stagger_armour` is ignored. Other knockback is multiplied by `1 - knockback_resistance`. Stun duration is multiplied by `1 - stagger_resistance`, capped, then followed by the authored control lockout; these rules supply elite armour and anti-permanent-lock behavior without an ID-specific invulnerability branch.

#### Attack definitions

Timing is `windup / active / recovery / ordinary cooldown` in seconds. Range is `maximum / minimum` pixels; knockback is `force / duration`.

| Stable attack ID / name | Delivery / impact | Damage × | Timing | Range | Knockback | Hit-stop | Special payload |
| --- | --- | ---: | --- | --- | --- | ---: | --- |
| `jax_basic_punch` / Cross Punch | melee / heavy | 1.0 | .20/.08/.34/.22 | 52/0 | 155/.18 | .075 | Jax short-range heavy basic |
| `zoey_rapid_strike` / Rapid Circuit Strike | melee / light | 1.0 | .12/.06/.20/.12 | 52/0 | 70/.10 | .035 | fast basic |
| `rex_heavy_hook` / Concrete Hook | melee / heavy | 1.0 | .38/.10/.52/.42 | 56/0 | 125/.18 | .090 | slow heavy basic |
| `backup_runner_punch` / Backup Jab | melee / light | 1.0 | .20/.07/.28/.25 | 52/0 | 80/.12 | .040 | temporary ally basic |
| `street_punk_basic_punch` / Street Jab | melee / light | 1.0 | .31/.08/.42/.38 | 52/0 | 68/.14 | .040 | basic punch |
| `bat_thug_heavy_swing` / Heavy Bat Swing | melee / heavy | 1.0 | .58/.10/.62/.65 | 56/0 | 185/.24 | .080 | slow high-knockback swing |
| `bottle_throw` / Readable Bottle Throw | projectile / light | 1.0 | .62/.08/.45/1.20 | 180/125 | 40/.10 | .035 | `bottle_projectile` |
| `viper_enforcer_heavy` / Enforcer Hammer | melee / heavy | 1.0 | .48/.10/.58/.50 | 58/0 | 175/.22 | .080 | elite basic |
| `viper_enforcer_charge` / Armoured Charge | charge / heavy | 1.6 | .75/.10/.55/.75 | 220/70 | 240/.30 | .095 | 3.5s special cooldown; .75s telegraph; 240px charge |
| `viper_melee_combo` / Viper Three-Hit Combo | melee / boss | 1.0 | .24/.16/.42/.42 | 62/0 | 95/.12 | .055 | three direct-hit resolutions |
| `viper_charge` / Viper Rush | charge / boss | 1.8 | .80/.12/.48/.48 | 240/76 | 220/.26 | .100 | 4.5s special cooldown; .80s telegraph; 280px charge |
| `viper_area_warning` / Venom Ring | area / boss | 2.1 | 1.10/.12/.60/.55 | 100/0 | 150/.20 | .090 | 6.0s special cooldown; 1.10s telegraph; 92px radius |
| `viper_summon` / Call the Vipers | summon / boss | 0 | .90/.10/.55/.40 | 300/0 | 0/0 | 0 | 8.0s special cooldown; .90s telegraph; one-shot stable summon IDs `bat_thug`,`street_punk` |

Special definitions are deduplicated and sorted by stable attack ID. After at least one basic attack, each actor selects the next available special in that stable cycle; per-special cooldown and `one_shot` state are deterministic and consume no random stream.

#### Projectile definition

| Stable ID | Speed | Lifetime | Collision / visual radius | Colours | Runtime contract |
| --- | ---: | ---: | --- | --- | --- |
| `bottle_projectile` | 105 px/s | 2.5s | 8 / 5px | primary `(0.45,1,0.72,1)`; accent `(0.9,1,0.92,1)` | Lane-readable projectile stepped in stable spawn order; resolves one direct hit or expires/cleans on run transition |

### Interventions

| Stable ID / name | Authored tuning | Validity and immutable-rejection contract | Presentation |
| --- | --- | --- | --- |
| `fire_hydrant` / Fire Hydrant | 112px circle; 18 damage; fixed leftward 300-force/.30s knockback; 4.0s Wet; 8.0s base cooldown; .55s water/.28s impact/.50s rejection | Requires at least one live registered enemy in the circle and no active cooldown; locks before callbacks; rejected requests consume no cooldown or effect | SVG icon, world/HUD name, exact hover/focus area preview, textual target/cooldown state, tooltip, water/impact/rejection feedback |
| `call_backup` / Call Backup | exactly 2 `backup_runner` allies; 12 eligible combat seconds; 2 charges; 30.0s base cooldown | Requires eligible active enemy combat, no current backup, charge, completed cooldown, and successful creation/registration of both allies; transaction rolls back on failure; allies leave at expiry, defeat, terminal state, or restart | SVG icon, charge/cooldown/ally/duration text, tooltip, accepted/rejected/left feedback |
| `subway_reroute` / Subway Reroute | 2 run charges (cap 2); -15 Heat; immediate next authored occurrence | Requires `PATROLLING`, `PatrolController.can_reroute()`, and charge; cannot activate during boss/encounter, reduce Pressure, clear/reopen thresholds, regenerate, or consume a card-owned Subway skip; invalid/exhausted requests mutate nothing | SVG icon, charge and `-15H` text, tooltip, enabled/disabled state, typed applied/rejected feedback |

Zoey's 0.85 authored cooldown multiplier multiplies the active-equipment/synergy intervention multiplier. Hacker Deck contributes -10% and Tech 2 contributes -15% additively within that equipment multiplier. Both Hydrant and Backup preserve their remaining-cooldown ratio when the composed multiplier changes; no modifier changes Subway charges.

### Combo, telegraphs, animation, and screen effects

| Stable/resource ID | Authored values | Contract |
| --- | --- | --- |
| `milestone_6_combo` | 2.5 eligible-second expiry; presentation milestones 10/20/30/50 | Shared crew/environmental hits; highest combo enters summary; no damage/reward/escalation modifier |
| `milestone_6_screen_shake` | light 1.5px/.12s; heavy 3.5px/.20s; environmental 5px/.20s; boss 6px/.20s; 34 oscillations/s | Deterministic presentation only; multiplied by saved 0–1 intensity; reset restores authored camera offset |
| Boss warning presentation | minimum overlay warning .45s; charge marker radius 48px; summon marker 64px; area uses authored 92px | Named text plus pulsing circle/crosshair; freezes during pause and clears on terminal/restart/menu |

The nine `ActorVisual` variants use state-driven idle bob, walk stride, windup lean, active extension, recovery, knockback, incapacitated, and death poses. The Viper draws at 1.16× scale; Viper Enforcer and The Viper use explicit bright outline/accent treatments. Presentation palette and poses never decide hit timing or state transitions.

### Settings and versioned persistence

#### Settings defaults

| Stable field | Default | Valid range / application |
| --- | ---: | --- |
| `master_volume` | 0.80 | 0–1; `Master` bus |
| `music_volume` | 0.65 | 0–1; `Music` bus |
| `sound_effects_volume` | 0.80 | 0–1; `SFX` bus |
| `fullscreen` | `false` | windowed/fullscreen `Window` mode |
| `screen_shake_intensity` | 0.75 | 0–1 multiplier; zero clears active shake |
| `damage_numbers_enabled` | `true` | hides/shows presentation numbers only |
| `hit_flash_reduction` | 0.00 | 0–1; scales flash duration, 1 disables it |
| `pause_on_focus_loss` | `true` | forwards typed pause intent; `RunDirector` accepts only at a valid boundary |

Numeric fields sanitize to 0–1; missing/wrong-type optional fields use these defaults. Settings persist through the profile and are available from main menu or pause. The pause menu remains available through `Space`/`Escape` outside unskippable transitions; card-owned pause cannot be released by ordinary pause input.

#### Profile schema and production access

| Stable profile fact | Authored value |
| --- | --- |
| Path / version | `user://neon_loop_profile_v1.json`; `save_version = 1` |
| Production default crew | `jax` |
| Production default equipment | `chain_sneakers`, `magnetic_flail`, `reinforced_jacket`, `serrated_wraps`, `shock_gloves`, `spiked_bat`, `steel_toe_boots`, `voltaic_blade` |
| Production default cards | `arcade`, `convenience_store`, `subway_entrance` |
| Development/test access | all `jax`,`rex`,`zoey`; all nine existing equipment IDs; all four existing card IDs |
| Lifetime fields | non-negative `completed_runs`, `victories`, `extractions`, `defeats`, `elites_defeated` |

The save service performs `.tmp`/`.bak` atomic replacement. Missing files load safe defaults; malformed JSON, non-object roots, invalid/missing version, unsupported old versions, and read I/O failure recover to defaults with an explicit status. A version newer than 1 loads a sanitized read-only projection and rejects overwrite. Development reset removes only the configured profile plus its `.tmp`/`.bak` siblings, then writes defaults. Active runs are not saved.

#### Exact unlock policy

| Stable rule ID | Trigger | Existing content unlocked |
| --- | --- | --- |
| `first_completed_run_zoey` | any completed `victory`, `extracted`, or `defeated` run | crew `zoey` |
| `first_elite_defeat_hacker_deck` | completed run with at least one elite defeated | equipment `hacker_deck` |
| `first_extraction_gang_hideout` | completed `extracted` run | card `gang_hideout` |
| `first_victory_rex` | completed `victory` run | crew `rex` |

Rules apply in stable rule-ID order and are idempotent. No rule creates a tenth item, fifth card, permanent statistical bonus, currency grant, or active-run mutation.

### Contextual tutorial catalogue

All prompts are nonmodal, once per run, and default to six display seconds. One prompt exists per trigger; priorities are used for deterministic queue ordering.

| Stable prompt ID | Trigger | Priority | Authored heading and body |
| --- | --- | ---: | --- |
| `tutorial_run_controls` | `run_started` | 100 | **AUTO-BRAWL, YOUR DECISIONS** — “Your crew fights automatically. Use interventions and route choices when their labelled prompts appear. The labelled HELP button explains controls.” |
| `tutorial_coin_cluster` | `coin_cluster_available` | 80 | **COIN CLUSTER** — “Click or tap for a streak bonus. Ignore it safely and the full base value auto-collects.” |
| `tutorial_interventions` | `intervention_available` | 90 | **INTERVENTIONS** — “Choose Hydrant, Backup, or Reroute when its text says VALID. Rejected or exhausted requests spend nothing.” |
| `tutorial_equipment` | `equipment_choice_available` | 70 | **BUILD YOUR CREW** — “Active gear grants effects; Backpack gear is inactive. Inspect tags and the written synergy preview before confirming.” |
| `tutorial_district_cards` | `card_planning_available` | 75 | **DISTRICT CARDS** — “Place a card only on a future slot labelled VALID, then confirm. Heat changes; Night Pressure never cools.” |
| `tutorial_extraction` | `extraction_available` | 95 | **EXTRACTION WINDOW** — “Extract now to secure Scrap, or continue toward greater risk and The Viper. The choice is written beside both actions.” |
| `tutorial_boss` | `boss_intro` | 100 | **THE VIPER** — “Watch the named warning and ground marker before each major attack. The boss bar shows health and ENRAGED state.” |

### Prototype audio catalogue

All cues are deterministically synthesized at 22,050 Hz, mono, signed 16-bit PCM; synthesis consumes no run stream. Non-music cues use `SFX`, do not loop, and use a .005s attack unless noted. Waveforms are sine/triangle/square. `ratio` is the secondary-frequency ratio; `0` disables it.

| Stable cue ID | Bus / wave | Effective note pattern Hz; note length | Duration / gain / ratio / release | Loop |
| --- | --- | --- | --- | --- |
| `music_district_loop` | Music / triangle | 110,138.59,164.81,138.59,123.47,146.83,174.61,146.83; .50s | 4.00s/.18/2.0/0; attack 0 | yes |
| `music_boss_layer` | Music / triangle | 55,65.41,73.42,82.41,55,73.42,87.31,98; .25s | 4.00s/.16/1.5/0; attack 0 | yes |
| `sfx_light_hit` | SFX / sine | 760,520; .035s | .09s/.32/1.35/.035s | no |
| `sfx_heavy_hit` | SFX / triangle | 210,120; .07s | .18s/.46/.5/.07s | no |
| `sfx_knockback` | SFX / triangle | 330,220,145; .055s | .19s/.38/.75/.05s | no |
| `sfx_environment_collision` | SFX / square | 95,72; .08s | .20s/.24/1.8/.08s | no |
| `sfx_coin_auto_collect` | SFX / sine | 520,660; .055s | .12s/.22/0/.04s | no |
| `sfx_coin_manual_collect` | SFX / sine | 660,880; .055s | .13s/.30/2.0/.04s | no |
| `sfx_coin_streak_increase` | SFX / sine | 780,980,1170; .045s | .15s/.27/0/.03s | no |
| `sfx_card_placement` | SFX / triangle | 390,585,780; .06s | .20s/.25/0/.045s | no |
| `sfx_intervention_activation` | SFX / triangle | 180,270,405; .08s | .27s/.34/2.0/.06s | no |
| `sfx_heat_tier_increase` | SFX / square | 245,245,330; .09s | .30s/.20/0/.05s | no |
| `sfx_night_pressure_warning` | SFX / triangle | 96,128,96; .13s | .42s/.30/2.0/.08s | no |
| `sfx_extraction_available` | SFX / sine | 440,554.37,659.25; .11s | .38s/.30/2.0/.08s | no |
| `sfx_boss_introduction` | SFX / square | 82.41,73.42,65.41,55; .13s | .56s/.23/1.5/.10s | no |
| `sfx_victory` | SFX / sine | 440,554.37,659.25,880; .10s | .45s/.32/2.0/.08s | no |
| `sfx_defeat` | SFX / triangle | 220,174.61,130.81,98; .11s | .50s/.30/.5/.10s | no |
| `sfx_ui_hover` | SFX / sine | 620 constant; effective default .16s note | .055s/.14/0/.02s | no |
| `sfx_ui_confirm` | SFX / sine | 540,720; .05s | .12s/.20/0/.03s | no |

The presentation controller owns one district player, one boss-layer player, and eight rotating SFX voices. The versioned bus layout is `Master` with child `Music` and `SFX`. District/boss music and all required sound-effect categories remain replaceable prototype audio.

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

Ordinary clicks on active or stored items inspect only. In `INTRO`, `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE`, the player may drag or use the click/tap/keyboard fallback to stage an active item into an empty backpack slot or swap an item across occupied active/backpack positions. Cross-area dragging is lossless, same-area dragging is not a reorder operation, dropping outside valid targets is non-destructive, and every valid stage still requires Confirm. The player may deliberately discard the exact named item only through the separate destructive-confirmation action; during combat management controls reject while inspection remains available. Every mutation validates the inspected inventory revision and expected identity so stale, invalid, or mismatched requests reject without side effects. Successful active changes recalculate all build state immediately; backpack-only changes do not. Development/test access retains all nine entries; the production profile initially gates only `hacker_deck` under the exact unlock rule recorded above.

### Implemented status subset

| Stable status ID | Authored values | Behavior |
| --- | --- | --- |
| `bleed` | 4.0s base duration, 3 base maximum stacks, 1.0s tick, 2 damage per stack per tick | Reapplication adds stacks up to the derived maximum and refreshes duration; red actor marker/count; clears on actor/run cleanup |
| `shock` | 3.0s base duration, 1 maximum stack, no damage tick | Reapplication refreshes duration; cyan actor marker; Hacker Deck/Tech 2 extend the applied duration; clears on actor/run cleanup |
| `wet` | 4.0s base duration, 1 maximum stack, no damage tick | Applied to surviving Hydrant targets; mechanics-neutral future-compatibility state; changes no damage, Heat, Pressure, reward, or stream; clears on actor/run cleanup |

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

- The true presentation viewport is 1280 × 720. A camera at logical center `(320, 180)` with 2× zoom preserves the established 640 × 360 world framing. At M4.1 acceptance, 16:9, integer scaling, nearest filtering, an explicit default mipmap-filter setting, and pixel snapping were configured; the owner later removed the explicit aspect and mipmap-filter override lines while retaining the viewport, stretch mode, integer scale, nearest canvas filtering, and pixel snapping.
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

Historical out-of-scope itemization notes considered sell/salvage, auto-salvage, rarity, uniques, affixes, sets, a larger character sheet, category slots, item-instance rolls, and broader economy values. None are planned or authorized: Milestone 6 is the stopping boundary, and the implemented non-destructive drag/snap-back plus click/tap/keyboard confirmation contracts remain final-scope requirements.

### District cards

Milestone 5 implements exactly four validated `DistrictCardDefinition` Resources and four typed `CardEffectDefinition` payloads. The authored deck contains one copy of each card. Every cost is `0` and is displayed as `FREE`; no card currency, shop, or broader economy exists.

| Stable ID / name | Heat | Valid future node | Tags | Stable effect ID / typed effect and progression contract |
| --- | ---: | --- | --- | --- |
| `arcade` / Arcade | `+10` | `travel` | `FIGHT`, `REWARD` | `arcade_standard_encounter_reward_boost` / `ADD_STANDARD_ENCOUNTER`: replace the reached travel occurrence with one non-recursive standard encounter; advance its resulting standard reward by exactly one eligible authored quality tier, skipping absent tiers and clamping to the existing catalogue maximum. This is not a general upgrade system. |
| `convenience_store` / Convenience Store | `-10` | `travel` | `SHOP`, `RECOVERY` | `convenience_store_existing_stock_purchase` / `OPEN_ONE_PURCHASE_SHOP`: replace the reached travel occurrence with a shop/recovery visit allowing at most one purchase from the run's existing finite cooling stock. It cannot replenish stock or create a broader economy. |
| `gang_hideout` / Gang Hideout | `+20` | `encounter` | `ELITE`, `EQUIPMENT` | `gang_hideout_viper_signal_elite` / `ADD_ELITE_ENCOUNTER`: replace the reached baseline encounter with scaled `viper_signal`, which guarantees one Viper Enforcer plus budgeted basic enemies, and guarantee an equipment choice. It grants no recursive card reward. |
| `subway_entrance` / Subway Entrance | `-15` | `encounter` | `REROUTE`, `SKIP` | `subway_entrance_reroute_skip` / `REROUTE_SKIP_STANDARD`: reroute the reached future segment and skip exactly that one baseline standard encounter. It consumes/replenishes no Subway intervention charge, reduces no Night Pressure, and cannot skip extraction progression, clear a queued boss, or bypass boss precedence. |

The finite state contract is an opening draw of two, hand capacity three, a draw pile containing the two cards not opened, immediate hand-to-discard movement on confirmed placement, and no discard reshuffle during Milestone 5. A successful reward acquisition moves exactly one selected card from draw pile to hand; choices not selected remain in the draw pile. Clean restart reconstructs the one-copy deck and clears hand, discard, pending/resolved effects, placement/acquisition tokens, route modifications, modal/planning state, and cards-stream state before the deterministic opening draw.

Opening draws and reward choices first reject invalid/duplicate content, then sort by stable card ID and draw only from the run-scoped `cards` stream. A supplemental opportunity follows the existing core reward contract for each eligible baseline non-elite standard encounter while valid cards remain. It offers up to three remaining cards; **Skip / Keep Hand** is available, including at the three-card hand cap. Card-created encounters, elite encounters, shops, reroutes, and card effects never generate recursive card rewards. The feature consumes no `encounters`, `spawns`, `rewards`, `equipment`, `enemy_variants`, or `cosmetic` draw for card selection; schema version 1 is unchanged. Reproduction remains bounded to an identical supported build, content revision, schema version, seed, gameplay decisions, and authoritative timing.

`PatrolController` exposes exactly five current-window future route slots identified as `<route-id>::route_slot::<occurrence-index>`, paired with stable `<route-id>::occurrence::<occurrence-index>` identities. Each snapshot carries the future route index, loop, node ID/type, status, occupied card/effect, token, and route revision. One card may occupy an occurrence. Wrong-node, current, past, expired, occupied, out-of-window, stale-revision, duplicate-token, invalid, and outside placements reject without authoritative mutation.

The player stages a card/slot pair with expected hand and route revisions, then confirms its token. Only confirmation moves the card to discard, registers the pending route effect, and makes `RunFlowController` ask `RunDirector` to apply the card's Heat delta exactly once. On reaching that authored future occurrence, `CardSystem` and `PatrolController` consume the pending record exactly once before baseline node dispatch; the card effect replaces that occurrence's baseline behavior and moves into resolved route history. No card directly changes Night Pressure or its extraction/boss latches.

Planning opens only during safe `PATROLLING`, `SHOP`, or `EXTRACTION_AVAILABLE` states outside active combat. Patrol planning owns a pause, so eligible time and Night Pressure do not advance. An unsafe progression transition ends planning and clears its staged token synchronously; stale confirmation then rejects before Heat or route mutation. The 1280 x 720 HUD shows hand/draw/discard counts, all required card detail, five target slots and explicit statuses, valid-target highlights, staged confirmation, invalid/outside return feedback, and pending/resolved route/minimap changes. Typed native drag/drop includes an 8-pixel mouse/touch fallback and first-pointer ownership; right-click cancels an active drag. Click, tap, focus, keyboard activation, and explicit target buttons provide the full alternative path.

Milestone 5 passed **188/188 cumulative tests and 2,450 assertions with no failures or skips across 15 suites**: the preserved 145-test/1,709-assertion baseline plus 43 M5 tests/741 assertions. Configured `/GameRun`, fresh Windows/Web exports, Windows runtime smoke, real Web pointer/click/rejection flows, clean Web restart, 1280 × 720 containment, and an empty Web warning/error console passed. Evidence: `res://docs/screenshots/milestone_5_district_cards.png`. It was subsequently merged through PR #4 and published from `main` commit `da934897cbdee44cb4d1a44b25e91b458558bfbc`.

### Implemented optional coin clusters

Coin clusters are the implemented vertical-slice ambient interaction under `LootContainer`.

- Each coin-rewarding defeated enemy creates one cluster; explicitly rewardless enemies create none.
- Authored enemy base values are Street Punk 40, Bottle Thrower 50, Bat Thug 60, and Viper Enforcer 120; crew, Backup Runner, and The Viper are rewardless. Milestone 3 standard reward selection separately uses `rewards`.
- Ignored clusters auto-collect after approximately 2.5 seconds for the full base value.
- A successful manual collection is immediate and may advance an approximately 3-second streak.
- Manual streak bonus tuning is data-driven and capped at 10% of that cluster's base value; auto-collection receives no manual bonus.
- Click and timeout are mutually exclusive resolutions of one authoritative award, so the base value is credited at most once.
- `RewardDirector`, not the cluster presentation or combat actor, owns the coin ledger, resolution state, and streak.
- Victory, extraction, or defeat settles every unresolved visible cluster as full base value in stable deadline/ID order before freezing the summary; settlement grants no manual bonus or streak.
- The presentation uses a 32px mouse/touch shape, pointer cursor, pulse, hover response, and persistent `CLICK / TAP` affordance.
- Combat Lab placement enforces a 76px center exclusion around the Hydrant so the two generous interaction areas do not overlap.

### Escalation and finite cooling

| Value | Authority | Implemented behavior |
| --- | --- | --- |
| Heat | `RunDirector` | Tactical district alert clamped to 0–100; exact tiers change immediate danger/reward conditions and receive finite cooling |
| Night Pressure | `RunDirector` | Non-negative and irreversible during a run; eligible time and exactly-once completions advance scaling, extraction latches, and unavoidable boss queueing |

Night Pressure thresholds latch when crossed. A boss reached at an unsafe transition is queued until the next valid boundary, and the boss takes precedence when it and an extraction threshold are reached by the same authoritative update unless extraction was already confirmed. Cooling cannot reduce Night Pressure, reopen a spent extraction threshold, or clear a queued boss.

Configured Milestone 6 pressure gain is 0.07 per eligible active second, +1.5 for each exactly-once standard completion, and +3.0 for each exactly-once elite-flagged completion. Pauses, reward/card/shop modals, introductions, extraction/victory presentation, and summaries are ineligible. Scaling and threshold values remain the typed values listed in the run-definition table.

Shop cooling costs 60 coins and has two purchases per run. Subway Reroute starts with two charges and does not regenerate merely through elapsed time. Both reduce Heat only; zero-stock requests reject without mutation.

### Run-scoped deterministic streams

`RunDirector` owns one authoritative integer seed and a non-Autoload `RunRandomStreams` child with seven streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Schema 1 derives sub-seeds with `fnv1a32_utf8_v1` from canonical UTF-8 text. Gameplay candidates are deterministically filtered, duplicate/empty stable IDs are excluded, and remaining IDs are sorted before selection. The `cosmetic` stream is isolated so presentation draws cannot alter gameplay outcomes.

Milestone 6 preserves stream ownership: encounter definition selection uses `encounters`; mixed enemy budget selection uses `enemy_variants` to build the ordered actor-ID queue at encounter start; stable lane selection uses `spawns` when each staged actor is released; standard rewards use `rewards`; equipment choices and procs use `equipment`; card opening/reward choices use `cards`. The 3.0-second entry and 12.0-second interval timers consume no random draw. Boss attack cycles/summons, projectiles, backup, combo, cadence, audio, tutorials, settings, saves, unlocks, and summaries consume no gameplay draw. Screen shake is mathematical presentation and does not consume `cosmetic`.

Before the first draw, `RunContentAccessSnapshot` captures selected crew, sorted allowed equipment/card IDs, save version, and development-access flag. Same-seed restart reuses it. Reproduction is limited to the same supported build/content revision, schema 1, access snapshot, seed, gameplay decisions/effect resolutions, and authoritative timing; cross-version or bitwise physics replay is not promised.

## Milestone 6 cadence, summary, and scope record

The measurement-only `milestone_6_cadence` bands are ambient 10–20, strategic 30–60, and major 120–180 eligible active seconds. Composed instrumentation records coin-cluster presentation as ambient; ordinary encounter rewards and accepted shop visits as strategic; extraction windows and boss commitment as major. The non-boss 3.0-second entry beat and 12.0-second staged-actor interval are the authored pacing source intended to space potential coin-cluster opportunities; observed gaps still depend on roster choices and combat duration. The tracker explicitly rejects coin-labelled strategic events and never manufactures opportunities. A fixed-seed Rex/starter-only technical probe reached Defeated naturally at 589.517 eligible seconds and recorded ambient 47 events/12.446-second average/9 violations, strategic 13/44.999/8, and major 3/194.994/3. Per-gap cadence conformance, representative Victory/Extraction, and owner-facing qualitative validation remain next-session TODOs.

Recorded event IDs are `coin_cluster_presented:<cluster-id>`, `encounter_reward:<encounter-id>`, `shop:<source-id>:<monotonic-id>`, `extraction:<threshold-index>`, and `boss_commitment`. Each category retains at most 128 records and classifies each gap as `too_soon`, `within_target`, or `too_late`; this diagnostic classification never changes gameplay.

The complete `RunSummaryRecord` includes result (`VICTORY`, `EXTRACTED`, or `DEFEATED`), duration, seed, schema, maximum Heat, final Night Pressure, encounters, enemies/elites defeated, boss result (`DEFEATED`, `CREW DEFEATED`, or `NOT REACHED`), coins, manual clusters, maximum streak, scrap, highest combo, equipment build, active synergies, Restart Run, and Return to Main Menu. Unresolved clusters settle at base value before publication. Completed-run persistence happens only after this snapshot and cannot change it.

No post-Milestone-6 content is catalogued or authorized: no procedural route generation, additional district/card/crew/enemy/boss/equipment content, multiplayer, controller support, localization, achievements, daily systems/leaderboards, advanced meta-progression/permanent stat tree, mid-run saving/replay, card economy, or equipment selling/salvage/rarity/uniques/affixes/sets.

Godot 4.7 passed **244/244 cumulative tests and 3,234 assertions with no failures or skips across 22 suites**, and the configured headless `/GameRun` boot was clean. The cumulative harness's 48 ObjectDB and four resource-in-use shutdown diagnostics remain a next-session harness-cleanup audit. This content record does not claim clean exported logs, accepted 1080p/1440p layout, visual evidence, Victory/Extraction duration, cadence conformance, boss readability/defeatability, three-build viability, distinct crew feel, tutorial comprehension, or any new owner qualitative result until those deferred TODOs are actually completed.
