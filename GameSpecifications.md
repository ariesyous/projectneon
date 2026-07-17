# Neon Loop — Game Specifications

**Document status:** Initial vertical-slice specification  
**Working title:** Neon Loop  
**Engine:** Godot 4.x  
**Primary language:** Typed GDScript  
**Target platform:** Windows PC  
**Target display:** 16:9 desktop display  
**Internal design resolution:** 640 × 360  
**Current production goal:** A complete, replayable vertical slice proving the core game loop

---

## 1. Document Purpose

This document is the source of truth for the initial implementation of **Neon Loop**.

It is written for both human developers and coding agents. It defines:

- What the game is
- What the player does
- Which systems must exist
- How those systems interact
- What is intentionally out of scope
- How the Godot project should be structured
- How each milestone is verified

The first implementation must prioritize a small, polished, playable vertical slice. It must not attempt to build the full imagined game immediately.

When a requirement is ambiguous, prefer the interpretation that:

1. Preserves the core player fantasy
2. Produces a playable result sooner
3. Keeps systems modular and data-driven
4. Avoids unnecessary global state
5. Is easy to inspect and debug in Godot

---

## 2. Product Vision

**Neon Loop** is a side-view, 16-bit-inspired, auto-battling action roguelite.

The player assembles and improves a small crew that patrols a dangerous city district. Crew members move and fight automatically. The player does not directly control their attacks.

Instead, the player:

- Shapes the route
- Selects upgrades
- Equips synergistic items
- Places district cards
- Triggers limited interventions
- Manually collects optional coin clusters for a small streak bonus
- Decides whether to continue or extract

The game should feel like operating a dangerous little combat machine.

The player should frequently think:

> “I built this system, and now I want to see how far it can go.”

---

## 3. Core Player Fantasy

The player is the **director of the district run**, not a conventional beat-'em-up character.

The crew handles ordinary movement and combat. The player shapes the circumstances around them.

The experience should combine:

- The visual spectacle of a 16-bit side-scrolling brawler
- The indirect control of an auto-battler
- The escalating build construction of a roguelite
- The strategic route shaping of a card-driven game
- The tension of deciding when to extract
- The pleasure of watching a system become increasingly powerful

The final fantasy is a busy neon street where:

- Crew members automatically fight gangs
- Enemies are knocked into walls and objects
- Clickable coin clusters and equipment burst from defeated enemies
- The player clicks environmental objects at decisive moments
- Build synergies visibly alter combat
- Heat changes the immediate district alert while irreversible Night Pressure steadily escalates the run
- The player chooses whether to push deeper or escape safely

---

## 4. Design Pillars

### 4.1 Build It, Then Watch It Work

The player’s choices should visibly alter what happens during combat.

Equipment, synergies, route cards, and interventions must produce observable changes rather than invisible statistical improvements only.

### 4.2 Frequent Interaction at Multiple Scales

The game may contain automatic action, but the player should not feel passive.

During an active run, interaction should occur at three distinct cadences:

- **Ambient optional interactions:** approximately every 10–20 seconds
- **Meaningful strategic decisions:** approximately every 30–60 seconds
- **Major risk decisions:** approximately every 2–3 minutes

Ambient interactions must be quick, optional, and safe to ignore. Coin clusters are the initial example. Strategic and risk decisions may pause or redirect the run and must not be diluted into constant clicking.

Examples:

- Choose one of three upgrades
- Trigger an environmental intervention
- Place a district card
- Equip or replace an item
- Continue or extract
- Accept or avoid an elite encounter

### 4.3 Satisfying Combat Spectacle

Automatic combat must be enjoyable to watch.

Combat should emphasize:

- Clear anticipation
- Strong hit reactions
- Brief hit-stop
- Knockback
- Flashing impact effects
- Damage numbers
- Coin bursts
- Environmental collisions
- Readable attack timing
- Distinct sound effects

### 4.4 Escalation and Risk

Each run should become busier, more dangerous, and more rewarding over time.

Heat communicates immediate tactical danger and may be manipulated. Night Pressure communicates irreversible run escalation. The player should understand that remaining in the district is profitable but always becomes riskier even when Heat is reduced.

### 4.5 Readable Systems

The player should be able to understand why something happened.

Tooltips, icons, status indicators, and debug tools must expose:

- Current Heat
- Current Night Pressure and progress toward the next major threshold
- Current run seed in development tools and the run summary
- Current synergies
- Equipment effects
- Active status effects
- Encounter difficulty
- Intervention cooldowns
- Extraction reward multiplier
- Coin collection streak and its capped bonus when active

### 4.6 Small Number of Strong Interactions

The vertical slice should use a limited set of systems with strong interactions.

Do not compensate for weak mechanics by generating large quantities of content.

---

## 5. Non-Goals for the Vertical Slice

The first vertical slice must not include:

- Multiple city districts
- Procedural city generation
- Online multiplayer
- Player-versus-player combat
- A large narrative campaign
- Dialogue trees
- Complex faction reputation
- More than one boss
- More than three crew members
- More than six standard enemy definitions
- More than twelve equipment items
- More than eight district cards
- A large permanent skill tree
- Steam achievements
- Mod support
- Workshop integration
- Mobile controls
- Console support
- Full localization
- Monetization systems
- Daily rewards
- Energy systems
- Real-money purchases
- Login streaks
- Notifications intended to pressure return play

These may be reconsidered after the vertical slice proves the core loop.

---

## 6. Vertical-Slice Objective

The vertical slice must prove the following question:

> Is it fun to shape an auto-brawl, watch it unfold, and intervene at important moments?

The vertical slice should support a complete run lasting approximately **8–12 minutes**.

A complete run can end in one of three ways:

1. **Victory:** defeat the district boss
2. **Extraction:** leave voluntarily with secured rewards
3. **Defeat:** all crew members are incapacitated

The vertical slice must contain:

- One fixed nighttime street
- One patrol loop
- One starting crew member
- Up to three active crew members
- Two basic enemy types
- One ranged enemy type
- One elite enemy
- One boss
- Three interventions
- At least nine equipment items
- Three synergy categories
- Four district cards
- One shop interaction
- One complete run summary
- One optional ambient interaction loop based on coin clusters
- Separate tactical Heat and irreversible Night Pressure escalation
- One authoritative run seed with isolated deterministic named random streams
- Placeholder or prototype-quality art and audio where final assets are unavailable

---

## 7. Target Experience

### 7.1 Session Length

- Typical run: 8–12 minutes
- Short extraction: 3–6 minutes
- Boss victory: approximately 10 minutes
- Restart time after defeat: less than 10 seconds

### 7.2 Interaction Density

The player should have:

- Continuous visual action
- One ambient optional interaction approximately every 10–20 seconds
- One meaningful strategic decision approximately every 30–60 seconds
- One major risk decision approximately every 2–3 minutes

These categories are not interchangeable. Ambient interactions support engagement without carrying the consequence or interruption of a strategic choice.

Cadence is measured during eligible active play. Time spent paused, in modal reward or shop choices, or in non-interactive introductions does not count toward the 10–20 second ambient target.

### 7.3 Ambient Interaction: Coin Clusters

Coin clusters are the first ambient optional interaction system.

- Each coin-rewarding defeated enemy's award is represented by one clickable cluster rather than individual precision targets. Explicitly rewardless enemies do not create a cluster.
- A cluster automatically collects after approximately 2.5 seconds.
- Clicking a cluster collects it immediately.
- Ignoring a cluster never loses the base coin reward.
- Click and auto-collection are mutually exclusive resolutions: the base award is credited exactly once even if input and timeout occur together.
- Only successful manual collections advance the collection streak. Auto-collected clusters grant no manual bonus and do not advance it.
- Consecutive successful manual collections within approximately 3 seconds of the previous manual collection build a streak; otherwise the streak resets before the new manual collection is counted.
- The streak grants a small coin bonus capped at 10% of that cluster's base value.
- Timing windows and bonus values must be data-driven prototype tuning, not hard-coded balance commitments.
- Manual collection should feel beneficial but never mandatory.
- Collection must not interrupt combat or require excessive pointer precision.
- A mostly passive player must not be heavily penalized.

Future ambient interactions may include breakable containers, civilian events, temporary opportunities, and environmental objects. They must follow the same principle: optional attention may provide a modest benefit, while ignoring them does not undermine the core auto-battler experience.

### 7.4 Desired Emotional Arc

**Start:** Quiet, understandable, controlled  
**Middle:** Busy, increasingly powerful, increasingly risky  
**Late run:** Chaotic, spectacular, dangerous  
**End:** Relief, satisfaction, or regret

---

## 8. Core Gameplay Loop

