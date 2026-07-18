# Neon Loop Content Catalog

## Catalog status

This catalog reflects the implemented **Milestone 0 — Project Foundation**, **Milestone 1 — Combat Lab**, and **Milestone 2 — Player Intervention**. Entries explicitly marked as placeholders still reserve later ownership or screen space; listing deferred vertical-slice content does not authorize it.

## Implemented foundation content

### Stage

| ID / name | Type | Current state |
| --- | --- | --- |
| Downtown Loop | Fixed district stage | Placeholder nighttime street made from development shapes and labels |
| Back Lane | Debug lane guide / combat lane | Visible development marker at Y 194; used by Combat Lab movement |
| Middle Lane | Debug lane guide / combat lane | Visible development marker at Y 226; used by Combat Lab movement |
| Front Lane | Debug lane guide / combat lane | Visible development marker at Y 258; used by Combat Lab movement |
| Route nodes | Route placeholders | Visual markers only; no patrol or encounter resolution |
| Spawn points | Authored lab markers | Fixed Jax/enemy starting regions; no encounter scheduling |
| Interactables container | Stage container | Hosts the functional Fire Hydrant presentation/input scene; gameplay authority remains run-scoped |
| Crew container | Stage container | Hosts the runtime Jax actor |
| Enemy container | Stage container | Hosts five live Street Punks plus short death-cleanup presentation |
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

Combat Lab elapsed time, Jax health/state/target, coin total, manual streak, Fire Hydrant state/cooldown, fullscreen state, and player guidance are live presentation values. Their native-scale typography, meters, and framing are enlarged for common 16:9 displays; compact labels preserve the central fight area. Other displayed values and disabled buttons remain placeholders. No HUD region owns authoritative gameplay state.

The HUD presents the Milestone 1 manual coin streak plus Milestone 2 Hydrant, onboarding, sound, fullscreen, landscape, and safe-area state. Dedicated Night Pressure, run-seed, and random-stream readouts remain deferred with their future gameplay owners.

### Development tools

| Tool | Control | Current state |
| --- | --- | --- |
| DebugOverlay | `F1` | Toggleable development information shell |
| Lane guides | DebugOverlay button or `F2` | Requests that Downtown Loop show or hide all three lane visuals |

### Runtime ownership state

| Class | Current content |
| --- | --- |
| `RunDirector` | Typed responsibility description only |
| `PatrolController` | Typed responsibility description only |
| `CombatDirector` | Actor registration, targeting, reservations, hit resolution, hit-stop, cleanup, safe-space assignment, and typed environmental-hit authority |
| `RewardDirector` | Milestone 1 coin ledger, at-most-once cluster resolution, and manual streak authority |
| `CombatLabController` | Fixed five-enemy authored demo orchestration and repeat spawning |
| `FireHydrantController` | Milestone 2 circle validation, deterministic area resolution, rejection, and cooldown authority |
| `DisplayController` | Presentation-only fullscreen, landscape, and safe-area integration |
| `CardSystem` | Typed responsibility description only |
| `SynergySystem` | Typed responsibility description only |

## Assets

Milestones 1 and 2 use project-native code-drawn placeholder actors, health/target indicators, hit/death/spawn/water effects, damage numbers, Hydrant and coin presentation, and deterministic generated PCM cues. These are deliberately replaceable evaluation assets, not production sprites or audio. No production character sprites, enemy sprites, equipment icons, card art, or music are cataloged as implemented.

The existing project icon and Godot MCP addon files are project/development support, not Neon Loop gameplay content.

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

The visual-direction reference is stored at `res://docs/reference/neon_loop_gameplay_mockup.png`; it is inspiration only and does not authorize the later systems depicted in it. Milestone 1 evidence is stored at `res://docs/screenshots/milestone_1_combat_lab.png`. Milestone 2 evidence is stored at `res://docs/screenshots/milestone_2_player_intervention.png`.

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

## Remaining specified content and contracts

The following names and contracts come from `GameSpecifications.md`. Named crew/enemies and later systems remain deferred unless a subsection explicitly identifies implemented Milestone 1 or Milestone 2 behavior.

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
- Subway Reroute — finite charge or explicit consumable; cannot reduce Night Pressure or bypass its thresholds

Wet application and combo continuation remain future compatibility contracts only. No general status-effect, Wet, combo-meter, or combo-reward system is implemented in Milestone 2.

### Equipment

The vertical-slice catalogue contains these nine definitions. None is implemented in Milestone 2.

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
- Milestone 1 uses fixed authored base values; randomized values remain deferred to the Milestone 3 `rewards` stream.
- Ignored clusters auto-collect after approximately 2.5 seconds for the full base value.
- A successful manual collection is immediate and may advance an approximately 3-second streak.
- Manual streak bonus tuning is data-driven and capped at 10% of that cluster's base value; auto-collection receives no manual bonus.
- Click and timeout are mutually exclusive resolutions of one authoritative award, so the base value is credited at most once.
- `RewardDirector`, not the cluster presentation or combat actor, owns the coin ledger, resolution state, and streak.
- The presentation uses a 32px mouse/touch shape, pointer cursor, pulse, hover response, and persistent `CLICK / TAP` affordance.
- Combat Lab placement enforces a 76px center exclusion around the Hydrant so the two generous interaction areas do not overlap.

### Escalation and finite cooling

| Value | Future authority | Specified behavior |
| --- | --- | --- |
| Heat | `RunDirector` | Tactical district alert clamped to 0–100; changes immediate danger/reward conditions and may receive finite cooling |
| Night Pressure | `RunDirector` | Non-negative and irreversible during a run; advances major scaling, extraction thresholds, and the unavoidable boss threshold |

Night Pressure thresholds latch when crossed. A boss reached at an unsafe transition is queued until the next valid boundary, and the boss takes precedence when it and an extraction threshold are reached by the same authoritative update unless extraction was already confirmed. Cooling cannot reduce Night Pressure, reopen a spent extraction threshold, or clear a queued boss.

Shop cooling requires meaningful cost plus finite stock or an explicit per-run purchase limit; price escalation alone is insufficient. Subway Reroute consumes a finite charge or consumable and does not regenerate merely through elapsed time. These values, thresholds, latches, shops, and charges are specified only and have no Milestone 2 runtime implementation.

### Run-scoped deterministic streams

`RunDirector` will own one authoritative integer seed and a non-Autoload `RunRandomStreams` child with seven streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Gameplay candidates must be deterministically filtered and sorted by stable content ID before selection. The `cosmetic` stream is isolated so presentation draws cannot alter gameplay outcomes. No seed, stream component, or random content selection is implemented in Milestone 2.

Listing deferred content does not authorize its implementation beyond Milestone 2.
