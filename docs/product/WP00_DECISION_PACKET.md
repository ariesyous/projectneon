# WP00 Owner Decision Packet

Status: **owner-approved**
Prepared: 2026-08-20
Approved: 2026-08-20
Scope: product and architecture rebaseline only; no gameplay implementation

## Decision record

The owner explicitly approved the complete recommended D1–D7 package on 2026-08-20 with “Yeah I approve, proceed.” This packet is now the decision record supporting canonical-document reconciliation.

The recommended package is internally coherent. The alternatives are viable, but selecting an alternative may require adjusting dependent choices before the canonical documents can be updated.

## Recommended package at a glance

1. Use the proposed north star: plan the next block, watch the crew execute the build, intervene decisively, then bank gains or push through escalating district laps.
2. Structure a boss run as three laps of three blocks. Offer **Extract / Push Deeper** after laps one and two; pushing after lap two commits the player to lap three and its boss. Target 8–12 eligible minutes for a boss run.
3. Replace the release-facing persistent hand/five-future-slot planner with a focused **District Plan** offering two next-block cards at a time. Keep a finite four-card, no-duplicate lap deck and rebuild it at each lap boundary.
4. Make Jax, Zoey, and Rex selectable on a fresh production profile. Retire the Zoey/Rex unlock gates prospectively while preserving legacy profile compatibility and historical Milestone 6 records.
5. Permit only breadth, cosmetic, compendium, and challenge progression. Retain Hacker Deck and Gang Hideout as breadth unlocks; do not add permanent stats or a required meta grind. Keep Scrap informational until a separately approved breadth economy exists.
6. Define the permanent combat vocabulary as **Environment**, **Focus**, and **Backup**. Fire Hydrant is one Environment action; Call Backup maps to Backup; Subway Reroute becomes a strategic District Plan/travel action rather than a combat-bar intervention. Rally remains a WP05 prototype candidate, not a promised permanent slot.
7. Adopt the measurable clarity, consequence, variety, replay-desire, timing, and technical metrics in this packet.

## D1 — North star and player promise

### Option A — Plan, watch, intervene, push (recommended)

> **Neon Loop is a run-based neon-street auto-brawler where the player plans the next block, watches the crew execute the build, intervenes at decisive moments, and chooses whether to bank gains or push through another increasingly dangerous district lap.**

Player promise: within each lap, the player can explain what they chose, how it changed the fight, what threat comes next, and why they are extracting or pushing.

Tradeoff: this deliberately makes the district-lap rhythm—not freeform route editing—the primary product identity.

### Option B — Build-first combat machine

Emphasize assembling a powerful crew/build and watching it operate, while treating block planning and extraction as supporting systems.

Tradeoff: closer to the current fantasy language, but it gives less guidance for repairing unclear waiting, route, and phase structure.

### Exact owner question

Approve Option A, choose Option B, or provide replacement wording that explicitly states what the player repeatedly does and why they continue a run.

## D2 — Lap loop, commitment, and target duration

### Option A — Three laps × three blocks (recommended)

```text
SELECT CREW
  -> LAP 1: [PLAN -> BLOCK -> REWARD] x3
  -> EXTRACT or PUSH
  -> LAP 2: [PLAN -> BLOCK -> REWARD] x3
  -> EXTRACT or COMMIT TO FINAL LAP
  -> LAP 3: [PLAN -> BLOCK -> REWARD] x3
  -> BOSS
  -> RESULT
```

- A block is a fight, shop, or authored utility/event outcome selected through District Plan.
- The third block may carry the lap's elite, hazard, or modifier; it does not add a hidden fourth block.
- Lap one extraction target: roughly 2–4 eligible minutes.
- Lap two extraction target: roughly 5–8 eligible minutes.
- Boss-run target: 8–12 eligible minutes.
- The lap-one decision previews the lap-two modifier, reward tier, and next major threat.
- Pushing after lap two is the explicit boss commitment. There is no routine extraction after lap three begins; victory or defeat resolves the committed run.
- Heat remains tactical. Night Pressure remains irreversible and supplies within-lap escalation, but lap boundaries become the player-facing major-risk structure.

Tradeoff: highly legible and testable, but less freeform than pressure-only extraction windows.

### Option B — Four laps × two blocks

More frequent push/extract decisions and atmosphere changes.

Tradeoff: stronger repetition but more interruptions, more transition overhead, and less time for a build choice to express itself before the next major decision.

### Option C — Keep the current pressure-threshold route

