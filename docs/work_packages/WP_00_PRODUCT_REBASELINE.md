# WP00 — Product Rebaseline

Status: proposed; first required package
Branch suggestion: `codex/wp-00-product-rebaseline`

## Outcome

Turn the research proposal into an owner-approved, canonical product plan before production gameplay changes begin.

## Required work

1. Review `docs/product/PRODUCT_RESEARCH.md` and `docs/product/PRODUCT_DIRECTION.md` with the owner.
2. Resolve and record:
   - district-lap structure and target run length;
   - focused next-block District Plan versus future-slot planner;
   - all three crew available from first launch;
   - allowed meta-progression and explicit non-goals;
   - permanent combat intervention vocabulary;
   - success metrics for clarity, consequence, variety, and replay desire.
3. Produce low-cost, representative wireframes for:
   - minimal combat HUD;
   - District Plan;
   - reward/equipment decision;
   - shop;
   - lap-end push/extract;
   - run summary.
4. Map the approved experience onto existing authorities and identify migrations, compatibility risks, and deletions/deprecations.
5. Update the canonical product and engineering documentation only after approval:
   - `GameSpecifications.md`;
   - `ARCHITECTURE.md`;
   - `IMPLEMENTATION_PLAN.md`;
   - `TEST_PLAN.md`;
   - `CONTENT_CATALOG.md` where content availability changes;
   - `CHANGELOG.md`.
6. Mark superseded Milestone 6 rules precisely. Do not rewrite history or claim that prior technical verification failed.

## Out of scope

- production gameplay implementation;
- content expansion;
- changing save files or migration behavior;
- updating the random schema;
- claiming owner approval before it is explicitly given.

## Acceptance gate

- The owner approves a written north star and player loop.
- Each consequential decision above has a recorded answer.
- Wireframes demonstrate one-decision-at-a-time hierarchy and icon-plus-label communication.
- The new scope is reconciled with every conflicting Milestone 6 contract.
- Canonical documents agree on runtime ownership, scope, phases, validation, and content availability.
- The roadmap is adjusted to match the approved decisions.
- No gameplay or external state has changed.

## Recommended parts

### Part A — Decision packet

Prepare alternatives, tradeoffs, wireframes, and the exact owner questions. Stop for owner decisions.

### Part B — Technical rebaseline

After explicit approval, update canonical documents and produce an authority/migration map. Stop for document review.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with xhigh reasoning. Complete WP00 in C:\Users\sith\Documents\Code\projectneon as a product and architecture rebaseline, not an implementation task. Read the required repository documents in AGENTS.md order, then docs/product/README.md, PRODUCT_RESEARCH.md, PRODUCT_DIRECTION.md, ROADMAP.md, and this work-package file. Inspect the existing runtime and dirty working tree only as needed to make the decision packet accurate.

First produce the owner decision packet and representative wireframes. Clearly identify every conflict with the current Milestone 6 specification, including crew unlocks and the card/route model. Do not edit gameplay code and do not update the canonical specification until the owner explicitly approves the product choices. Once approved, reconcile GameSpecifications.md and the owned architecture, plan, test, catalog, and changelog documents without rewriting historical verification. Preserve the owner-carried Godot-AI changes. Stop when WP00's acceptance gate is evidenced and hand back the decisions, document changes, and remaining risks. Do not commit, push, publish, or start WP01.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP00 Product Rebaseline without stopping until the owner has explicitly approved the north star, lap loop, District Plan model, default crew availability, progression boundary, intervention vocabulary, and acceptance metrics; representative wireframes exist; all conflicts with Milestone 6 are resolved in the canonical repository documents; no gameplay code or external state has changed; and the complete WP00 acceptance evidence is ready for owner review. Pause whenever an owner decision is required, preserve unrelated Godot-AI changes, and do not begin WP01.
```