1. Start a run at the crew hideout with an authoritative integer seed, optionally supplied by the player or development tools.
2. Select one starting crew member.
3. Enter the district with one basic equipment item.
4. Crew automatically follows the patrol route.
5. Enemies spawn as scheduled encounters.
6. Crew automatically targets and fights enemies.
7. Defeated enemies drop coin clusters that may be clicked immediately or auto-collected for their full base value.
8. Heat changes with tactical actions while Night Pressure irreversibly rises through elapsed time and completed encounters.
9. At reward moments, the player chooses upgrades or cards.
10. The player may activate interventions during combat.
11. The player may add crew members and equipment during the run.
12. At extraction windows, the player may leave with secured rewards.
13. If the player continues, Night Pressure, enemy strength, and rewards increase regardless of later Heat reduction.
14. At the configured Night Pressure progression threshold, the boss encounter becomes unavoidable.
15. The run ends in victory, extraction, or defeat.
16. A run summary displays the result, run seed, escalation reached, and earned unlock currency.
17. The player may immediately begin another run.

---

## 9. Input Model

The vertical slice is designed primarily for mouse and keyboard.

### Mouse

- Left click: select buttons, cards, upgrades, environmental objects, and coin clusters
- Left click and drag: drag district cards to valid route slots
- Right click: cancel current card drag or close a tooltip
- Mouse wheel: optional UI scrolling where needed
- Hover: display tooltips and highlight interactable objects

### Keyboard

- `Space`: pause or resume the run
- `1`, `2`, `3`: activate equipped interventions
- `E`: open or confirm extraction prompt when available
- `Tab`: toggle expanded run details
- `Escape`: pause menu
- `F1`: toggle debug overlay in development builds

Direct fighter movement and direct attack controls are intentionally excluded.

---

## 10. Main Game Screen

The primary screen must use a single large side-view street canvas framed by compact UI panels.

### Required Layout

**Top-left**

- District minimap
- Patrol route
- Current crew location
- Encounter icons
- Extraction point

**Top-centre**

- Heat meter
- Current Heat percentage
- Current Heat tier
- Current Night Pressure
- Progress toward the next extraction or boss threshold
- Run timer
- Current night label

**Top-right**

- Coins
- Current coin collection streak when active
- Scrap
- Intervention charges
- Compact crew status portraits

**Left side**

- Expanded crew panel
- Portraits
- Health
- Equipment slots
- Current statuses
- Auto-battle indicator

**Centre**

- Main street
- Crew
- Enemies
- Environmental objects
- Combat effects
- Loot
- Clickable coin clusters
- Damage numbers

**Right side**

- Equipment and synergy summary
- Active synergy thresholds
- Progress toward alternative synergy paths
- Short effect descriptions

**Bottom-centre**

- District card hand
- Card costs
- Valid placement slots
- Route progression indicator

**Bottom-right**

- Intervention buttons
- Extraction button
- Extraction reward multiplier

The street canvas must remain the visual focus. UI panels should not cover critical combat space.

---

## 11. World and Stage Structure

The vertical slice uses one fixed district stage called **Downtown Loop**.

### Stage Visual Elements

- Arcade
- Convenience store
- Gang hideout
- Subway entrance
- Alley
- Neon signs
- Fire hydrant
- Dumpster
- Payphone or electrical box
- Street barriers
- Wet pavement reflections
- Background NPC silhouettes

### Play Space

The main combat area is a side-view street approximately two screens wide in world coordinates.

The camera may remain fixed for the first prototype. If horizontal scrolling is later added, the combat logic must remain independent of camera position.

### Patrol Route

The crew follows a predefined loop with route nodes.

Each route node may contain:

- Empty travel
- Standard encounter
- Elite encounter
- Shop
- Healing point
- Extraction point
- Boss trigger
- Card-modified effect

The route is visually represented on the minimap.

---

## 12. Lane-Based Movement

The battlefield uses three invisible depth lanes:

- Back lane
- Middle lane
- Front lane

Actors may:

- Move horizontally within a lane
- Change lanes to reach a target
- Reserve a nearby attack position
- Be knocked into another lane by specific effects
- Temporarily ignore lanes during scripted boss movement

The lane system exists to simplify:

- Targeting
- Navigation
- Sprite sorting
- Crowd control
- Attack range checks
- Collision readability

### Lane Rules

- Actors may not occupy exactly the same attack position.
- Multiple actors may surround a target using reserved attack slots.
- Lane changes should take approximately 0.2–0.5 seconds.
- Actors should avoid rapid lane switching.
- Lane selection should prefer the nearest valid target and nearest open attack position.

---

## 13. Crew System

### 13.1 Crew Size

- Starting crew size: 1
- Maximum active crew size: 3

### 13.2 Initial Crew Archetypes

#### Jax — Brawler

- High knockback
- Medium health
- Short-range attacks
- Benefits strongly from environmental collision effects

#### Zoey — Tech Fighter

- Fast attacks
- Lower health
- Reduces intervention cooldowns
- Applies Shock through equipment synergies

#### Rex — Bruiser

- High health
- Slow attacks
- Strong stagger resistance
- Excels against elites and the boss

Only Jax is required for Milestone 1. Zoey and Rex are introduced later.

### 13.3 Crew Runtime Properties

Each crew actor must track:

- Definition ID
- Display name
- Current health
- Maximum health
- Current state
- Current target
- Lane
- Movement speed
- Attack cooldown
- Attack range
- Base damage
- Knockback strength
- Status effects
- Equipment
- Active synergy modifiers
- Temporary run modifiers
- Incapacitated state

### 13.4 Incapacitation

When a crew member reaches zero health:

- Enter the Incapacitated state
- Stop targeting and attacking
- Play a clear downed animation
- Remain visible
- Become revivable only if a future effect explicitly supports revival

The run ends when all active crew members are incapacitated.

---

## 14. Actor State Machine

Crew and enemies use an explicit state machine.

Required states:

- `IDLE`
- `PATROLLING`
- `ACQUIRING_TARGET`
- `APPROACHING_TARGET`
- `ATTACK_WINDUP`
- `ATTACK_ACTIVE`
- `ATTACK_RECOVERY`
- `STUNNED`
- `KNOCKED_BACK`
- `INCAPACITATED`
- `DEAD`

### State Requirements

- Only one state may be active at a time.
- State transitions must be visible in the debug overlay.
- Attack hitboxes must only be active during `ATTACK_ACTIVE`.
- An actor cannot acquire a target while dead or incapacitated.
- Knockback interrupts ordinary attacks unless the actor has explicit resistance.
- State transition logic must not depend on animation frame names alone.

---

## 15. Automatic Targeting

### Target Selection Rules

Crew actors:

1. Ignore dead, incapacitated, or invalid enemies.
2. Prefer enemies currently participating in the active encounter.
3. Prefer the nearest reachable enemy.
4. Prefer enemies already targeting the crew actor only when distances are similar.
5. Reacquire a target immediately when the current target becomes invalid.
6. Avoid repeatedly switching targets unless the existing target becomes invalid or unreachable.

Enemies follow equivalent rules against crew members.

### Attack Position Reservation

Each target exposes a limited set of nearby attack positions.

An approaching actor:

- Requests an open position
- Moves toward that position
- Releases the position when interrupted, dead, or retargeting
- Attacks only when within valid range

This prevents all actors from stacking on one point.

---

## 16. Combat System

### 16.1 Combat Priorities

Combat must feel responsive and readable before it becomes complex.

Required first:

- Clear attack anticipation
- Accurate hit timing
- Hit-stop
- Knockback
- Hit flash
- Damage numbers
- Death reaction
- Coin-cluster drop, manual collection, and full-value auto-collection feedback
- Strong sound feedback

### 16.2 Damage Resolution

A basic hit calculates:

```text
final_damage =
    base_attack_damage
    × attacker_damage_multiplier
    × ability_damage_multiplier
    × target_damage_taken_multiplier
```

The vertical slice does not require complex armour formulas.

Damage must never be negative.

### 16.3 Hit Result

A successful hit may produce:

- Damage
- Knockback
- Stagger
- Status application
- Environmental collision
- On-hit equipment trigger
- Combo increment
- Sound and visual feedback

### 16.4 Hit-Stop

Ordinary hit-stop:

- Light hit: 0.03–0.05 seconds
- Heavy hit: 0.06–0.10 seconds
- Boss hit: tune separately

Hit-stop must not pause UI animations, input buffering, or the pause menu.

### 16.5 Knockback

Knockback has:

- Horizontal force
- Optional lane displacement
- Duration
- Resistance multiplier
- Collision damage potential