Preserve the authored patrol and extraction thresholds without an explicit block/lap lifecycle.

Tradeoff: lowest migration cost, but it does not address the owner's missing-loop and ambiguous-waiting feedback.

### Exact owner question

Approve Option A, choose B/C, or specify the exact number of laps, blocks per lap, extraction points, boss commitment point, and boss-run target.

## D3 — District Plan model

### Option A — Focused next-block choice with a lap deck (recommended)

- At each PLAN phase, show two large District Cards. A third choice appears only if an explicit run effect grants it.
- Each choice shows icon/illustration, location, block type, reward/risk, exact Heat change, and one short special rule.
- Click/tap/keyboard selection is primary. Drag may be an equivalent flourish, never a separate ruleset.
- Confirmation creates exactly one authoritative next-block intent. Invalid, stale, replayed, declined, or transition-race intents mutate nothing.
- The four existing stable IDs and authored identities remain: Arcade, Convenience Store, Gang Hideout, and Subway Entrance.
- Each lap starts with one copy of every currently available card. The offer draws without replacement from the lap deck, keeps no duplicate within one offer, and refills to two choices while cards remain.
- Three block choices consume at most three of the four lap cards. The lap boundary archives the resolved trail and rebuilds the available one-copy deck for the next lap.
- No persistent card hand, editable future slots, slot-validity words, or route-history dots remain in release combat presentation.
- Resolved blocks form a simple lap trail; they are history, not editable route targets.
- `CardSystem` keeps card-offer, revision/token, exact-once, and deterministic `cards`-stream authority. `PatrolController` keeps current block/lap progress and safe boundaries, but its five-slot modification interface becomes legacy/development-only after WP03 migration.

Compatibility note: WP00 does not change random schema version 1. WP03 must lock deterministic vectors before migration and confirm that lap-deck scheduling does not alter the documented seed-derivation/draw primitive. If it does, WP03 must stop for a separately documented schema compatibility decision rather than silently changing the version.

Tradeoff: removes the largest learning burden while preserving card identity and deterministic authority; sacrifices multi-step lookahead.

### Option B — Focused offers with replacement

Offer two or three choices from the full unlocked pool every block, allowing repeated cards within a lap but not within one offer.

Tradeoff: simplest content scaling, but abandons the current finite one-copy/no-reshuffle deck contract and is more likely to require a random-schema compatibility decision.

### Option C — Keep the five-future-slot planner

Retain the hand, placement legality, future occurrence identities, and route modification preview, with a presentation redesign.

Tradeoff: preserves strategic lookahead and implementation, but retains the conceptual load directly identified in the owner playtest.

### Exact owner question

Approve Option A, choose B/C, or specify offer size, reuse/refill rule, lookahead depth, and whether drag is primary or optional.

## D4 — Default crew availability

### Option A — All three from first launch (recommended)

- Fresh production profiles expose Jax, Zoey, and Rex before the first gameplay draw.
- The first-completed-run → Zoey and first-victory → Rex rules are retired for rebaseline runs.
- Existing profiles remain readable. Already recorded unlocks and lifetime facts are not deleted or rewritten.
- WP00 changes documents only. WP02 owns the backward-safe profile/default migration and must not rewrite a save merely because it was loaded.

Tradeoff: immediately exposes the product's three core play styles; removes two simple progression beats.

### Option B — All three plus a guided recommendation

Same availability as A, but Jax is visibly recommended for the first run and the other crew carry concise complexity labels.

Tradeoff: better onboarding with a small risk that “recommended” is perceived as the only valid choice.

### Option C — Preserve crew gates

Tradeoff: lowest migration cost, but directly conflicts with the owner preference and with making the opening premise feel complete.

### Exact owner question

Approve A, choose B/C, or specify a different fresh-profile availability rule. If A is approved, say whether Jax should still be marked “recommended.”

## D5 — Progression boundary

### Option A — Breadth without permanent power (recommended)

Available on first launch:

- all three crew;
- the full run, extraction, and boss paths;
- eight existing equipment entries and three existing District Cards, preserving enough starting breadth for the current three build families.

Allowed unlocks:

- existing Hacker Deck after a completed run containing an elite defeat;
- existing Gang Hideout after extraction;
- future equipment, District Cards, events, hazards, encounter modifiers, cosmetics, compendium entries, and challenge contracts only after separate content approval.

Explicit boundaries:

