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
- Coins and equipment burst from defeated enemies
- The player clicks environmental objects at decisive moments
- Build synergies visibly alter combat
- Heat steadily increases the danger
- The player chooses whether to push deeper or escape safely

---

## 4. Design Pillars

### 4.1 Build It, Then Watch It Work

The player’s choices should visibly alter what happens during combat.

Equipment, synergies, route cards, and interventions must produce observable changes rather than invisible statistical improvements only.

### 4.2 Frequent Meaningful Decisions

The game may contain automatic action, but the player should not feel passive.

During an active run, the player should receive a meaningful decision or interaction approximately every 20–40 seconds.

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

The player should understand that remaining in the district is profitable but increasingly risky.

### 4.5 Readable Systems

The player should be able to understand why something happened.

Tooltips, icons, status indicators, and debug tools must expose:

- Current Heat
- Current synergies
- Equipment effects
- Active status effects
- Encounter difficulty
- Intervention cooldowns
- Extraction reward multiplier

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
- Six equipment items
- Three synergy categories
- Four district cards
- One shop interaction
- One complete run summary
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
- At least one optional clickable interaction approximately every 10–20 seconds
- One substantial choice approximately every 30–60 seconds
- One major risk decision approximately every 2–3 minutes

### 7.3 Desired Emotional Arc

**Start:** Quiet, understandable, controlled  
**Middle:** Busy, increasingly powerful, increasingly risky  
**Late run:** Chaotic, spectacular, dangerous  
**End:** Relief, satisfaction, or regret

---

## 8. Core Gameplay Loop

1. Start a run at the crew hideout.
2. Select one starting crew member.
3. Enter the district with one basic equipment item.
4. Crew automatically follows the patrol route.
5. Enemies spawn as scheduled encounters.
6. Crew automatically targets and fights enemies.
7. Defeated enemies drop coins and may generate rewards.
8. Heat rises over time and through dangerous actions.
9. At reward moments, the player chooses upgrades or cards.
10. The player may activate interventions during combat.
11. The player may add crew members and equipment during the run.
12. At extraction windows, the player may leave with secured rewards.
13. If the player continues, enemy strength and rewards increase.
14. At maximum progression, the boss encounter begins.
15. The run ends in victory, extraction, or defeat.
16. A run summary displays the result and earned unlock currency.
17. The player may immediately begin another run.

---

## 9. Input Model

The vertical slice is designed primarily for mouse and keyboard.

### Mouse

- Left click: select buttons, cards, upgrades, and environmental objects
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
- Run timer
- Current night label

**Top-right**

- Coins
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
- Damage numbers

**Right side**

- Equipment and synergy summary
- Active synergy thresholds
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
- Coin drop
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

The `RunDirector` schedules encounters using encounter definitions.

Each encounter definition contains:

- ID
- Display name
- Spawn budget
- Allowed enemy types
- Spawn positions
- Maximum concurrent enemies
- Heat requirement
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
- Rewards are generated
- The next route node becomes active

---

## 19. Heat System

Heat represents escalating danger and reward.

### 19.1 Heat Range

- Minimum: 0
- Maximum: 100

### 19.2 Heat Gain

Heat increases through:

- Passage of time
- Completing fights
- Playing dangerous district cards
- Triggering elite encounters
- Remaining after an extraction window

### 19.3 Heat Reduction

Heat may decrease through:

- Convenience store card
- Specific shop purchase
- Subway reroute
- Extraction

### 19.4 Heat Tiers

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

- Boss encounter begins
- Extraction unavailable until the boss encounter resolves

### 19.5 Initial Tuning

Starting values may use:

- Passive Heat gain: 1 point every 6 seconds
- Standard encounter completion: +4 Heat
- Elite encounter completion: +8 Heat
- Dangerous card: +10 to +20 Heat
- Cooling card: -10 to -20 Heat

All Heat values must be data-driven.

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

Each crew member has:

- Weapon slot
- Gear slot
- Tech slot

The vertical slice may simplify this to any three generic slots during early milestones.

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

### 21.3 Equipment Rules

- Effects must be defined in Resources where practical.
- UI must display all tags and major effects.
- Replacing equipment must immediately recalculate synergies.
- Equipment must not directly manipulate UI nodes.
- Equipment triggers must use shared effect interfaces rather than item-specific combat branches where practical.

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
- Allows one purchase

#### Gang Hideout

- Adds an elite encounter
- Heat change: +20
- Reward: guaranteed equipment choice

#### Subway Entrance

- Reroutes the next route segment
- Heat change: -15
- Skips one standard encounter
- Cannot skip boss progression requirements

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

### Choice Presentation

A reward choice should usually display three options.

Each option must include:

- Name
- Icon
- Short description
- Relevant tags
- Numerical values where useful
- Current synergy impact preview

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

### Scrap

Represents secured progression currency.

Scrap is awarded based on:

- Encounters completed
- Heat reached
- Elites defeated
- Boss victory
- Extraction timing

The vertical slice may display Scrap totals without implementing a large permanent upgrade system.

---

## 26. Extraction

Extraction is the central risk-versus-reward decision.

### Extraction Windows

Extraction becomes available:

- At a designated route node
- After selected milestone encounters
- Before maximum Heat

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

- Heat increases
- Reward multiplier increases
- Future encounters become harder
- The next extraction opportunity occurs later

### Boss Restriction

At Heat 100 or during the boss encounter, extraction is unavailable.

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
- Maximum Heat reached
- Enemies defeated
- Elites defeated
- Boss defeated
- Coins collected
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
- Boss warning near maximum

### 30.4 Card UI

Cards must show:

- Name
- Art or placeholder
- Cost
- Heat effect
- Node effect
- Tags
- Valid placement feedback

### 30.5 Synergy UI

The synergy panel must show:

- Tag name
- Current count
- Required threshold
- Active effect
- Active or inactive state

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
- Coin pickup
- Card placement
- Intervention activation
- Heat tier increase
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

---

## 34. Core Runtime Systems

### RunDirector

Owns:

- Run state
- Run timer
- Heat
- Route progression
- Encounter scheduling
- Extraction
- Boss trigger
- Win and loss conditions
- Reward multiplier

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

### CardSystem

Owns:

- Draw pile
- Hand
- Discard pile
- Placement validation
- Card resolution

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
spawn_entries: Array[SpawnEntry]
maximum_concurrent_enemies: int
reward_table: RewardTable
elite: bool
boss: bool
```

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
run_started()
run_completed(result)
heat_changed(previous_value, new_value)
heat_tier_changed(previous_tier, new_tier)
route_node_entered(route_node)
encounter_started(encounter_definition)
encounter_completed(encounter_definition)
actor_spawned(actor)
actor_incapacitated(actor)
actor_died(actor)
enemy_defeated(enemy, killer)
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

### Save Requirements

- Save files must be versioned.
- Missing optional fields must receive defaults.
- Corrupt saves must fail safely.
- Development builds should include a reset-save option.

---

## 40. Debugging Tools

A development build must include a toggleable debug overlay.

The overlay should display:

- Current run state
- Run time
- Heat and tier
- Current route node
- Active encounter ID
- Crew state and target
- Enemy state and target
- Current lane
- Reserved attack position
- Active status effects
- Active synergies
- Spawn budget
- Frames per second

### Debug Controls

Development-only controls may include:

- Add 10 Heat
- Reduce 10 Heat
- Spawn basic enemy
- Spawn elite
- Start boss
- Heal crew
- Grant equipment
- Draw card
- Force extraction window
- Restart run

Debug features must be disabled or hidden in release builds.

---

## 41. Testing Requirements

### Unit Tests

Required deterministic test coverage:

- Heat tier calculation
- Damage calculation
- Synergy threshold activation
- Equipment modifier aggregation
- Card placement validation
- Reward table selection
- Target validity
- Save-data migration or defaulting

### Integration Tests

Required integration scenarios:

- Crew acquires and defeats an enemy
- Encounter completes after all enemies are defeated
- Heat reaches a new tier
- Equipment change activates a synergy
- Fire hydrant damages and knocks back valid enemies
- Extraction ends the run
- All crew incapacitated triggers defeat
- Boss defeat triggers victory

### Manual Verification

Every milestone must include a short manual verification checklist.

Visual features require screenshots or recorded evidence during development.

---

## 42. Performance Requirements

Target:

- 60 frames per second at 1080p on a typical modern integrated or low-end dedicated GPU
- No more than 30 active ordinary enemies in the vertical slice
- No unbounded object creation during combat
- Reuse frequently spawned effects through pooling where beneficial
- Avoid per-frame full-scene searches
- Avoid unnecessary allocations in `_process` and `_physics_process`
- Remove or recycle expired damage numbers, projectiles, and effects

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
- Coin drop

### Acceptance Criteria

- Jax automatically acquires a valid enemy.
- Jax approaches and attacks without direct control.
- Enemy can attack Jax.
- Hits occur only during valid attack frames.
- Knockback is visible.
- Dead enemies cannot remain targeted.
- Repeated enemy spawning works without runtime errors.
- Combat remains understandable with five enemies present.

---

## Milestone 2 — Player Intervention

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
- Standard rewards
- Extraction window
- Defeat state
- Boss trigger
- Run summary

### Acceptance Criteria

- A run begins, escalates, and ends.
- Heat visibly changes difficulty.
- Player can extract.
- Player can lose.
- Player can reach the boss.
- Summary accurately reports the result.
- Restart begins a new clean run.

---

## Milestone 4 — Equipment and Synergies

### Deliverables

- Six equipment items
- Equipment UI
- Tag aggregation
- Knockback synergy
- Bleed synergy
- Tech synergy
- Equipment reward choice
- Recalculation when equipment changes

### Acceptance Criteria

- At least three visibly distinct builds are possible.
- Synergies activate at the correct threshold.
- The UI previews whether an item activates a synergy.
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

### Acceptance Criteria

- The game supports a complete 8–12 minute run.
- Each crew member feels distinct.
- At least three build strategies are viable.
- The player receives regular decisions.
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
5. Heat creates observable escalation.
6. Equipment choices visibly change combat.
7. At least one synergy creates an exciting interaction.
8. District cards alter future encounters.
9. The extraction decision creates real tension.
10. The boss provides a clear final test.
11. Run restart is fast and reliable.
12. No critical gameplay system depends on placeholder debug input.
13. The project architecture is documented.
14. Deterministic logic has automated test coverage.
15. The game remains stable over repeated runs.

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

---

## 48. Recommended First Codex Task

Use the following as the first implementation request after this file is added to the repository:

```text
Create the Milestone 0 technical foundation for Neon Loop.

Read GameSpecifications.md in full.

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
- Are interventions meaningful rather than cosmetic?
- Is the player making decisions or only clicking cooldowns?

### Build Construction

- Do equipment choices visibly change behaviour?
- Can the player recognize an emerging build?
- Are synergy thresholds understandable?

### Run Structure

- Does Heat create tension?
- Is extraction a legitimate strategic choice?
- Does the run escalate quickly enough?
- Does the boss feel like the conclusion of the run?

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