An enemy knocked into a wall, hydrant blast zone, dumpster, or another enemy may receive bonus collision damage.

### 16.6 Combo Meter

The combo meter increases when crew attacks connect.

Rules:

- Combo expires after 2.5 seconds without a valid hit.
- Multiple crew members contribute to the same combo.
- Environmental hits may continue the combo.
- Combo milestones provide visual celebration only in the vertical slice.
- Future score or reward scaling is deferred.

### 16.7 Status Effects

Initial status effects:

#### Bleed

- Deals damage over time
- Stacks up to a defined maximum
- Refreshes duration when reapplied

#### Shock

- Briefly increases damage taken from interventions
- May chain to one nearby target when synergy is active

#### Stun

- Prevents movement and attacks
- Does not stack
- Bosses receive reduced duration

---

## 17. Enemy System

### 17.1 Basic Enemy Types

#### Street Punk

- Melee
- Low health
- Medium speed
- Basic punch attack

#### Bat Thug

- Melee
- Medium health
- Slow heavy attack
- High knockback

#### Bottle Thrower

- Ranged
- Low health
- Attempts to maintain distance
- Throws a slow, readable projectile

### 17.2 Elite Enemy

#### Viper Enforcer

- High health
- Armour against light stagger
- Heavy charge attack
- Increased reward value
- Distinct visual outline or palette

### 17.3 Boss

#### The Viper

The Viper is the vertical-slice boss.

Required behaviours:

- Basic melee combo
- Dash or charge
- Summon two basic enemies
- Area warning attack
- Enrage at 40% health

The boss must have:

- Dedicated health bar
- Clear telegraphs
- Immunity to permanent stun-lock
- Reduced knockback
- Distinct music transition
- Victory sequence

---

## 18. Encounter System

The `RunDirector` schedules encounters using encounter definitions and the run-scoped `encounters` random stream.

Each encounter definition contains:

- ID
- Display name
- Base spawn budget
- Allowed enemy types
- Spawn positions
- Maximum concurrent enemies
- Heat requirement
- Night Pressure requirement or progression band
- Reward table
- Completion condition
- Elite flag
- Boss flag

### Encounter Completion

A standard encounter is complete when:

- All required enemies are defeated
- No pending required spawns remain

After completion:

- Crew resumes patrol
- Night Pressure increases by a data-driven amount
- Rewards are generated through their named deterministic stream
- The next route node becomes active

---

## 19. Escalation Systems: Heat and Night Pressure

Heat and Night Pressure serve different purposes and must not be treated as aliases.

- **Heat** is tactical, partially player-manipulable district alert.
- **Night Pressure** is irreversible run progression.

Reducing Heat may make the next encounter safer, but it never reverses the overall escalation of the run.

### 19.1 Heat Range and Responsibility

- Minimum: 0
- Maximum: 100

Heat controls:

- Encounter composition
- Elite availability
- Immediate danger
- Reward quality
- District alert level

### 19.2 Heat Changes

Heat may increase through:

- Completing fights
- Playing dangerous district cards
- Triggering elite encounters
- Remaining after an extraction window
- Other explicitly defined encounter, shop, card, or limited intervention effects

Heat may decrease through:

- Convenience store or cooling cards
- Limited shop purchases
- Finite-use Subway Reroute charges
- Extraction

Shop-based Heat reduction must be constrained through cost, availability, or per-run purchase limits. Cooling effects provide tactical relief only and cannot reduce Night Pressure.

### 19.3 Heat Tiers

#### Tier 0: 0–19

- Introductory encounters
- No elite spawns

#### Tier 1: 20–39

- Increased spawn budget
- Small reward bonus

#### Tier 2: 40–59

- Ranged enemies enabled
- More aggressive encounters

#### Tier 3: 60–79

- Elite encounters enabled
- Increased enemy damage
- Higher reward quality

#### Tier 4: 80–99

- Maximum standard difficulty
- High elite chance
- Highest ordinary reward multiplier

#### Tier 5: 100

- Maximum district alert
- Highest immediate ordinary encounter danger and reward quality
- Does not by itself begin the boss encounter or reverse Night Pressure progression

### 19.4 Night Pressure

Night Pressure is a non-negative, monotonically increasing value. Its final range and threshold spacing are data-driven.

Night Pressure must:

- Increase through elapsed time
- Increase through encounters completed
- Never decrease during a run
- Gradually increase enemy health
- Gradually increase enemy damage
- Gradually increase encounter spawn budget
- Control major run progression
- Control extraction-window progression
- Eventually force the boss encounter
- Prevent indefinite farming even if Heat is repeatedly reduced

Only ending or restarting a run resets Night Pressure. Cards, shops, interventions, reroutes, and extraction decisions may alter Heat or the route but cannot rewind Night Pressure already earned.

Elapsed-time gain uses authoritative active simulation time. Paused states, modal reward and shop choices, and non-interactive introductions do not advance it. Encounter-completion gains are applied exactly once by `RunDirector` after an authoritative encounter result.

Extraction and boss thresholds are latched when first crossed and never reopen or clear because Heat later falls. If the boss threshold is crossed while an immediate transition would be unsafe, `RunDirector` queues the boss and starts it at the next valid transition boundary. When an extraction threshold and the boss threshold are reached by the same authoritative update, the boss takes precedence unless extraction was already confirmed before that update.

### 19.5 Initial Data-Driven Tuning

Prototype Heat values may use:

- Standard encounter completion: +4 Heat
- Elite encounter completion: +8 Heat
- Dangerous card: +10 to +20 Heat
- Cooling card: -10 to -20 Heat

Prototype Night Pressure scaling may begin with:

```text
enemy_health_multiplier = 1.0 + night_pressure × 0.01
enemy_damage_multiplier = 1.0 + night_pressure × 0.005
spawn_budget_multiplier = 1.0 + night_pressure × 0.0125
```

These formulas are initial tuning examples, not permanent balance values. Night Pressure gain rates, thresholds, multipliers, clamps, and boss timing must be data-driven and tuned through playtests. Spawn-budget conversion uses a documented deterministic rounding rule and still respects encounter and global concurrency caps, including the vertical-slice limit of 30 active ordinary enemies.

### 19.6 Anti-Farming Requirement

Lowering Heat must create temporary tactical relief without enabling an endless high-reward loop. Night Pressure continues to advance during eligible active play while the player cools the district, and its configured boss threshold eventually makes the boss unavoidable. No combination of cooling cards, shop purchases, or Subway Reroutes may indefinitely postpone major progression. Cooling never unlatches an extraction threshold, clears a queued boss, or reopens a spent progression window.

---

## 20. Interventions

Interventions are limited player-triggered abilities that affect active combat.

### 20.1 Fire Hydrant

**Type:** Environmental  
**Trigger:** Click the highlighted hydrant  
**Effect:**

- Blast a cone or circular area
- Deal light damage
- Apply strong knockback
- Apply Wet for future content compatibility
- Continue the combo meter

**Restrictions:**

- Cooldown or limited charges
- Cannot be triggered when no enemies are in range
- Must visibly preview the affected area on hover

### 20.2 Call Backup

**Type:** Active ability  
**Effect:**

- Spawn two temporary allied NPCs
- Allies fight for 12 seconds
- Allies disappear after duration or defeat

### 20.3 Subway Reroute

**Type:** Strategic intervention  
**Effect:**

- Immediately end the current non-boss travel segment
- Reduce Heat
- Move crew to the next route node
- Cannot skip an active boss encounter
- Consumes a finite charge or explicit consumable resource
- Cannot reduce Night Pressure or bypass its boss threshold

Subway Reroute must not be an infinitely repeatable cooling ability. Charge count, acquisition, per-run acquisition cap, and Heat reduction are data-driven. Charges do not regenerate merely through elapsed time, and an activation request at zero charges is rejected without changing Heat, route state, or Night Pressure.

### 20.4 Intervention Requirements

Every intervention must show:

- Icon
- Name
- Cost or charges
- Cooldown
- Valid or invalid state
- Hover tooltip
- Activation feedback

---

## 21. Equipment System

Equipment is represented by data-driven Resource definitions.

### 21.1 Equipment Slots

The long-term slot model is:

- Weapon slot
- Gear slot
- Tech slot

The vertical slice uses three generic equipment slots so any two distinct catalogue items can form a valid two-item synergy combination. Category-locked slots may be reconsidered later only if the required build combinations remain valid.

### 21.2 Initial Equipment

#### Spiked Bat

- Tags: `MELEE`, `BLEED`, `KNOCKBACK`
- Increased heavy-hit damage
- Chance to apply Bleed
- Increased knockback

#### Shock Gloves