- no permanent health, damage, cooldown, economy, or drop-rate bonuses;
- no permanent stat tree;
- no grind required to make early runs viable;
- no unlock may hide a core crew style, extraction, or boss access;
- Scrap remains a run-summary/result measure until a separately approved breadth/cosmetic economy defines its use;
- active-run state remains nonsavable.

Tradeoff: retains discovery and goals without corrupting run balance; future breadth still requires content and UX work.

### Option B — All current gameplay content available; cosmetics/challenges only

Expose all three crew, all nine equipment entries, and all four cards immediately.

Tradeoff: cleanest balance and onboarding baseline, but removes the existing unlock proof and most near-term meta progression.

### Option C — Allow permanent stat progression

Tradeoff: stronger long-term power growth, but conflicts with the research direction, obscures build balance, and requires a much larger economy/migration specification.

### Exact owner question

Approve A, choose B/C, or list the exact content/power categories that may be unlocked. Confirm whether Scrap is summary-only for the rebaseline.

## D6 — Permanent intervention vocabulary

### Option A — Environment + Focus + Backup (recommended)

The permanent combat interaction bar has at most three labelled roles:

1. **Environment** — one context-sensitive street object currently valid in the encounter. Fire Hydrant is the first implementation; later objects replace the icon/verb in this slot rather than adding more permanent buttons.
2. **Focus** — temporarily prioritize a telegraphed enemy or interruptible threat. It changes target priority, not direct movement or attacks.
3. **Backup** — the existing finite Call Backup tempo swing.

Classification changes:

- Subway Reroute is strategic travel/District Plan vocabulary, not a permanent combat-bar intervention.
- Rally/reposition remains a WP05 prototype candidate. It is added to the permanent vocabulary only after owner selection from measured prototypes.
- A maximum of zero to two meaningful intervention uses per ordinary fight is a tuning target, not a requirement to click.

Tradeoff: the smallest coherent bar that covers context, precision, and a scarce tempo swing; no dedicated defensive response is guaranteed.

### Option B — Environment + Focus + Rally + Backup

Tradeoff: complete proposed vocabulary, but a four-button bar risks direct-control creep and demands another production mechanic before evidence shows it is needed.

### Option C — Keep Fire Hydrant + Call Backup + Subway Reroute

Tradeoff: preserves the implemented set, but mixes combat and travel semantics and does not create a reusable environment vocabulary.

### Exact owner question

Approve A, choose B/C, or name the permanent labelled roles. Confirm that Subway Reroute should leave the combat bar under A/B.

## D7 — Acceptance metrics

### Recommended measurable gate

Use five unbriefed participants for each qualitative checkpoint. Participants receive only the task prompt being measured; failures are recorded without coaching. Automated evidence cannot satisfy qualitative metrics.

#### Clarity

- **Wireframe/first-use:** at least 4/5 participants independently identify the current phase, next event, currently available action, selected District Card's primary consequence, and the difference between Extract and Push.
- **Playable loop:** at least 4/5 accurately recount `PLAN → BLOCK/FIGHT → REWARD → LAP DECISION` and predict what happens immediately after a confirmed District Plan choice.
- **No dead-looking wait:** every noninteractive delay longer than one second presents a named next event plus countdown, visible approach, or authored transition; testers do not broadly describe a state as stalled or broken.

#### Consequence

- For one District Plan choice, one equipment/shop choice, and one Push decision per observed session, at least 4/5 participants correctly predict the primary change before confirmation and identify its expression in the next applicable fight/result.
- Every shipped major choice passes the four recorded checks: **Preview, Magnitude, Expression, Recall**. A choice with clear copy but no material next-fight effect fails.

#### Variety and intervention quality

- Across at least five representative full sessions spanning all three crew and fixed seeds, at least 4/5 participants name three distinct meaningful decisions from their run.
- At least 4/5 explain one situation where using an intervention was strong and one where holding it or choosing another action was better.
- Every permanent intervention has a documented strong case, weak case, invalid case, and readable counter/tradeoff; no action is the correct on-cooldown choice across the approved encounter matrix.
- At least three viable builds differ in behavior and presentation, not only total damage, and no universally dominant starter/build appears in the approved fixed-seed scenario matrix.

#### Replay desire

- After the result screen and before prompting, at least 4/5 participants either start another run or explicitly state that they want another run.
- At least 3/5 name a concrete different next-run intention: another crew, build, District Plan choice, intervention approach, or push/extract strategy.

#### Timing and cadence

