# WP02 — Core Run Loop and State Clarity

Status: proposed; requires completed WP00
Branch suggestion: `codex/wp-02-core-run-loop`

## Outcome

Make every run visibly and repeatedly follow the approved plan → fight → reward → push/extract structure, with no ambiguous waiting or shop state.

## Required work

1. Implement the approved district-lap lifecycle using existing authorities or narrowly justified additions.
2. Make Jax, Zoey, and Rex selectable from first launch; migrate or repurpose superseded unlock rules exactly as approved in WP00.
3. Present an explicit phase label and next-event description/countdown in every nonterminal run state.
4. Begin encounters promptly or make arrival/spawn delay visually meaningful and interruptible only where specified.
5. Give PLAN, FIGHT, REWARD, SHOP, LAP DECISION, EXTRACTION, BOSS, and RESULT unambiguous entry/exit presentation.
6. Implement the approved lap-end push/extract decision, risk/reward preview, escalating modifier, and boss commitment.
7. Preserve Heat/Night Pressure separation, deterministic streams, safe-boundary precedence, clean restart, summaries, and application/run ownership.
8. Ensure invalid, paused, planning, transition, and terminal states cannot leak eligible time or accept stale intents.

## Out of scope

- full card UI/authority migration, owned by WP03;
- broad item/shop rebalance, owned by WP04;
- new encounter/intervention content, owned by WP05;
- final stage art, owned by WP06;
- permanent stat progression.

## Acceptance gate

- A run repeatedly completes the approved lifecycle and reaches the lap decision at the specified cadence.
- The UI always answers “what phase, what next, what can I do now?”
- The shop cannot be mistaken for waiting or combat.
- All three crew are selectable on a fresh production profile.
- Push/extract previews and outcomes are exact, authoritative, and at-most-once.
- Pauses, planning, focus loss, restart, terminal cleanup, and same/new-seed restart remain correct.
- Deterministic replay/isolation and cumulative lifecycle tests pass.
- An unbriefed loop playtest meets the WP00 comprehension target.

## Recommended parts

### Part A — Lifecycle authority

Implement lap state, transitions, precedence, tokens, summaries, cleanup, and tests without relying on UI state.

### Part B — Runtime phase presentation

Connect the approved WP01 components and make every wait/state transition legible.

### Part C — Crew/profile migration and loop validation

Make all crew available by default, migrate safely, and run the full comprehension/determinism matrix.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with xhigh reasoning. Implement the owner-approved WP02 Core Run Loop and State Clarity in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline, WP01 handoff, and this complete work-package file. Audit the current RunDirector/RunFlowController/PatrolController/ProfileSaveService contracts before proposing the smallest authority changes needed for the approved district-lap lifecycle.

Implement lifecycle authority and deterministic tests before presentation. Then connect the approved phase banners, next-event/countdown, unmistakable shop, lap push/extract preview, all-crew default availability, and terminal/restart behavior. Preserve UI/gameplay ownership, Heat/Night Pressure separation, safe-boundary precedence, stream isolation, stale-intent rejection, and backward-safe profile handling. Do not implement WP03–WP06 content. Launch /GameRun, exercise every changed state and input, inspect fresh output, run affected and cumulative tests, perform proportionate Windows/Web checks, update owned docs, and capture evidence. Preserve unrelated Godot-AI changes. Stop only at the WP02 acceptance gate; do not commit or publish unless asked.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP02 Core Run Loop and State Clarity without stopping until the approved district-lap lifecycle is authoritative and deterministic; all three crew are available on a fresh production profile with approved migration behavior; every run state clearly shows phase, next event, and current action; shop, lap push/extract, boss commitment, terminal outcomes, pause, restart, and cleanup are correct; an unbriefed comprehension check meets the WP00 target; all affected cumulative tests and platform/runtime checks pass cleanly; and evidence/documentation are complete. Preserve unrelated changes and do not start WP03 or publish externally.
```