- Tags: `TECH`, `SHOCK`, `FAST`
- Chance to apply Shock
- Slight attack speed bonus

#### Reinforced Jacket

- Tags: `DEFENCE`, `STREET`
- Increased maximum health
- Reduced knockback received

#### Hacker Deck

- Tags: `TECH`, `INTERVENTION`
- Reduced intervention cooldown
- Increased Shock duration

#### Steel-Toe Boots

- Tags: `KNOCKBACK`, `MOBILITY`
- Increased movement speed
- Increased environmental collision damage

#### Serrated Wraps

- Tags: `BLEED`, `FAST`
- Increased Bleed stack limit
- Increased damage against bleeding targets

#### Magnetic Flail

- Tags: `TECH`, `KNOCKBACK`
- Improves environmental interaction or pulls enemies into knockback chains

#### Voltaic Blade

- Tags: `TECH`, `BLEED`
- Applies Bleed and improves Shock interactions

#### Chain Sneakers

- Tags: `FAST`, `KNOCKBACK`
- Improves movement or attack speed and knockback follow-up

Exact numerical balance remains provisional.

### 21.3 Equipment Rules

- Effects must be defined in Resources where practical.
- UI must display all tags and major effects.
- Replacing equipment must immediately recalculate synergies.
- Equipment must not directly manipulate UI nodes.
- Equipment triggers must use shared effect interfaces rather than item-specific combat branches where practical.
- Equipment choices must create tradeoffs between completing the current synergy and opening a second possible build.
- The vertical-slice catalogue must contain at least nine items and no large rarity or crafting system.

---

## 22. Synergy System

Synergies activate when the crew’s combined equipment tags reach thresholds.

### Initial Synergies

#### Knockback 2

- +20% knockback distance
- +25% environmental collision damage

#### Bleed 2

- Bleed maximum stacks increased
- Crew deals bonus damage to bleeding enemies

#### Tech 2

- Intervention cooldowns reduced by 15%
- Shock duration increased

### Synergy Requirements

The system must:

- Count active tags
- Recalculate when equipment changes
- Emit an event when a synergy activates or deactivates
- Display current progress in the UI
- Support future thresholds such as 2, 4, and 6
- Avoid hard-coding checks for individual equipment IDs
- Give every primary vertical-slice synergy at least three valid two-item activation combinations
- Include at least two equipment items that bridge different primary synergy categories
- Preview both immediately activated synergies and progress toward alternative synergies in the UI

With the initial nine-item catalogue, Knockback, Bleed, and Tech each satisfy the three-combination requirement. `Spiked Bat`, `Magnetic Flail`, and `Voltaic Blade` create cross-category build decisions.

---

## 23. District Card System

District cards modify future route nodes or run rules.

### Initial Cards

#### Arcade

- Adds a fight encounter
- Heat change: +10
- Reward: increased upgrade choice quality

#### Convenience Store

- Adds a shop or recovery node
- Heat change: -10
- Allows one purchase, keeping shop-based cooling finite

#### Gang Hideout

- Adds an elite encounter
- Heat change: +20
- Reward: guaranteed equipment choice

#### Subway Entrance

- Reroutes the next route segment
- Heat change: -15
- Skips one standard encounter
- Cannot reduce Night Pressure or skip its extraction and boss progression requirements

### Card Flow

- Player begins with a small hand.
- Cards may be awarded after encounters.
- Cards are dragged onto valid route slots.
- Valid slots highlight during drag.
- Invalid placement provides immediate feedback.
- Played cards move to the discard pile.
- Route changes appear on the minimap.

### Vertical-Slice Simplification

The route may contain a fixed number of empty modification slots rather than fully procedural route construction.

---

## 24. Rewards and Upgrade Choices

### Reward Types

- Coins
- Scrap
- Equipment choice
- District card
- Crew recruitment
- Healing
- Intervention charge
- Temporary run modifier

### Coin Reward Delivery

Enemy coin rewards are delivered as clusters using the ambient interaction rules in section 7.3. Every coin-rewarding enemy resolves to one cluster. Auto-collection always grants the full base value. Manual collection may add only the capped streak bonus; it may never determine whether the base reward is kept. Each cluster has one authoritative resolution so simultaneous click and timeout cannot double-credit it.

When a coin cluster's base value is randomized, it and general reward selection use `rewards`; equipment choices use `equipment`; and card choices use `cards`. Presentation timing or cosmetic burst patterns use `cosmetic` and must not consume gameplay reward randomness. Milestone 1 uses fixed authored base values so coin-cluster behavior can be validated before the named-stream infrastructure arrives with the complete run structure in Milestone 3.

### Choice Presentation

A reward choice should usually display three options.

Each option must include:

- Name
- Icon
- Short description
- Relevant tags
- Numerical values where useful
- Current synergy impact preview
- Immediate synergy activations and progress toward alternative synergy paths

The run pauses during major reward selection.

---

## 25. Economy

### Coins

Used during the current run for:

- Shop purchases
- Healing
- Equipment
- Intervention charges

Coins are lost at the end of the run unless explicitly converted.

Coin collection rules:

- Each coin-rewarding defeated enemy produces one clickable cluster rather than many precision targets.
- Clusters auto-collect after approximately 2.5 seconds for the full base reward.
- Clicking collects immediately and, only when it succeeds before auto-collection, advances a roughly 3-second manual collection streak.
- The streak window is measured from the previous successful manual collection and resets when that interval expires; auto-collection neither advances nor receives the streak bonus.
- The streak bonus is small, data-driven, and capped at 10% of the current cluster's base value.
- Click and timeout can resolve a cluster only once, so its base value cannot be duplicated.
- Missing or ignoring a cluster never loses its base value.

Shop purchases that reduce Heat must have meaningful cost and finite stock or an explicit per-run purchase limit; increasing price alone is not a sufficient anti-farming limit. Coins must not enable unlimited cooling.

### Scrap

Represents secured progression currency.

Scrap is awarded based on:

- Encounters completed
- Maximum Heat reached
- Night Pressure reached
- Elites defeated
- Boss victory
- Extraction timing

Heat may improve immediate ordinary reward quality, while secured progression rewards may also account for the maximum Heat and Night Pressure reached. Reducing current Heat cannot erase Night Pressure-based escalation or recreate already-consumed high-tier rewards.

The vertical slice may display Scrap totals without implementing a large permanent upgrade system.

---

## 26. Extraction

Extraction is the central risk-versus-reward decision.

### Extraction Windows

Extraction becomes available:

- At a designated route node
- At configured Night Pressure progression thresholds
- After selected milestone encounters when the next pressure threshold permits it

### Extraction Behaviour

When extraction is available:

- Display a prominent button
- Show estimated secured rewards
- Show current reward multiplier
- Require one confirmation
- Stop new encounters during the extraction sequence
- Play a short extraction animation
- End the run as `EXTRACTED`

### Continuing

If the player declines extraction:

- Heat may increase
- Night Pressure remains irreversible and continues to rise
- Reward multiplier increases
- Future encounters become harder
- The next extraction opportunity occurs at a later Night Pressure threshold

### Boss Restriction

When Night Pressure reaches the configured boss threshold, the boss encounter becomes unavoidable and extraction closes until the boss encounter resolves. Heat 100 alone does not start the boss or permanently close extraction.

---

## 27. Run States

The run uses explicit states:

- `INITIALIZING`
- `INTRO`
- `PATROLLING`
- `ENCOUNTER_ACTIVE`
- `REWARD_SELECTION`
- `SHOP`
- `EXTRACTION_AVAILABLE`
- `EXTRACTING`
- `BOSS_INTRO`
- `BOSS_ACTIVE`
- `VICTORY`
- `DEFEAT`
- `RUN_SUMMARY`
- `PAUSED`

Only the `RunDirector` may authoritatively change the run state.

Other systems may request transitions through defined methods or signals.

---

## 28. Run Summary

The run summary must display:

- Result: Victory, Extracted, or Defeated
- Run duration
- Run seed
- Maximum Heat reached
- Final Night Pressure reached
- Enemies defeated
- Elites defeated
- Boss defeated
- Coins collected
- Manual coin clusters collected and maximum collection streak
- Scrap secured
- Highest combo
- Equipment build
- Active synergies
- “Restart Run” button
- “Return to Main Menu” button

Restarting should return to active play quickly.

---

## 29. Meta-Progression

The vertical slice includes only a minimal unlock structure.

Allowed persistent unlocks:

- Unlock Zoey
- Unlock Rex
- Unlock one additional equipment item
- Unlock one additional district card

The equipment unlock may gate one entry from the required at-least-nine-item catalogue; it does not imply an undocumented tenth required item. Development and test profiles must be able to access all nine catalogue entries for build-combination validation.