- Ordinary fight: target 20–45 eligible seconds.
- Complete block including its focused decision and reward: target 45–90 eligible seconds.
- Lap decision: target every 120–180 eligible seconds.
- Boss run: target 8–12 eligible minutes; lap-one extraction roughly 2–4, lap-two extraction roughly 5–8.
- Optional coin-cluster opportunities retain the 10–20 eligible-second ambient target and full passive base reward.
- The old generic “strategic decision every 30–60 seconds” target is superseded by the 45–90-second block target; it is not relabelled as a pass by counting coin clicks.

Timing bands are tuning targets across representative traces, not a rule that every deterministic gap must fit. WP07 records distributions, outliers, and owner-accepted exceptions rather than passing on averages alone.

#### Technical and compatibility

- No UI scene becomes gameplay authority.
- Heat/Night Pressure separation, safe-boundary precedence, exact-once tokens, deterministic stable ordering, named-stream isolation, restart/cleanup, and same-build reproduction remain verified.
- Random schema version remains 1 unless a later package demonstrates an incompatible semantic change and receives a separate documented decision.
- All changed input paths retain mouse, keyboard, and touch parity as approved; all important state uses icon plus label/shape and never colour alone.
- WP00 itself changes documentation/wireframes only, touches no gameplay code or save/external state, and preserves unrelated Godot-AI/project changes.

### Lighter alternative

Use 3/5 qualitative thresholds and accept stated replay interest without a concrete alternate-run plan.

Tradeoff: easier early iteration, but too weak for the roadmap's final release acceptance and less diagnostic when the sample is only five people.

### Exact owner question

Approve the recommended measurable gate, choose the lighter gate, or change the exact denominator, thresholds, timing bands, or replay behavior.

## Representative wireframes

The low-cost wireframes are decision evidence, not final art direction:

- [Wireframe overview (PNG)](wireframes/wp00_wireframes.png)
- [Editable wireframe source (SVG)](wireframes/wp00_wireframes.svg)
- [Wireframe notes](wireframes/README.md)

They cover the minimal combat HUD, District Plan, reward/equipment decision, shop, lap-end Push/Extract decision, and run summary. Each frame gives one decision primary visual weight and pairs every unfamiliar symbol with a short label.

## Milestone 6 conflict and migration map

| Current canonical contract | Rebaseline conflict | Post-approval treatment | Future owner |
| --- | --- | --- | --- |
| Milestone 6 is the stopping boundary; no future milestones/packages are authorized. | The proposed WP01–WP07 roadmap is post-M6 work. | Preserve M0–M6 history and technical evidence; supersede only the prospective stopping-boundary language with the approved work-package roadmap. | Product docs, `GameSpecifications.md`, `AGENTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md` |
| Core loop is patrol-route/encounter progression governed by Heat/Night Pressure thresholds. | The approved player-facing spine becomes blocks and district laps with explicit decisions. | Keep Heat, Night Pressure, deterministic selection, and safe boundaries as authorities; add block/lap lifecycle contracts and presentation phases without rewriting historical M3/M6 verification. | `RunDirector`, `RunFlowController`, `PatrolController` in WP02 |
| Extraction windows latch at Night Pressure 18/36; boss at 50. | Player-facing extraction moves to lap-one/lap-two decisions and lap-two boss commitment. | WP00 documents the approved experience. WP02 maps or retunes thresholds behind explicit lap decisions and proves precedence. No gameplay value changes occur in WP00. | WP02 |
| Four-card one-copy run deck, opening hand two, capacity three, no reshuffle; cards are placed into five future route slots. | Focused next-block choices need three choices per lap and no combat-time legality planner. | Keep four stable card IDs, two-choice deterministic offers, lap-scoped one-copy deck, exact-once/revision authority, and resolved trail; deprecate release-facing hand/future-slot UI after tested migration. | `CardSystem`, `PatrolController`, `GameHUD` in WP03 |
| Production starts with Jax; Zoey unlocks after any completed run; Rex after victory. | All three crew must express the premise on first launch. | Fresh profiles expose all three. Legacy unlock facts remain readable; gates are retired prospectively. Save migration/code waits for WP02. | `AppState`, profile defaults/access snapshot in WP02 |
| Four exact unlock rules include Zoey, Rex, Hacker Deck, and Gang Hideout. | Two crew rules conflict; progression must not withhold core styles. | Retire only Zoey/Rex gates under recommended D5. Preserve Hacker Deck/Gang Hideout breadth gates. Keep history and existing IDs. | WP02/profile docs |
| The exact three interventions are Fire Hydrant, Call Backup, and Subway Reroute. | Subway is strategic travel while the new combat vocabulary needs reusable roles. | Preserve exact implemented M6 behavior as historical. Prospectively classify combat roles as Environment/Focus/Backup; move Subway to District Plan/travel vocabulary; prototype Rally before any promise. | WP02/WP03 classification, WP05 mechanics |
| HUD simultaneously presents route/cards, build detail, interventions, progression, and combat. | Research requires actionable combat HUD plus focused decision layers. | Minimal combat HUD becomes canonical presentation goal; detailed cards/inventory/shop own attention only when actionable. | WP01 |
| Generic cadence targets are ambient 10–20, strategic 30–60, major 120–180 seconds. | Proposed blocks target 45–90 seconds and laps 120–180; old strategic band cannot describe the new phase rhythm. | Retain coin ambient 10–20 and major 120–180. Supersede generic strategic 30–60 with block 45–90 and record distributions rather than average-only passes. | `TEST_PLAN.md`, cadence docs; runtime tuning WP02/WP07 |
| M6 final owner acceptance is pending under `MILESTONE_6_PLAYTEST.md`. | The August owner playtest rejected final experience acceptance and initiated a rebaseline. | Do not claim M6 technical failure. Keep the tentative-release record historical; state that the rebaseline, not the old M6 playtest TODO list, governs future product acceptance after approval. | Canonical docs and playtest record note |
| Random schema version 1 and seven named streams are fixed. | Card/lap scheduling changes draw timing and requires compatibility scrutiny. | WP00 changes no schema. Preserve stream names/derivation; WP03 locks vectors and stops if it discovers an incompatible semantic change. | WP03 |
| Current shop is finite Heat cooling stock. | New shop wireframe implies a focused choice layer and visible before/after consequences. | Keep current stock/economy as implemented until WP04 consequence audit; do not invent selling, rarity, or broad economy in WP00. | WP04 |
| Summary is comprehensive but primarily statistical. | New promise requires recall of decisive choices and a clear next-run intention. | Preserve exact authoritative metrics; add concise cause/build/highlight presentation and progressive disclosure later. | WP01/WP02/WP07 |

