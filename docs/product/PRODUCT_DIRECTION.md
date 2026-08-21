# Proposed Product Direction

Status: owner approval required
Prepared: 2026-08-20

## North star

**Neon Loop is a run-based neon-street auto-brawler where the player plans the next block, watches the crew execute the build, intervenes at decisive moments, and chooses whether to bank gains or push through another increasingly dangerous district lap.**

The game should feel strategic before combat, readable during combat, and satisfying immediately after combat.

## Player promise

Every two or three minutes, the player should be able to say:

- what they chose;
- how that choice changed the fight;
- what threat is coming next;
- why they are pushing onward or extracting.

If the player is waiting, the game must turn that time into anticipation with a visible next event, countdown, telegraph, or meaningful observation. It must never look stalled.

## Core verbs

1. **Plan** — choose the next block and understand its risk and reward.
2. **Build** — equip effects that visibly change crew behavior and synergies.
3. **Watch** — read automatic combat, enemy intent, and build payoff.
4. **Intervene** — use a small number of decisive tactical actions.
5. **Push or extract** — accept escalating risk or bank the run result.

## Proposed nested loop

Target timings are hypotheses to validate in WP00/WP02, not final balance values.

### Encounter loop: roughly 20–45 seconds

1. A short fight intro names the threat and relevant modifier.
2. The encounter begins promptly; any spawn delay is represented by an arrival countdown or visible approach.
3. The player's build runs automatically.
4. Enemy intent and environmental opportunities are telegraphed.
5. The player uses zero to two meaningful interventions.
6. The result and decisive causes receive a short audiovisual payoff.

### Block loop: roughly 45–90 seconds

1. Present one focused choice: next district block, reward, shop, or event.
2. Preview immediate consequences.
3. Resolve the block encounter or utility outcome.
4. Award one understandable improvement or resource outcome.
5. Show the next threat and progress toward the lap decision.

### District-lap loop: roughly 2–3 minutes

1. Complete three or four blocks.
2. Face an elite, hazard, or lap modifier.
3. Reach a clear **Extract** or **Push Deeper** decision.
4. Pushing changes the district's look, enemy behavior, reward quality, and pressure.

### Run loop: initial target of 8–12 minutes

1. Select any of the three crew members, all available by default.
2. Build through escalating laps.
3. Extract to secure a completed run or commit toward the final boss.
4. End with a concise summary that connects choices, build, and outcome.
5. Reset run power; retain only approved breadth, cosmetic, or challenge progression.

## Moment-to-moment information architecture

### Combat layer: only actionable information

The default HUD should show:

- crew identity and health;
- Heat and Night Pressure, with distinct shapes and labels;
- current phase and next event/countdown;
- coins or the one immediately spendable resource;
- available interventions with icon, input, charges, and cooldown;
- a compact build/synergy summary that expands on focus or inspect.

Cards, backpack management, detailed effect prose, route history, and shop stock should not compete with combat unless they are currently actionable.

### Focused decision layers

Planning, reward, equipment, and shop decisions should temporarily own attention. Each layer should have:

- one clear heading and one-sentence instruction;
- a small number of large choices;
- icon plus short label;
- exact consequence or before/after comparison;
- one visually dominant confirm action;
- one safe decline/back action when the system permits it.

### Progressive disclosure

The first view communicates category and consequence. Hover, focus, long-press, or an inspect action reveals exact rules. The game should not rely on paragraphs to explain what an icon, state label, spatial grouping, and preview can communicate together.

## District Cards: proposed redesign

Rename the interaction layer in player-facing copy to **District Plan** while retaining stable internal IDs where safe.

### Recommended model

- At the end of a block, offer two or three large District Cards.
- Each card represents the next block, not an abstract future slot.
- The face shows illustration/icon, location name, encounter/event type, reward, Heat change, and one short special rule.
- Selecting a card updates a small “Next Block” preview; confirming begins it.
- Click/tap/keyboard selection is primary. Drag can be retained as an optional equivalent, not the tutorial's foundation.
- Resolved blocks become a simple visual trail around the district lap; they are history, not editable slots.
- Advanced future planning can return later only if playtests show that players understand the base loop and want more lookahead.

### Why this direction

It preserves the authored district-card identity and deterministic content while eliminating simultaneous hand management, route-slot legality, abstract occurrence IDs, and combat-time placement. It also turns an invisible wait into an explicit plan/fight transition.

## Choice consequence standard

Every choice must pass all four checks:

1. **Preview:** The player can state what will change before confirming.
2. **Magnitude:** The change is large enough to affect a reasonable next-fight decision or observation.
3. **Expression:** Combat presentation makes the effect recognizable through behavior, iconography, text, and/or audiovisual feedback.
4. **Recall:** The reward/result screen briefly names the effect that mattered.