The game must remain completable without permanent statistical bonuses.

Large permanent stat trees are deferred.

---

## 30. User Interface Requirements

### 30.1 General

- UI must remain readable at 1080p and 1440p.
- Pixel-art assets should use nearest-neighbour filtering.
- Text may use a pixel-inspired font but must remain legible.
- Tooltips should appear after a short hover delay.
- Important values should not depend on colour alone.
- Ambient interactions must use generous hit areas and remain safe to ignore.
- Pausing must stop gameplay logic.

### 30.2 Health Bars

Health bars must show:

- Current health
- Maximum health
- Recent damage indication
- Incapacitated state

### 30.3 Heat Meter

The Heat meter must show:

- Numeric Heat
- Tier
- Direction of recent change
- Upcoming threshold
- District alert implications at the current tier

### 30.4 Night Pressure Meter

Night Pressure must be visually distinct from Heat and show:

- Current irreversible pressure
- Progress toward the next extraction window or major run threshold
- Enemy scaling trend
- Clear warning as the unavoidable boss threshold approaches

Cooling feedback must never imply that Night Pressure decreased.

### 30.5 Card UI

Cards must show:

- Name
- Art or placeholder
- Cost
- Heat effect
- Night Pressure or major-progression implications when relevant
- Node effect
- Tags
- Valid placement feedback

### 30.6 Synergy UI

The synergy panel must show:

- Tag name
- Current count
- Required threshold
- Active effect
- Active or inactive state
- Synergies activated immediately by a choice
- Progress opened toward alternative synergies

### 30.7 Coin Cluster UI

Coin clusters must:

- Use a generous clickable area
- Show that base value will auto-collect
- Communicate the remaining auto-collection delay without demanding attention
- Show the active manual collection streak and capped bonus
- Avoid obscuring combat or requiring precision clicking

---

## 31. Art Direction

### 31.1 Visual Style

- Original 16-bit-inspired pixel art
- Urban neon setting
- High-contrast silhouettes
- Readable characters
- Exaggerated combat poses
- Wet street reflections
- Limited but rich palette
- Modern UI usability layered over retro visuals

The art may evoke the era of classic arcade brawlers without copying characters, stages, logos, animations, or protected visual designs from existing games.

### 31.2 Character Scale

At the 640 × 360 internal resolution:

- Crew characters should appear approximately 48–72 pixels tall
- Basic enemies should use comparable scale
- Boss may be larger
- Attack silhouettes must remain readable at native scale

### 31.3 Animation Requirements

Minimum animation set per ordinary actor:

- Idle
- Walk
- Attack
- Hit
- Knockback
- Incapacitated or death

Optional later:

- Heavy attack
- Lane change
- Victory
- Status reaction

### 31.4 Placeholder Policy

Development placeholders are allowed.

Placeholders must:

- Be visually distinct
- Indicate intended dimensions
- Not be mistaken for final assets
- Be replaceable without changing gameplay code

---

## 32. Audio Direction

### Required Audio Categories

- Light hit
- Heavy hit
- Knockback
- Environmental collision
- Coin cluster auto-collection and manual collection
- Coin collection streak increase
- Card placement
- Intervention activation
- Heat tier increase
- Night Pressure threshold warning
- Extraction available
- Boss introduction
- Victory
- Defeat
- UI hover and confirm

### Music

The vertical slice should include:

- One looping district track
- One boss variation or layer
- Optional Heat-based intensity layers

Audio assets may be placeholders during early implementation.

---

## 33. Technical Architecture

### 33.1 Architectural Principles

- Prefer composition over deep inheritance.
- Use typed GDScript.
- Use custom Resources for tunable data.
- Keep gameplay logic out of UI scenes.
- Use signals for cross-system communication.
- Avoid unnecessary Autoloads.
- Keep scene responsibilities narrow.
- Do not hard-code content IDs into unrelated systems.
- Separate deterministic calculations from presentation.
- Route all gameplay randomness through run-scoped deterministic named streams.
- Make important state inspectable in debug tools.

### 33.2 Recommended Autoloads

Allowed initial Autoloads:

#### AppState

- Persistent settings
- Current profile
- Scene transition requests

#### SaveService

- Load and save persistent data
- Version save files

No other Autoload should be added without documenting the reason.

The run itself must not be managed as a global singleton.

### 33.3 Run-Scoped Deterministic Randomness

Every run has one authoritative integer seed owned by `RunDirector`. A run may be started with a supplied seed; otherwise `RunDirector` generates and records one before any gameplay random draw occurs. Automatic seed creation is an initialization boundary and may use platform entropy or time; once the integer seed is committed, every gameplay random choice comes only from its deterministic named streams.

`RunDirector` owns a run-scoped `RunRandomStreams` component. This component is not an Autoload. It derives stable sub-seeds from the authoritative run seed, a versioned, platform-stable derivation algorithm, and these stream names:

- `encounters`
- `spawns`
- `rewards`
- `equipment`
- `cards`
- `enemy_variants`
- `cosmetic`

Gameplay systems receive or request only the stream appropriate to their responsibility. They must not use unseeded global random calls such as `randi()`, `randf()`, `randomize()`, `Array.shuffle()`, or `Array.pick_random()`, and they must not all consume one fragile shared random sequence. Seed derivation must not depend on a process- or platform-unstable hash; the algorithm and `random_schema_version` are part of the reproducibility contract.

Before a gameplay stream chooses among content, the candidate set must be filtered deterministically and sorted by stable content ID. Scene-tree insertion order, dictionary iteration order, and presentation order must not decide gameplay outcomes.

The `cosmetic` stream is isolated from gameplay streams. Adding or changing cosmetic draws must not alter encounter, spawn, reward, equipment, card, or enemy-variant outcomes. Systems may introduce more narrowly scoped deterministic substreams later when ordering within one named domain would otherwise become fragile, but the derivation contract must remain documented and testable.

Within the same supported build, content revision, and random-schema version, starting with the same seed and making the same gameplay-relevant decisions at the same authoritative timing points must produce the same gameplay outcomes. This requirement does not promise cross-version or bitwise-identical physics replay. Development bug reports must include the run seed, build/content/schema versions, and enough ordered decision and timing context to reproduce the sequence.

---

## 34. Core Runtime Systems

### RunDirector

Owns:

- Run state
- Run timer
- Heat
- Night Pressure
- Route progression
- Encounter scheduling
- Extraction
- Boss trigger
- Win and loss conditions
- Reward multiplier
- Authoritative run seed
- Run-scoped deterministic named random streams

### RunRandomStreams

Owns:

- Stable, versioned derivation of named sub-seeds from the authoritative run seed
- One deterministic generator state per documented stream
- Stream access by declared `StringName`
- Development-only draw counts or state identifiers for diagnostics
- Serialization hooks required by any future replay or mid-run save format

It does not choose gameplay content, own presentation, or exist outside the lifetime of its run.

### PatrolController

Owns:

- Route node sequence
- Crew movement between nodes
- Route modification
- Pausing patrol during encounters
- Subway reroute behaviour

### CombatDirector

Owns:

- Active encounter
- Active combatants
- Team membership
- Encounter completion
- Target coordination
- Reward request after combat
- Deterministic spawn and enemy-variant stream usage

### ActorController

Owns:

- Actor state
- Health
- Movement
- Target
- Attack execution
- Status effects
- Equipment-derived modifiers

### RewardDirector

Owns:

- Reward tables
- Choice generation
- Reward presentation request
- Applying selected rewards
- Authoritative coin ledger, cluster collection resolution, and collection-streak bonus
- Deterministic reward and equipment stream usage

Milestone 1 introduces only the narrow coin-ledger, single-resolution cluster, and manual-streak responsibilities needed for the Combat Lab. Shops, broad reward-choice systems, and later economy features remain in their assigned milestones.

### CardSystem

Owns:

- Draw pile
- Hand
- Discard pile
- Placement validation
- Card resolution
- Deterministic card stream usage

### SynergySystem

Owns:

- Active equipment tags
- Threshold evaluation
- Derived synergy modifiers
- Activation and deactivation events

### GameHUD

Owns:

- Presentation
- Player input forwarding
- Tooltips
- UI animation

The HUD must not own authoritative gameplay state.

---

## 35. Recommended Scene Structure

```text
GameRun
├── RunDirector
│   └── RunRandomStreams
├── PatrolController
├── CombatDirector
├── RewardDirector
├── CardSystem
├── SynergySystem
├── DistrictStage
│   ├── Background
│   ├── LaneMarkers
│   ├── RouteNodes
│   ├── SpawnPoints
│   ├── Interactables
│   ├── CrewContainer
│   ├── EnemyContainer
│   ├── EffectsContainer
│   └── LootContainer
├── Camera2D
├── GameHUD
└── DebugOverlay
```

