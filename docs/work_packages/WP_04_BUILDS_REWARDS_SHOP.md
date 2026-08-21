# WP04 — Builds, Rewards, and Shop

Status: proposed; requires completed WP02 and WP03
Branch suggestion: `codex/wp-04-build-consequence`

## Outcome

Make equipment, synergy, reward, and shop decisions visibly consequential in the next fight and easy to compare before confirmation.

## Required work

1. Audit all existing equipment, synergy thresholds, reward tiers, starting builds, and shop stock against the WP00 choice-consequence standard.
2. Identify hidden, marginal, dominant, or redundant effects with deterministic scenario evidence.
3. Rebalance only the approved content set so representative choices alter attack behavior, target strategy, survival, status cadence, environmental play, or intervention economy at noticeable magnitudes.
4. Give each item and synergy a clear icon/category, short promise, exact detail view, and in-combat proc/activation feedback.
5. Present reward/shop comparisons as explicit before/after changes, including outgoing item, destination, activated/deactivated synergy, and next-fight consequence.
6. Make shop entry, finite stock, affordability, purchase result, decline, and exit unmistakable.
7. Preserve active/backpack semantics, lossless staged replacement, Skip Gear, deterministic equipment selection, and exact reward accounting.
8. Validate at least three viable and visibly distinct build identities across crew choices.

## Out of scope

- item rarity, affixes, sets, salvage, selling, or a broad economy;
- permanent stats or grind;
- a large equipment content expansion;
- card redesign or new encounter mechanics;
- using UI as the inventory or reward authority.

## Acceptance gate

- Every offered choice clearly previews its destination and material next-fight effect.
- At least three viable builds differ in behavior and presentation, not just total damage.
- Testers can explain representative selection/rejection decisions and recognize activated synergies during combat.
- No universally dominant starter/build appears in the approved scenario matrix.
- Full inventory, replacement, swap, storage, discard, skip, affordability, and stale-token paths remain lossless and exact.
- Equipment/reward streams, restart, summaries, and cumulative tests remain deterministic and clean.
- Shop state is visually and interactively unmistakable.

## Recommended parts

### Part A — Consequence audit and balance proposal

Produce scenario data and obtain owner approval for changes that materially alter authored values or effects.

### Part B — Reward/shop comparison experience

Implement the focused choice, before/after, synergy, stock, and feedback presentation.

### Part C — Build expression and validation

Add combat acknowledgements, run the three-build matrix, and repair dominance or invisibility.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Implement the owner-approved WP04 Builds, Rewards, and Shop in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline and WP01–WP03 handoffs, then this complete work-package file. First create a deterministic consequence audit of every existing item, synergy, reward tier, starter, and shop path; separate presentation failures from balance failures and stop for owner approval before materially changing authored effects or values.

Then implement the approved balance changes and icon-plus-label/before-after presentation while preserving SynergySystem, RewardDirector, and cooling/shop authority; active/backpack semantics; staged lossless replacement; Skip Gear; stable ordering; and isolated equipment/rewards streams. Do not add rarity, selling, permanent power, or broad content. Demonstrate three behaviorally and visually distinct viable builds, exercise every changed input and full-inventory/shop path, launch /GameRun, inspect fresh output, run affected and cumulative tests, perform proportionate Windows/Web checks, capture evidence, and update owned docs/catalog. Preserve unrelated Godot-AI changes. Stop at the WP04 acceptance gate; do not commit, publish, or start WP05 unless asked.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP04 Builds, Rewards, and Shop without stopping until the owner-approved consequence audit and balance changes are implemented; every equipment/reward/shop choice shows an exact before/after and meaningful next-fight consequence; at least three viable builds have distinct behavior and readable combat expression; full inventory, replacement, backpack, skip, stock, affordability, stale-token, summary, restart, and deterministic stream contracts pass; shop state is unmistakable; all cumulative/runtime/platform checks and evidence/documentation are complete; and unrelated changes remain intact. Pause for owner approval before changing authored balance, and do not begin another package or publish externally.
```
