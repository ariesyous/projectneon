# Product Research: Readability, Agency, and the Roguelite Loop

Status: research synthesis; recommendations are proposals, not specification
Prepared: 2026-08-20

## Research question

What patterns let an indirect-control or auto-combat roguelite remain readable, consequential, varied, and satisfying across a full run—and what should Neon Loop adopt without losing its street-patrol identity?

The pass focused on products with at least two of these traits: automated combat, build construction, route or event planning, run-based escalation, and limited tactical intervention. It also reviewed interface and accessibility guidance for communicating dense game state.

## Owner evidence

The August owner playtest is the highest-priority qualitative evidence for this rebaseline. It found that the current build is fun, while also identifying:

- unclear idle/waiting states and an indistinct shop phase;
- a confusing card/route interaction;
- choices whose consequences are not sufficiently visible;
- a text-heavy, spartan interface with few meaningful icons;
- unclear lane, dot, and background presentation;
- insufficient intervention and encounter variety;
- weak run repetition and roguelite identity;
- insufficient visual and interaction polish;
- a preference for all crew to be available by default.

This means Milestone 6 remains technically implemented and tentatively released, but it has not earned final owner experience acceptance.

## Comparable patterns

| Reference | Relevant product pattern | Lesson for Neon Loop |
|---|---|---|
| Loop Hero | The player expands a deck and places terrain, buildings, and enemies around a repeating expedition loop. | A literal loop works when each placement has an understandable effect on a future pass. The loop itself must be visible and mechanically meaningful. |
| The Last Flame | Build and positioning decisions occur between auto-battles; combat demonstrates whether the strategy worked. | Separate a calm preparation decision from a short combat payoff. Do not make the player parse the full build system during combat. |
| He Is Coming | The next boss arrives on an explicit clock; day/night risk, campfires, items, and exploration make “prepare or push” legible. | Always show the next major threat and make the risk of continuing concrete. |
| Backpack Battles | Buying and spatially arranging items is the primary agency; automated battles validate the arrangement. | If combat is automatic, build changes must produce obvious behavioral or visual differences in the very next fight. |
| Slay the Spire | Each node is one focused choice; route risk and reward are visible; card/relic interactions create run identity. | Present one decision at a time and reveal its likely consequence before confirmation. |
| Balatro | A small action is supported by game-changing modifiers, strong audiovisual payoff, and readable score consequences. | “Juice” is not decoration: it teaches the player what mattered and makes a build feel powerful. |
| Into the Breach | Enemy intent is fully telegraphed before the player acts. | Complex or automated behavior feels fair when intent and consequence are visible early enough to respond. |
| Despot's Game | The player prepares a squad, then watches it auto-fight through paths, shops, and events; runs reset on failure. | A run needs a crisp alternation of preparation, execution, reward, and route risk. |

### Sources