### Actor Scene

```text
Actor
├── VisualRoot
│   ├── AnimatedSprite2D
│   ├── Shadow
│   └── StatusVisuals
├── CollisionShape2D
├── Hurtbox
├── HitboxContainer
├── NavigationController
├── StateMachine
├── AttackController
├── StatusController
└── AudioController
```

---

## 36. Recommended Repository Structure

```text
res://
  assets/
    audio/
    fonts/
    sprites/
    ui/

  data/
    crew/
    enemies/
    attacks/
    equipment/
    cards/
    encounters/
    heat_tiers/
    synergies/
    interventions/
    rewards/

  scenes/
    game/
    stages/
    actors/
    combat/
    interactables/
    ui/
    effects/
    debug/

  scripts/
    run/
    patrol/
    combat/
    actors/
    cards/
    equipment/
    synergies/
    rewards/
    ui/
    save/
    utilities/

  tests/
    unit/
    integration/
    fixtures/

  docs/
    concepts/
    decisions/

  GameSpecifications.md
  AGENTS.md
  ARCHITECTURE.md
  IMPLEMENTATION_PLAN.md
  TEST_PLAN.md
  CONTENT_CATALOG.md
  CHANGELOG.md
```

---

## 37. Data Definitions

Use custom Godot Resources for content.

### CrewDefinition

```text
id: StringName
display_name: String
portrait: Texture2D
sprite_frames: SpriteFrames
max_health: float
movement_speed: float
base_damage: float
attack_range: float
attack_cooldown: float
knockback_strength: float
starting_equipment: Array[EquipmentDefinition]
```

### EnemyDefinition

```text
id: StringName
display_name: String
sprite_frames: SpriteFrames
max_health: float
movement_speed: float
base_damage: float
attack_range: float
attack_cooldown: float
knockback_resistance: float
reward_value: int
ai_profile: EnemyAIProfile
```

### AttackDefinition

```text
id: StringName
display_name: String
damage_multiplier: float
windup_time: float
active_time: float
recovery_time: float
range: float
knockback_force: float
hit_stop_duration: float
status_applications: Array[StatusApplication]
```

### EquipmentDefinition

```text
id: StringName
display_name: String
description: String
icon: Texture2D
tags: Array[StringName]
stat_modifiers: Array[StatModifier]
triggered_effects: Array[TriggeredEffectDefinition]
rarity: int
```

### DistrictCardDefinition

```text
id: StringName
display_name: String
description: String
icon: Texture2D
cost: int
heat_delta: int
valid_node_types: Array[StringName]
effect_definition: CardEffectDefinition
```

### EncounterDefinition

```text
id: StringName
display_name: String
minimum_heat: int
minimum_night_pressure: float
base_spawn_budget: int
spawn_entries: Array[SpawnEntry]
maximum_concurrent_enemies: int
reward_table: RewardTable
elite: bool
boss: bool
```

### RunEscalationDefinition

```text
passive_pressure_per_second: float
pressure_per_standard_encounter: float
pressure_per_elite_encounter: float
extraction_pressure_thresholds: PackedFloat32Array
boss_pressure_threshold: float
health_multiplier_per_pressure: float
damage_multiplier_per_pressure: float
spawn_budget_multiplier_per_pressure: float
```

### RunRandomSchemaDefinition

```text
schema_version: int
derivation_algorithm_id: StringName
declared_stream_names: Array[StringName]
```

The initial declared stream names are the seven names in section 33.3. A schema-version change is required when seed derivation or draw semantics change in a way that invalidates prior reproduction metadata.

### CoinClusterTuning

```text
auto_collect_delay: float
manual_streak_window: float
manual_bonus_curve: Curve
maximum_manual_bonus: float
```

The prototype maximum manual bonus is 0.10. Award rounding and click-versus-timeout resolution must use one documented deterministic rule.

### SynergyDefinition

```text
id: StringName
display_name: String
tag: StringName
required_count: int
description: String
modifiers: Array[StatModifier]
triggered_effects: Array[TriggeredEffectDefinition]
```

---

## 38. Signals and Event Contracts

Suggested cross-system signals:

```text
run_state_changed(previous_state, new_state)
run_started(seed)
run_completed(result)
heat_changed(previous_value, new_value)
heat_tier_changed(previous_tier, new_tier)
night_pressure_changed(previous_value, new_value)
night_pressure_threshold_reached(threshold_id, value)
boss_queued()
route_node_entered(route_node)
encounter_started(encounter_definition)
encounter_completed(encounter_definition)
actor_spawned(actor)
actor_incapacitated(actor)
actor_died(actor)
enemy_defeated(enemy, killer)
coin_cluster_spawned(cluster, base_value)
coin_cluster_collected(cluster, manual, base_value, bonus_value, streak_count)
damage_dealt(source, target, amount, hit_result)
combo_changed(value)
reward_choice_requested(options)
reward_selected(reward)
equipment_added(actor, equipment)
equipment_removed(actor, equipment)
synergy_activated(synergy)
synergy_deactivated(synergy)
card_drawn(card)
card_played(card, route_node)
intervention_used(intervention)
extraction_became_available()
extraction_requested()
boss_started()
boss_defeated()
```

Signals must use stable, documented argument types.

Avoid a single untyped global event bus unless a specific need is documented.

---

## 39. Save Data

### Persistent Data

- Save version
- Unlocked crew IDs
- Unlocked equipment IDs
- Unlocked card IDs
- Lifetime statistics
- Audio settings
- Display settings
- Input settings

### Non-Persistent Run Data

Active run state does not need mid-run saving for the vertical slice.

The run seed, random-schema version, content/build version, and gameplay-relevant decision trace should be captured in development bug reports. The seed is sufficient to restart a run from the beginning, but it is not sufficient to resume an already-consumed random sequence.

### Save Requirements

- Save files must be versioned.
- Missing optional fields must receive defaults.
- Corrupt saves must fail safely.
- Development builds should include a reset-save option.

### Replay and Future Mid-Run Save Considerations

Any future mid-run save or replay format must preserve:

- Authoritative run seed
- Random-schema and content/build versions
- State or draw position for every named random stream
- Authoritative Heat, Night Pressure, route, encounter, actor, and reward state
- Ordered player decisions, including authoritative simulation timing where timing affects outcomes

Determinism is guaranteed only within a supported build/content/schema version given the same seed and gameplay-relevant decisions. Cross-version or bitwise-identical physics replay is not implied.

Optional supplied seeds support future daily-run design, but daily scheduling, shared rules, leaderboards, and rewards remain deferred.

---

## 40. Debugging Tools

A development build must include a toggleable debug overlay.

The overlay should display:

- Current run state
- Run seed and random-schema version
- Run time
- Heat and tier
- Night Pressure, next extraction threshold, and boss threshold
- Boss queued state
- Current route node
- Active encounter ID
- Crew state and target
- Enemy state and target
- Current lane
- Reserved attack position
- Active status effects
- Active synergies
- Spawn budget
- Per-stream draw count or state identifier
- Active coin clusters and collection streak
- Remaining Subway Reroute charges
- Remaining shop cooling purchases
- Frames per second

### Debug Controls

Development-only controls may include:

- Add 10 Heat
- Reduce 10 Heat
- Add Night Pressure
- Advance to the next Night Pressure threshold
- Spawn basic enemy
- Spawn elite
- Start boss
- Heal crew
- Grant equipment
- Draw card
- Force extraction window
- Restart run
- Restart with the same seed
- Copy seed and bug-report metadata

Debug tools must not provide an ordinary “Reduce Night Pressure” control. A forced boss threshold must queue the boss through the same safe transition boundary as normal progression.

Debug features must be disabled or hidden in release builds.

---

## 41. Testing Requirements

### Unit Tests

Required deterministic test coverage:

- Heat tier calculation
- Night Pressure never decreases and advances only through eligible active time and exactly-once encounter completion
- Night Pressure scaling, deterministic spawn-budget rounding, concurrency caps, and latched extraction and boss thresholds
- Boss-threshold precedence and safe-boundary queueing
- Damage calculation
- Synergy threshold activation
- Equipment modifier aggregation
- The nine-item equipment matrix provides at least three valid two-item combinations per primary synergy and at least two bridge items
- Card placement validation
- Reward table selection
- Coin cluster click and timeout each grant the full base value exactly once
- A click-versus-timeout race cannot duplicate a coin award
- Only successful manual collections advance the approximately three-second streak
- Auto-collection grants no manual bonus, and every per-cluster manual bonus is at most 10% of that cluster's base value
- Target validity
- Save-data migration or defaulting
- Identical seed and identical decisions produce identical reward selections
- Identical seed and identical decisions produce identical encounter selections
- Extra `cosmetic` draws do not change encounter, reward, equipment, card, spawn, or enemy-variant outcomes
- Different seeds produce meaningfully different run sequences across a documented sample rather than relying on one possibly coincidental comparison
- Candidate ordering remains stable when source containers are inserted in a different order

