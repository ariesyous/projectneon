# Neon Loop Content Catalog

## Catalog status

This catalog reflects **Milestone 0 — Project Foundation**. Entries marked as placeholders reserve ownership or screen space; they are not functional gameplay content. Revised vertical-slice entries are cataloged below as specified-but-not-implemented contracts and do not expand the current milestone.

## Implemented foundation content

### Stage

| ID / name | Type | Milestone 0 state |
| --- | --- | --- |
| Downtown Loop | Fixed district stage | Placeholder nighttime street made from development shapes and labels |
| Back Lane | Debug lane guide | Visible development marker; no navigation behavior |
| Middle Lane | Debug lane guide | Visible development marker; no navigation behavior |
| Front Lane | Debug lane guide | Visible development marker; no navigation behavior |
| Route nodes | Route placeholders | Visual markers only; no patrol or encounter resolution |
| Spawn points | Spawn placeholders | Marker nodes only; no spawned content or behavior |
| Interactables container | Stage container | Contains a clearly labelled/drawn nonfunctional placeholder; no intervention behavior |
| Crew container | Stage container | Contains a clearly labelled/drawn nonfunctional placeholder; no crew actor behavior |
| Enemy container | Stage container | Contains a clearly labelled/drawn nonfunctional placeholder; no enemy behavior |
| Effects container | Stage container | Contains a clearly temporary drawn placeholder; no combat effect behavior |
| Loot container | Stage container | Empty; no rewards or pickups |

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

All displayed values and buttons are placeholders. No HUD region owns authoritative gameplay state.

The Milestone 0 HUD does not yet claim dedicated Night Pressure, run-seed, random-stream, or coin-streak presentation. Those revised-specification readouts remain deferred with their gameplay owners.

### Development tools

| Tool | Control | Milestone 0 state |
| --- | --- | --- |
| DebugOverlay | `F1` | Toggleable development information shell |
| Lane guides | DebugOverlay button or `F2` | Requests that Downtown Loop show or hide all three lane visuals |

### Runtime ownership placeholders

| Class | Milestone 0 content |
| --- | --- |
| `RunDirector` | Typed responsibility description only |
| `PatrolController` | Typed responsibility description only |
| `CombatDirector` | Typed responsibility description only |
| `RewardDirector` | Typed responsibility description only |
| `CardSystem` | Typed responsibility description only |
| `SynergySystem` | Typed responsibility description only |

## Assets

Milestone 0 uses project-native placeholder shapes, labels, and any compatible existing project assets. No production character sprites, enemy sprites, equipment icons, card art, effects, music, or gameplay audio are cataloged as implemented.

The existing project icon and Godot MCP addon files are project/development support, not Neon Loop gameplay content.

Milestone 0 visual evidence is stored at `res://docs/screenshots/milestone_0_foundation.png`.

## Specified but not implemented

The following names come from `GameSpecifications.md` and remain deferred:

### Crew

- Jax — Brawler (Milestone 1 combat proof)
- Zoey — Tech Fighter
- Rex — Bruiser

### Enemies

- Street Punk
- Bat Thug
- Bottle Thrower
- Viper Enforcer (elite)
- The Viper (boss)

### Interventions

- Fire Hydrant
- Call Backup
- Subway Reroute — finite charge or explicit consumable; cannot reduce Night Pressure or bypass its thresholds

### Equipment

The vertical-slice catalogue contains these nine definitions. None is implemented in Milestone 0.

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

### Optional coin clusters

Coin clusters are a Milestone 1 ambient interaction and are not present in the empty Milestone 0 `LootContainer`.

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

Shop cooling requires meaningful cost plus finite stock or an explicit per-run purchase limit; price escalation alone is insufficient. Subway Reroute consumes a finite charge or consumable and does not regenerate merely through elapsed time. These values, thresholds, latches, shops, and charges are specified only and have no Milestone 0 runtime implementation.

### Run-scoped deterministic streams

`RunDirector` will own one authoritative integer seed and a non-Autoload `RunRandomStreams` child with seven streams: `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Gameplay candidates must be deterministically filtered and sorted by stable content ID before selection. The `cosmetic` stream is isolated so presentation draws cannot alter gameplay outcomes. No seed, stream component, or random content selection is implemented in Milestone 0.

Listing deferred content does not authorize its implementation during Milestone 0.
