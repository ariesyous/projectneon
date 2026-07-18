# Neon Loop Content Catalog

## Catalog status

This catalog reflects the implemented **Milestone 0 — Project Foundation** and **Milestone 1 — Combat Lab**. Entries explicitly marked as placeholders still reserve later ownership or screen space; listing deferred vertical-slice content does not authorize it.

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
| Interactables container | Stage container | Contains a clearly labelled/drawn nonfunctional placeholder; no intervention behavior |
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

Combat Lab elapsed time, Jax health/state/target, coin total, and manual streak are live presentation values. Their native-scale typography, meters, and framing are enlarged for common 16:9 displays; compact labels preserve the central fight area. Other displayed values and disabled buttons remain placeholders. No HUD region owns authoritative gameplay state.

The HUD now presents the Milestone 1 manual coin streak. Dedicated Night Pressure, run-seed, and random-stream readouts remain deferred with their future gameplay owners.

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
| `CombatDirector` | Milestone 1 actor registration, targeting, reservations, hit resolution, hit-stop, and cleanup authority |
| `RewardDirector` | Milestone 1 coin ledger, at-most-once cluster resolution, and manual streak authority |
| `CombatLabController` | Fixed five-enemy authored demo orchestration and repeat spawning |
| `CardSystem` | Typed responsibility description only |
| `SynergySystem` | Typed responsibility description only |

## Assets

Milestone 1 uses project-native code-drawn placeholder actors, health/target indicators, hit/death/spawn effects, damage numbers, coin presentation, and deterministic generated PCM cues. These are deliberately replaceable evaluation assets, not production sprites or audio. No production character sprites, enemy sprites, equipment icons, card art, or music are cataloged as implemented.

The existing project icon and Godot MCP addon files are project/development support, not Neon Loop gameplay content.

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

The visual-direction reference is stored at `res://docs/reference/neon_loop_gameplay_mockup.png`; it is inspiration only and does not authorize the later systems depicted in it. Milestone 1 evidence is stored at `res://docs/screenshots/milestone_1_combat_lab.png`.

## Implemented Combat Lab content

| Content ID | Type | Authored Milestone 1 values |
| --- | --- | --- |
| `jax` | Crew actor | 520 health, 112 movement speed, 20 base damage, rewardless |
| `jax_basic_punch` | Basic attack | 0.20s windup, 0.08s active, 0.34s recovery, visible 155-force knockback, 0.075s hit-stop |
| `street_punk` | Enemy actor | 58 health, 86 movement speed, 2 base damage, fixed 40-coin reward |
| `street_punk_basic_punch` | Basic attack | 0.31s windup, 0.08s active, 0.42s recovery, visible 68-force knockback, 0.04s hit-stop |
| Milestone 1 coin cluster | Ambient interaction | 2.5s auto-collect, 3.0s manual streak window, basis-point bonus schedule capped at 10% |

## Remaining specified content and contracts

The following names and contracts come from `GameSpecifications.md`. Named crew/enemies and later systems remain deferred unless a subsection explicitly identifies implemented Milestone 1 behavior.

### Crew

- Zoey — Tech Fighter
- Rex — Bruiser

### Enemies

- Bat Thug
- Bottle Thrower
- Viper Enforcer (elite)
- The Viper (boss)

### Interventions

- Fire Hydrant
- Call Backup
- Subway Reroute — finite charge or explicit consumable; cannot reduce Night Pressure or bypass its thresholds

### Equipment

The vertical-slice catalogue contains these nine definitions. None is implemented in Milestone 1.

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

Coin clusters are the implemented Milestone 1 ambient interaction under `LootContainer`.

- Each coin-rewarding defeated enemy creates one cluster; explicitly rewardless enemies create none.
- Milestone 1 uses fixed authored base values; randomized values remain deferred to the Milestone 3 `rewards` stream.
- Ignored clusters auto-collect after approximately 2.5 seconds for the full base value.
- A successful manual collection is immediate and may advance an approximately 3-second streak.
- Manual streak bonus tuning is data-driven and capped at 10% of that cluster's base value; auto-collection receives no manual bonus.
- Click and timeout are mutually exclusive resolutions of one authoritative award, so the base value is credited at most once.
- `RewardDirector`, not the cluster presentation or combat actor, owns the coin ledger, resolution state, and streak.

### Escalation and finite cooling

| Value | Future authority | Specified behavior |
| --- | --- | --- |
| Heat | `RunDirector` | Tactical district alert clamped to 0–100; changes immediate danger/reward conditions and may receive finite cooling |
| Night Pressure | `RunDirector` | Non-negative and irreversible during a run; advances major scaling, extraction thresholds, and the unavoidable boss threshold |

Night Pressure thresholds latch when crossed. A boss reached at an unsafe transition is queued until the next valid boundary, and the boss takes precedence when it and an extraction threshold are reached by the same authoritative update unless extraction was already confirmed. Cooling cannot reduce Night Pressure, reopen a spent extraction threshold, or clear a queued boss.

Shop cooling requires meaningful cost plus finite stock or an explicit per-run purchase limit; price escalation alone is insufficient. Subway Reroute consumes a finite charge or consumable and does not regenerate merely through elapsed time. These values, thresholds, latches, shops, and charges are specified only and have no Milestone 1 runtime implementation.

### Run-scoped deterministic streams

`RunDirector` will own one authoritative integer seed and a non-Autoload `RunRandomStreams` child with seven streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Gameplay candidates must be deterministically filtered and sorted by stable content ID before selection. The `cosmetic` stream is isolated so presentation draws cannot alter gameplay outcomes. No seed, stream component, or random content selection is implemented in Milestone 1.

Listing deferred content does not authorize its implementation beyond Milestone 1.