### Integration Tests

Required integration scenarios:

- Crew acquires and defeats an enemy
- Encounter completes after all enemies are defeated
- Heat reaches a new tier
- Lowering Heat creates tactical relief without decreasing Night Pressure, reopening a spent extraction threshold, or clearing a queued boss
- Paused, modal-choice, and introduction time does not advance Night Pressure
- Finite shop cooling and Subway Reroute charges cannot postpone the boss indefinitely
- A supplied seed is displayed, recorded in the summary, and reproduced by a same-seed restart
- Equipment change activates a synergy
- Equipment choice previews immediate activations and progress toward alternative synergy paths
- Coin clusters auto-collect for full base value, accept generous manual input, and are removed or recycled after either resolution
- Fire hydrant damages and knocks back valid enemies
- Extraction ends the run
- All crew incapacitated triggers defeat
- Boss defeat triggers victory

### Manual Verification

Every milestone must include a short manual verification checklist.

Visual features require screenshots or recorded evidence during development.

Manual cadence checks must distinguish eligible active play from pauses, modal choices, and introductions. They should verify that ambient opportunities occur approximately every 10–20 active seconds without manufacturing extra strategic prompts, that strategic decisions remain approximately 30–60 active seconds apart, and that major risk decisions remain approximately 2–3 active minutes apart.

The Milestone 1 Human Validation Gate in section 44 is a separate owner-recorded qualitative gate. Automated tests, coding agents, and implementation-team observations cannot satisfy it.

---

## 42. Performance Requirements

Target:

- 60 frames per second at 1080p on a typical modern integrated or low-end dedicated GPU
- No more than 30 active ordinary enemies in the vertical slice
- No unbounded object creation during combat
- Reuse frequently spawned effects through pooling where beneficial
- Avoid per-frame full-scene searches
- Avoid unnecessary allocations in `_process` and `_physics_process`
- Remove or recycle resolved coin clusters, expired damage numbers, projectiles, and effects

Performance optimization should follow profiling. Do not prematurely build complex pooling systems before a measurable need exists.

---

## 43. Accessibility and Options

The vertical slice should include:

- Master volume
- Music volume
- Sound effects volume
- Full-screen toggle
- Windowed mode
- Screen shake intensity
- Damage number toggle
- Hit flash reduction
- Pause on focus loss
- Ability to pause at any time outside unskippable transitions

Important information must not rely on colour alone.

---

## 44. Milestone Plan

## Milestone 0 — Project Foundation

### Deliverables

- Godot project opens without errors
- Folder structure exists
- Main scene exists
- Empty Downtown Loop stage exists
- Placeholder UI shell exists
- Debug overlay exists
- Typed GDScript convention established
- Core documentation exists

### Acceptance Criteria

- Project launches into the game screen.
- No parser errors.
- No runtime errors.
- Debug overlay can be toggled.
- Empty street renders at the intended internal resolution.

---

## Milestone 1 — Combat Lab

### Deliverables

- Jax actor
- Street Punk enemy
- Actor state machine
- Lane movement
- Target acquisition
- Attack position reservation
- Basic attack
- Damage
- Health
- Knockback
- Hit-stop
- Damage numbers
- Enemy death
- Coin-rewarding enemy creates one clickable coin cluster
- Fixed authored base coin values; randomized reward generation remains deferred to Milestone 3
- Approximately 2.5-second full-value auto-collection
- Immediate manual collection with an approximately 3-second streak and per-cluster bonus capped at 10%
- At-most-once coin-award resolution
- A repeatable Combat Lab sequence that can be observed for at least 60 seconds
- Sufficient placeholder audio and visual feedback to evaluate hit timing and readability

### Acceptance Criteria

- Jax automatically acquires a valid enemy.
- Jax approaches and attacks without direct control.
- Enemy can attack Jax.
- Hits occur only during valid attack frames.
- Knockback is visible.
- Dead enemies cannot remain targeted.
- Repeated enemy spawning works without runtime errors.
- Combat remains understandable with five enemies present.
- Every coin-rewarding enemy creates one cluster; explicitly rewardless enemies create none.
- Ignoring a cluster grants its full base value after approximately 2.5 seconds.
- Manual collection is immediate, uses a generous target, and never interrupts combat.
- Only successful manual collections advance the approximately 3-second streak, and the bonus never exceeds 10% of the current cluster's base value.
- Click and auto-collection races can credit a cluster only once.
- The Combat Lab runs repeatably for at least 60 seconds without requiring coin clicks or direct character control.

---

## Milestone 1 Human Validation Gate — Owner Recorded

This mandatory qualitative gate occurs only after all technical Milestone 1 acceptance criteria pass and before any Milestone 2 implementation begins. It tests the central hypothesis that automatic combat is entertaining to watch without direct character control.

### Procedure

- The project owner recruits at least five people who were not involved in implementation.
- The owner designates a five-person scored cohort before observation; any additional testers are supplemental and do not replace a failed scored observation.
- Each tester receives only: “Watch this fight and tell me when you feel ready to stop.”
- The intended build systems, future features, and desired conclusions are not explained beforehand.
- The owner records observation duration and concise, unattributed notes for each tester.
- Coin clicking is allowed if discovered naturally, but engagement with coin clusters is not evidence by itself that passive combat is entertaining.

### Go/No-Go Criteria

The gate passes only when the owner records all of the following:

- At least four of five testers voluntarily watch for 60 seconds.
- At least three testers express curiosity about what happens next or request another encounter.
- Most testers can identify who is attacking whom.
- Most testers identify at least one satisfying hit, reaction, or combat moment.
- Combat is not broadly described as confusing, lifeless, or visually difficult to follow.

For this five-person check, “most” means at least three testers.

Five testers are not statistically significant market research. This is an early go/no-go check intended to expose an obviously weak combat foundation.

### Failure and Authority

If any criterion fails, Milestone 2 is blocked even when technical tests pass. Improve the relevant attack timing, animation, sound, hit reactions, targeting readability, enemy density, pacing, or visual effects, then repeat the full gate after revisions.

Only the project owner may record this gate as passed. Codex, another coding agent, automated tests, and members of the implementation team must never claim or infer a pass.

---

## Milestone 2 — Player Intervention

**Entry condition:** the project owner has recorded a passing Milestone 1 Human Validation Gate.

### Deliverables

- Fire hydrant interactable
- Hover highlight
- Range preview
- Click activation
- Area damage
- Strong knockback
- Cooldown or charge
- UI button state
- Audio and visual feedback

### Acceptance Criteria

- Hydrant cannot activate when unavailable.
- Activation can materially change an encounter.
- Enemies in range are knocked back.
- Enemies outside range are unaffected.
- Tooltip clearly explains the effect.
- Cooldown is visible.

---

## Milestone 3 — Complete Run Structure

### Deliverables

- RunDirector
- Patrol route
- Run timer
- Encounter scheduling
- Heat
- Heat tiers
- Irreversible Night Pressure with active-time and encounter gains
- Night Pressure enemy and spawn-budget scaling
- Latched extraction progression and unavoidable boss threshold
- Finite Subway Reroute charges and finite shop-based Heat cooling
- Authoritative integer run seed, optional supplied seed, and run-scoped named random streams
- Standard rewards
- Extraction window
- Defeat state
- Boss trigger
- Run summary

### Acceptance Criteria

- A run begins, escalates, and ends.
- Heat visibly changes immediate encounter conditions and can be reduced for limited tactical relief.
- Night Pressure never decreases, advances major progression, and eventually queues the boss despite Heat reduction.
- Paused and modal time does not advance Night Pressure.
- Shop and Subway cooling are finite and cannot reopen progression thresholds.
- Player can extract.
- Player can lose.
- Player can reach the boss.
- Summary accurately reports the result.
- Debug overlay and summary show the authoritative seed; same-seed restart reproduces gameplay selections for identical decisions within the same build/content/schema version.
- Cosmetic draws do not change gameplay-stream outcomes.
- Restart begins a new clean run.

---

## Milestone 4 — Equipment and Synergies

### Deliverables