Examples:

- an equipment item changes attack pattern, target priority, status cadence, survival plan, or an intervention—not only a small hidden percentage;
- a District Card changes encounter composition, rule, environmental opportunity, reward, or pressure—not only background flavor;
- a shop purchase shows the outgoing/incoming item, activated synergy, and next-fight effect;
- a push decision previews the new lap modifier, reward tier, and next major threat.

## Intervention vocabulary

Keep the permanent combat bar small. A proposed initial vocabulary is:

- **Environment:** context-sensitive street object such as Hydrant, power box, barrier/dumpster, or hanging sign. Only valid objects appear; the button adopts that object's icon and verb.
- **Focus:** briefly prioritize a telegraphed enemy or interruptible threat.
- **Rally:** a defensive or repositioning response with a clear cooldown.
- **Backup:** finite run resource for a larger tempo swing.

Not all four need to ship in the first prototype. WP05 should test the smallest combination that produces varied decisions without turning the game into an action game.

## Encounter variety model

Build variety from combinations rather than raw count:

- enemy role composition: swarm, heavy, ranged pressure, elite disruption;
- one visible district rule or hazard;
- one or two context-sensitive intervention opportunities;
- the player's crew/build identity;
- an explicit reward/risk modifier.

Each encounter gets a readable title card and a single-line tactical cue. New enemies or hazards are added only when they create a new decision, not merely a new sprite or stat profile.

## World and stage presentation

The logical lanes can remain an implementation detail, but release presentation should not expose lane dots or debug markers.

Replace them with an authored street scene whose gameplay bands are communicated through:

- curb, sidewalk, asphalt, crosswalk, storefront, and alley geometry;
- perspective, shadows, occlusion, and spawn entrances;
- readable enemy silhouettes and telegraph shapes;
- restrained navigation indicators that appear only when needed;
- lap-to-lap changes in lighting, weather, signage, hazards, or crowd dressing.

The player should perceive “a fight on a city block,” not “actors moving between debug coordinates.”

## Visual language

Create a small reusable system before polishing individual screens:

- typography scale and maximum line lengths;
- surface, border, spacing, and focus tokens;
- semantic colors reinforced by shapes and labels;
- one icon family for state, resource, card type, equipment tag, and intervention;
- character portraits and equipment/card key art at the sizes actually used;
- transition grammar for PLAN, FIGHT, REWARD, SHOP, EXTRACT, BOSS, and RESULT;
- motion and audio reserved for state changes, consequences, and successful actions.

Icons are never the sole carrier of unfamiliar meaning. New icons ship with labels/tooltips and are validated for grayscale, color-blind accessibility, keyboard focus, touch size, and 1280 × 720 fit.

## Roguelite progression direction

### Available from first launch

- Jax, Zoey, and Rex;
- the complete core loop;
- enough equipment, cards, events, and interventions to create at least three distinct builds;
- extraction and boss paths.

### Valid longer-term unlocks

- additional equipment, District Cards, events, hazards, and encounter modifiers;
- cosmetic variants;
- challenge mutators or higher-risk district contracts;
- compendium knowledge and optional goals.

### Avoid

- permanent stat trees;
- withholding core crew play styles;
- grind required to make early runs viable;
- random-schema changes without a documented compatibility need;
- meta systems that obscure whether a build or permanent power caused success.

## Product principles

1. One meaningful decision owns the screen at a time.
2. The next threat is always visible.
3. Every major pick changes the next fight.
4. Combat is the payoff for planning, not a dashboard-management phase.
5. Each lap changes risk, reward, and atmosphere.
6. Important information uses icon, label, shape, and feedback—not color or prose alone.
7. Debug affordances are invisible in release presentation.
8. Add content only when it creates a new decision or a new readable build expression.

## Explicit non-goals for this rebaseline

- direct character movement or action-combat controls;
- multiplayer;
- an open world or procedural city map;
- permanent stat progression;
- a large content expansion before the loop prototype passes;
- replacing deterministic gameplay with unseeded variation;
- controller support, localization, achievements, or live-service systems in the rebaseline itself.

## Approval criteria

The owner can approve this direction when the following statements feel true:

- The north star describes the game they want to make.
- The district-lap structure provides the missing “loop.”
- The focused District Plan is preferable to the current persistent hand/future-slot planner.
- All crew should be immediately selectable.
- Breadth/cosmetic/challenge unlocks are preferable to permanent stats.
- The proposed intervention vocabulary preserves the desired amount of indirect control.

Approval should be recorded in WP00 before implementation begins.
