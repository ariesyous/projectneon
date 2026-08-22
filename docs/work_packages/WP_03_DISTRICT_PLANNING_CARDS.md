# WP03 — District Planning and Cards

Status: implemented and technically evidenced on 2026-08-22; owner-authorized `main`/Pages browser-playtest publication; owner-run unbriefed first-use gate pending
Branch suggestion: `codex/wp-03-district-plan`

## Outcome

Make a first District Card decision understandable without instruction and make its consequence recognizable in the immediately following block.

## Required work

1. Implement the WP00-approved District Plan model, expected to be a focused next-block choice rather than a persistent combat hand/five-slot planner.
2. Preserve stable card IDs, authored effects, deterministic `cards`-stream selection, exact-once resolution, and validation against stale/replayed intent.
3. Present two or three large choices as allowed by content availability, each with:
   - illustration or category icon;
   - district name and block type;
   - one-line special rule;
   - exact Heat change;
   - reward/risk preview;
   - visible selection and confirm state.
4. Make click/tap/keyboard the primary tutorial path. Retain drag only if it adds delight without creating a second mental model.
5. Show one compact Next Block preview after confirmation and a simple resolved-lap history.
6. Remove or development-gate obsolete route-slot, validity, dot, and hand presentation after safe authority migration.
7. Update tutorial copy to teach the decision, not implementation mechanics.
8. Define backward-safe behavior for any persisted application data; active runs remain nonsavable unless the approved specification changes.

## Out of scope

- adding a large new card set;
- a card currency, deckbuilder meta, or permanent stat upgrades;
- procedural routes;
- rebalancing equipment/shop systems;
- final card illustration polish if placeholders are approved for this package.

## Acceptance gate

- An unbriefed player makes a valid first choice and accurately predicts the next block's primary consequence.
- The following block visibly acknowledges the chosen card/effect.
- No card hand or future-slot legality UI remains in combat unless explicitly approved.
- Invalid, stale, repeated, declined, and transition-race intents mutate nothing.
- Card selection changes only the `cards` stream and preserves schema/version contracts.
- All card/route/effect, input, restart, and lifecycle tests pass.
- Visual evidence covers normal, insufficient-choice, decline/back if allowed, and long-copy states.

## Recommended parts

### Part A — Authority migration

Define the revised card lifecycle, migrate/delete obsolete state safely, and lock deterministic vectors/tests.

### Part B — Focused District Plan UI

Implement choice cards, previews, input parity, tutorials, and next-block/history presentation.

### Part C — First-use validation

Run the unbriefed task, repair comprehension failures, and complete regression/platform evidence.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Implement the owner-approved WP03 District Planning and Cards in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline and WP01/WP02 handoffs, then this complete work-package file. Begin with a precise migration map from the current CardSystem/PatrolController future-slot contract to the approved focused next-block District Plan.

Preserve stable IDs, authored effects, deterministic cards-stream behavior, revision/token validation, safe-boundary precedence, and UI/authority separation. Implement and test authority migration first, then the large icon-plus-label choices, consequence preview, primary click/tap/keyboard flow, optional equivalent drag only if approved, compact Next Block state, history, and tutorial. Remove or development-gate obsolete release UI without deleting required debug capability. Do not add a content expansion or touch WP04–WP06 scope. Launch /GameRun, exercise every changed input and race/rejection path, inspect fresh output, run card plus cumulative tests, check affected Windows/Web behavior, capture visual and first-use evidence, and update owned docs. Preserve unrelated Godot-AI changes. Stop at the WP03 acceptance gate; do not commit or publish unless asked.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP03 District Planning and Cards without stopping until the approved focused District Plan replaces the confusing release flow; a first-time unbriefed player can select a card and predict its next-block consequence; that consequence is visibly acknowledged; stable IDs, authored effects, cards-stream determinism, safe-boundary precedence, token/revision rejection, restart, and input parity are fully covered; obsolete combat hand/slot clutter is removed or development-gated as approved; all affected cumulative/runtime/platform checks pass; and evidence/documentation are complete. Preserve unrelated changes and do not start WP04 or publish externally.
```