- At least nine equipment items, including Magnetic Flail, Voltaic Blade, and Chain Sneakers
- Equipment UI
- Tag aggregation
- Knockback synergy
- Bleed synergy
- Tech synergy
- Equipment reward choice
- Recalculation when equipment changes
- Immediate activation and alternative-path synergy previews

### Acceptance Criteria

- At least three visibly distinct builds are possible.
- Each primary synergy has at least three valid two-item activation combinations.
- At least two items bridge different primary synergy categories and create a visible build tradeoff.
- Synergies activate at the correct threshold.
- The UI previews both whether an item activates a synergy immediately and what alternative synergy progress it opens.
- Removing an item can deactivate a synergy.
- No equipment item requires UI-specific gameplay logic.

---

## Milestone 5 — District Cards

### Deliverables

- Card definitions
- Hand
- Draw
- Drag and drop
- Placement validation
- Route slots
- Four initial cards
- Minimap route updates
- Card reward source

### Acceptance Criteria

- Cards can only be placed on valid nodes.
- Route effects occur at the correct time.
- Heat changes are applied correctly.
- Played cards visibly alter future run events.
- Invalid placement returns the card to the hand.

---

## Milestone 6 — Vertical-Slice Content and Presentation

### Deliverables

- Three crew members
- Three basic enemy types
- One elite
- One boss
- Three interventions
- Finished prototype HUD
- Improved animations
- Improved effects
- Music
- Sound effects
- Tutorial prompts
- Settings
- Persistent unlocks
- Final run summary
- Tuned ambient optional interaction cadence

### Acceptance Criteria

- The game supports a complete 8–12 minute run.
- Each crew member feels distinct.
- At least three build strategies are viable.
- Ambient optional interactions occur approximately every 10–20 eligible active seconds, meaningful strategic decisions every 30–60 seconds, and major risk decisions every 2–3 minutes.
- The boss is readable and defeatable.
- Extraction is strategically meaningful.
- The game can be restarted repeatedly without state leakage.
- The vertical slice is understandable without developer explanation.

---

## 45. Vertical-Slice Completion Criteria

The vertical slice is complete only when all of the following are true:

1. The project launches without errors.
2. A complete run can end in victory, extraction, or defeat.
3. Automatic combat is understandable and visually satisfying.
4. The player has a meaningful intervention during combat.
5. Optional coin clusters meet their active-play cadence, preserve the full passive base reward, and cap manual bonuses at 10% per cluster.
6. Heat creates observable tactical escalation and finite cooling creates only temporary relief.
7. Night Pressure irreversibly advances extraction progression and eventually forces the boss.
8. At least nine equipment items create genuine tradeoffs, with at least three two-item combinations per primary synergy and at least two bridge items.
9. Equipment choices visibly change combat.
10. At least one synergy creates an exciting interaction.
11. District cards alter future encounters.
12. The extraction decision creates real tension.
13. The boss provides a clear final test.
14. Run restart is fast and reliable.
15. No critical gameplay system depends on placeholder debug input.
16. The project architecture is documented.
17. Deterministic logic has automated test coverage, including named-stream isolation and same-seed selection reproducibility.
18. The project owner has manually recorded a passing Milestone 1 Human Validation Gate before any Milestone 2 work.
19. The game remains stable over repeated runs.

---

## 46. Deferred Features

Do not implement these until the vertical slice is complete:

- Additional districts
- Procedural route generation
- Large crew roster
- Narrative campaign
- Factions
- Advanced meta-progression
- Item crafting
- Difficulty modes
- Challenge runs
- Daily runs
- Online leaderboards
- Multiplayer
- Modding
- Steam integration
- Achievements
- Controller support
- Localization
- Console ports

The run-seed and named-stream infrastructure is required for the vertical slice and is not deferred. Only the daily schedule, shared daily seed/rules, comparison services, leaderboards, and daily rewards are deferred.

---

## 47. Coding-Agent Working Rules

When implementing this project:

1. Read this document before modifying gameplay systems.
2. Read `ARCHITECTURE.md` before changing scene ownership or dependencies.
3. Read `AGENTS.md` before beginning any task.
4. Implement one clearly scoped milestone task at a time.
5. Do not declare work complete without launching the Godot project.
6. Inspect the Godot debugger and output after every implementation.
7. Do not suppress warnings or errors merely to produce a clean log.
8. Add or update tests for deterministic logic.
9. Use placeholder assets where final assets do not exist.
10. Do not modify unrelated scenes or systems.
11. Do not add Autoloads without documenting the reason.
12. Prefer typed GDScript.
13. Prefer composition over deep inheritance.
14. Put tunable values in Resources.
15. Keep UI logic separate from gameplay logic.
16. Update implementation documentation after completed work.
17. Capture screenshots for visual acceptance criteria.
18. Preserve existing working behaviour unless the task explicitly changes it.
19. Stop and report architectural conflicts rather than silently bypassing them.
20. Never attempt to build all deferred features in one pass.
21. Never use unseeded global randomness for gameplay; use the documented run-scoped named stream and deterministic candidate ordering.
22. Never claim the Milestone 1 Human Validation Gate passed; only report the project owner's recorded result.
23. Do not begin Milestone 2 until that owner-recorded gate passes.

---

## 48. Recommended First Codex Task

Use the following as the first implementation request after this file is added to the repository:

```text
Create the Milestone 0 technical foundation for Neon Loop.

Read the repository's canonical `GameSpecifications.md` in full.

Goal:
Create a clean Godot 4.x project foundation for the Neon Loop vertical slice.

Implement:
- The recommended repository folders
- A 640 × 360 game viewport configured for integer pixel-art scaling
- A GameRun main scene
- An empty Downtown Loop stage with three visible debug lanes
- A placeholder HUD containing Heat, timer, crew, cards, synergies, interventions, and extraction regions
- A toggleable development DebugOverlay
- Typed placeholder scripts for RunDirector, PatrolController, CombatDirector, RewardDirector, CardSystem, and SynergySystem
- ARCHITECTURE.md
- AGENTS.md
- IMPLEMENTATION_PLAN.md
- TEST_PLAN.md
- CONTENT_CATALOG.md
- CHANGELOG.md

Do not implement combat, enemies, cards, equipment, or progression yet.

Acceptance criteria:
1. The project launches directly into GameRun.
2. The empty street and HUD shell are visible.
3. Debug lanes can be toggled.
4. The DebugOverlay can be toggled with F1.
5. No parser errors occur.
6. No runtime errors occur.
7. All new scripts use typed GDScript.
8. Each system script contains a concise responsibility comment.
9. Documentation accurately reflects the created project.
10. Capture a screenshot of the running foundation.
```

---

## 49. Prototype Review Questions

After each milestone, answer these questions through playtesting:

### Combat

- Is it entertaining to watch a crew member fight without direct control?
- Are hit timing and impact readable?
- Does knockback produce satisfying outcomes?
- Can the player understand why an actor selected a target?

### Interaction

- Does the player have enough to do?
- Do ambient optional opportunities occur every 10–20 eligible active seconds without becoming mandatory busywork?
- Does ignoring coin clusters preserve the full base reward while manual collection remains modestly satisfying?
- Are strategic and major risk decisions still distinct from ambient clicks?
- Are interventions meaningful rather than cosmetic?
- Is the player making decisions or only clicking cooldowns?

### Build Construction

- Do equipment choices visibly change behaviour?
- Can the player recognize an emerging build?
- Are synergy thresholds understandable?
- Do bridge items create a real tradeoff between completing one synergy and opening another?
- Does the UI explain both immediate activation and alternative-path progress?

### Run Structure

- Does Heat create tension?
- Does lowering Heat feel useful without appearing to rewind Night Pressure?
- Does Night Pressure communicate irreversible progress toward extraction windows and the boss?
- Is extraction a legitimate strategic choice?
- Does the run escalate quickly enough?
- Does the boss feel like the conclusion of the run?

### Reproducibility

- Can a tester copy the seed and reproduce gameplay selections with the same decisions in the same build/content/schema version?
- Can presentation randomness change without altering gameplay outcomes?

### Scope

- Is a new feature solving a demonstrated problem?
- Could the same goal be achieved by improving an existing system?
- Is the feature required for the vertical slice?

---

## 50. Final Production Principle

The concept artwork represents the eventual fantasy, not the initial implementation target.

Build in this order:

1. Make one automatic punch feel good.
2. Make a small fight enjoyable to watch.
3. Give the player one meaningful intervention.
4. Turn the fight into a complete run.
5. Add build-defining equipment.
6. Add route-shaping cards.
7. Add content and presentation.

Do not build a large content library around an unproven combat loop.

The project succeeds when a player can watch the crew fight, make a small number of high-impact decisions, and feel responsible for the increasingly chaotic machine operating on the screen.