## Canonical reconciliation record

After approval, WP00 Part B updated only product/engineering documentation and wireframe evidence:

- `GameSpecifications.md`: added the approved rebaseline as the prospective product source of truth and precisely marked superseded M6 product rules while retaining historical milestone evidence.
- `AGENTS.md`: replaced the no-future-work boundary with the approved WP roadmap and recorded unchanged engineering/determinism/owner-change rules.
- `ARCHITECTURE.md`: added the target authority/migration map without pretending unimplemented WP02/WP03 behavior already exists.
- `IMPLEMENTATION_PLAN.md`: made WP00 complete and WP01–WP07 the approved prospective sequence while retaining milestone histories.
- `TEST_PLAN.md`: added the approved qualitative/timing metrics and evidence protocol while preserving exact historical results.
- `CONTENT_CATALOG.md`: recorded approved fresh-profile availability and future classification separately from currently implemented content until the owning package lands.
- `CHANGELOG.md`: appended the documentation-only rebaseline and owner decision without rewriting past entries.
- `docs/product/README.md`, `PRODUCT_DIRECTION.md`, and `ROADMAP.md`: changed proposal statuses after approval and aligned the exact selected choices.
- `docs/work_packages/WP_00_PRODUCT_REBASELINE.md`: recorded the owner decision and WP00 evidence status after Part B verification.

No gameplay script, scene, Resource, test implementation, project setting, profile/save file, Git history, branch, commit, publication, deployment, or external state is authorized by WP00.

## Historical approval response template

The owner may approve the coherent recommended package with:

```text
Approve WP00 recommended package D1–D7. Jax recommendation: yes/no.
```

Or respond decision by decision:

```text
D1: A/B/custom
D2: A/B/C/custom
D3: A/B/C/custom
D4: A/B/C/custom; mark Jax recommended: yes/no
D5: A/B/C/custom; Scrap summary-only: yes/no
D6: A/B/C/custom; move Subway off combat bar: yes/no
D7: recommended/lighter/custom
```

This prerequisite was satisfied on 2026-08-20. Canonical documentation was then reconciled without gameplay, project-setting, save/profile, Git-history, publication, deployment, or other external-state changes. See [WP00 acceptance evidence](WP00_ACCEPTANCE_EVIDENCE.md).