- [Loop Hero overview](https://playdigious.helpshift.com/hc/en/19-loop-hero/faq/215-what-is-loop-hero-about/)
- [The Last Flame](https://store.steampowered.com/app/1830970/The_Last_Flame/)
- [He Is Coming](https://www.chronocle.com/he-is-coming)
- [Backpack Battles](https://game.shochiku.co.jp/games/backpack-battles/)
- [Slay the Spire](https://store.steampowered.com/app/646570/Slay_the_Spire/?l=english)
- [Balatro](https://www.playbalatro.com/)
- [Into the Breach](https://www.subsetgames.com/itb.html)
- [Despot's Game](https://play.google.com/store/apps/details?id=com.KonfaGames.DespotsGame)

## UX and game-feel evidence

Microsoft's game accessibility guidance recommends reinforcing important information through more than color alone—for example, image plus text or symbol plus color—and calls out the frustration of maps that rely on color-only markers. Nielsen Norman Group guidance supports familiar icons with labels, appropriately sized targets, and motion used to explain state or relationships rather than as constant ornament. Game Developer's summary of a GDC game-feel session identifies animation, sound, screen shake, and particles as contributors to a more satisfying response.

These sources support the owner's observation that replacing prose with unlabeled icons would not be enough. Neon Loop needs a consistent icon-plus-label language, stronger hierarchy, clearer state transitions, and audiovisual acknowledgement of meaningful outcomes.

Sources:

- [Microsoft: Accessibility for games](https://learn.microsoft.com/en-us/windows/uwp/gaming/accessibility-for-games)
- [Nielsen Norman Group: Tablet Website and Application UX](https://media.nngroup.com/media/reports/free/Tablet_Website_and_Application_UX.pdf)
- [Nielsen Norman Group: Animation for attention and comprehension](https://www.nngroup.com/articles/animation-usability/)
- [Game Developer: Understanding why your game feels bad](https://www.gamedeveloper.com/design/video-understanding-why-your-game-feels-bad-and-how-to-fix-it-)

## Findings

### 1. The core issue is experience structure, not content count

The current build exposes combat, route planning, hand state, equipment, synergies, Heat, Night Pressure, interventions, rewards, and progression in overlapping presentation layers. Adding more cards, equipment, or enemies would increase cognitive load without fixing the player's uncertainty about what is happening now and why it matters.

Recommendation: rebuild the experience around a repeated and visibly labeled sequence:

`PLAN → FIGHT → INTERVENE → COLLECT → PUSH / EXTRACT`

### 2. Automatic combat needs stronger authored agency around it

Auto-combat succeeds when the player can form a hypothesis during preparation, recognize it during execution, and intervene at a decisive moment. Neon Loop currently has those ingredients, but their causal chain is visually weak.

Recommendation: every significant choice must visibly alter at least one of the next encounter's behaviors, risks, rewards, or intervention opportunities. Show the change before confirmation and acknowledge it during combat.

### 3. The next threat should never be a mystery

Unannounced waiting reads as inactivity. An explicit “next block” card, short countdown, enemy-intent preview, or phase banner turns the same time into anticipation.

Recommendation: the combat HUD always answers three questions without opening a panel:

- What phase am I in?
- What happens next, and when?
- What can I do right now?

### 4. District Cards are solving too many presentation problems at once

The current persistent hand, five future route slots, drag behavior, validity states, Heat effects, and route history create a high learning cost before the player can make a basic route choice.

Recommendation: prototype District Cards as a focused between-block decision. Offer a small number of large, illustrated choices with title, icon, one-line outcome, Heat change, and reward/risk. Selecting a card defines the next block. Click/tap is primary; drag may remain as an optional flourish. Remove the persistent combat hand and abstract future-slot planner unless testing proves that its strategic value justifies its complexity.

### 5. A loop needs a recurring escalation and a meaningful exit

A geometric patrol path is not enough. A roguelite loop is felt when the player repeatedly improves a run build, faces rising risk, and decides whether to bank progress or continue.

Recommendation: organize a run into escalating district laps. Each lap contains a handful of blocks, culminates in a major threat or modifier, and ends with an explicit extract-or-push decision. Continuing changes the district and reward quality; extraction protects the completed result. A boss concludes the final committed lap.

### 6. Variety should be systemic and legible

More buttons alone will recreate the same clutter. Variety should come from a small set of interactions that combine with encounters and builds.

Recommendation: keep indirect control and add a coherent intervention vocabulary—for example environmental opportunities, target priority, defensive rally, and temporary backup. Each should have a distinct icon, silhouette, validity rule, sound, and enemy counter.

### 7. Meta-progression should expand possibility, not withhold the premise

The three crew members are a core expression of the game, and the owner wants them available by default. Locking core play styles behind first-completion rules delays experimentation and makes the opening product feel smaller.

Recommendation: unlock Jax, Zoey, and Rex from first launch. If progression is retained, use it for new equipment/card/event pools, cosmetics, difficulty modifiers, and challenge variants rather than permanent stat power. This requires an approved specification change.

## Product risks

- **Over-scoping the rework:** Adding content before the new loop is tested could produce a larger but still confusing game.
- **Trading text overload for icon ambiguity:** Icons should be paired with short labels until repeated use makes them familiar.
- **Direct-control creep:** Too many intervention buttons would undermine the build-and-watch premise.
- **False consequence:** A reward preview can be clear yet remain numerically trivial. Choices need both readable presentation and meaningful balance impact.
- **Permanent-progression pressure:** Stat upgrades can make early runs feel intentionally weak and complicate deterministic balance.
- **Route abstraction relapse:** A visually improved version of the current five-slot planner may retain the same conceptual burden.

## Research conclusion

Neon Loop should not begin with a content expansion. It should first establish a legible run rhythm, a focused decision screen, a minimal combat HUD, obvious build payoffs, and a real lap-level risk decision. Once that spine is enjoyable using a small content set, interventions, encounters, and visual polish can expand it safely.
