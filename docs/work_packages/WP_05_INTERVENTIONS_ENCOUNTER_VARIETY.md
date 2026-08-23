# WP05 — Interventions and Encounter Variety

Status: Owner recommendation approved 2026-08-23; Parts B/C implementation and focused matrix complete; cumulative/platform/visual/human gates remain in handoff
Branch suggestion: `codex/wp-05-tactical-variety`

## Outcome

Sustain tactical attention across a run with a small, coherent set of interventions and encounter combinations, without turning Neon Loop into direct-control combat.

## Required work

1. Prototype the approved smallest intervention vocabulary, drawing from:
   - context-sensitive environment actions;
   - temporary target priority/focus;
   - defensive rally/reposition response;
   - finite Call Backup.
2. Retain Fire Hydrant as one environment object, then test a limited set of additional interactions such as a power box, barrier/dumpster, or hanging sign.
3. Give each action a distinct tactical purpose, valid-target telegraph, icon/verb, cooldown/charge treatment, audio/VFX response, and explicit rejection feedback.
4. Combine existing enemy roles, elites, hazards, lap modifiers, and environment opportunities into authored encounter questions.
5. Ensure enemy intent and interruptibility are visible before the decision window closes.
6. Prevent any intervention from being universally correct on cooldown; provide encounter/build contexts where holding or choosing another action is better.
7. Preserve combat authority, token validation, eligible-time cooldowns, caps, scaling, deterministic authored behavior, and no-stream rules where specified.
8. Add new content only when it creates a tested new decision and the owner approved it in the package prototype.

## Out of scope

- direct crew movement or attack controls;
- a large enemy/environment content expansion;
- unseeded dynamic events;
- changing reward/economy systems;
- adding buttons merely to fill the HUD.

## Acceptance gate

- The permanent combat interaction bar remains small and understandable.
- Each intervention has at least one strong use case, one weak/invalid case, and a readable counter or tradeoff.
- Fire Hydrant is no longer the only recurring environment decision.
- The encounter matrix produces distinct tactical questions using a bounded content set.
- Testers can anticipate enemy intent and explain at least one reason to use or hold an intervention.
- Invalid/duplicate/stale/cooldown/exhaustion/terminal requests consume nothing.
- Combat, intervention, deterministic, cleanup, restart, and cumulative tests pass cleanly.

## Part A result — 2026-08-22

- Research/decision record: `docs/product/WP05_RESEARCH_AND_DECISION_RECORD.md`.
- Exact prototype/matrix comparison: `docs/product/WP05_PROTOTYPE_COMPARISON.md`.
- Current-to-target authority map: `docs/product/WP05_CURRENT_TO_TARGET_AUTHORITY_MAP.md`.
- Technical evidence: `docs/product/WP05_ACCEPTANCE_EVIDENCE.md`.
- Single owner checkpoint: `docs/product/WP05_OWNER_SELECTION.md`.
- Fixed later human procedure: `docs/product/WP05_UNBRIEFED_INTENT_VARIETY_CHECK.md`.
- Focused result: **13/13 tests, 180 assertions**. Final cumulative result: **304/304 tests, 4,373 assertions across 32 suites**, zero failures/skips; clean repeats reported 4,372/4,373 from inherited WP02/M6 conditional branches.
- Configured matrix: 60 rows spanning all crew, exact WP04 builds, early/middle/elite/boss contexts, and hold/Environment/Focus/Backup/Rally policies; exact repeat and cosmetic isolation passed.

The owner answered **“Approved”** on 2026-08-23. The recommendation is now implemented on the handoff branch described in `docs/product/WP05_HANDOFF.md`; the historical Part A result above remains unchanged evidence rather than release content.

## Recommended parts

### Part A — Interaction prototypes

Build disposable or development-gated versions, measure use/hold decisions, and obtain owner selection before productionizing.

### Part B — Production intervention set

Implement selected definitions, authority, feedback, tests, and HUD integration.

### Part C — Encounter matrix

Author bounded combinations, validate cadence and dominance, and capture representative runs.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Complete WP05 Interventions and Encounter Variety in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline and prior handoffs, then this complete work-package file. Audit FireHydrantController, CallBackupController, CombatDirector, encounter definitions, enemy intent presentation, and current HUD authority boundaries. Start with the smallest development-gated prototypes needed to compare the approved intervention candidates; collect decision-quality evidence and stop for owner selection before productionizing new mechanics.

Implement only the selected bounded set. Keep indirect control, a small combat bar, typed authority, tokenized immutable rejection, eligible-time cooldowns, deterministic authored behavior, stream isolation, caps, cleanup, and restart. Every new mechanic must create a distinct tested decision with strong, weak, and invalid cases. Do not add broad content, direct movement, or economy work. Launch /GameRun, exercise changed inputs and rejection/race paths, inspect fresh output, run affected/cumulative tests and the encounter matrix, check affected Windows/Web behavior, capture evidence, and update owned docs/catalog. Preserve unrelated Godot-AI changes. Stop at the WP05 acceptance gate; do not commit, publish, or start WP06 unless asked.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP05 Interventions and Encounter Variety without stopping until owner-selected prototypes have become a small production-ready intervention vocabulary; Fire Hydrant is one of multiple readable contextual decisions; each action has distinct strong, weak, invalid, and hold cases; bounded encounter combinations create varied tactical questions with visible enemy intent; no action is universally correct on cooldown; all authority, deterministic, rejection, eligible-time, cleanup, restart, cumulative/runtime/platform checks pass; and evidence/documentation are complete. Pause for owner mechanic selection, preserve unrelated changes, and do not start WP06 or publish externally.
```
