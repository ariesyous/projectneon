# WP07 — Integration, Balance, and Release

Status: proposed; requires completed WP00–WP06
Branch suggestion: `codex/wp-07-integration-release`

## Outcome

Turn the rebaseline packages into one coherent, balanced, documented release candidate and obtain explicit owner acceptance.

## Required work

1. Run a cross-system audit for lifecycle, cards, builds, shops, encounters, interventions, UI, accessibility, profile migration, summaries, restart, and menu return.
2. Tune the approved timing targets using playtest evidence:
   - encounter downtime;
   - block and lap duration;
   - run duration;
   - reward frequency and consequence;
   - intervention cadence;
   - Heat/Night Pressure escalation;
   - push/extract risk/reward;
   - boss preparation and difficulty.
3. Check crew/build viability and dominance across fixed seeds and authoritative timing contexts.
4. Run all deterministic, rejection, restart, terminal, long-name, containment, accessibility, soak, Windows, and Web matrices.
5. Complete the unbriefed owner acceptance playtest defined in the approved test plan.
6. Fix in-scope defects and repeat affected validation; record genuine limitations rather than hiding them.
7. Reconcile `GameSpecifications.md`, architecture, implementation plan, test plan, content catalog, changelog, playtest guide, and release evidence.
8. Prepare release notes and a go/no-go record. Publish only after explicit authorization.

## Out of scope

- adding roadmap features during stabilization;
- interpreting automated success as qualitative owner acceptance;
- broad content, platform, or progression expansion;
- publishing, merging, tagging, or opening a PR without explicit authorization.

## Acceptance gate

- Full automated suite passes with exact results recorded and no hidden warnings/skips.
- Configured `/GameRun`, fresh output, every changed input, restart/outcome path, Windows export, and Web export/runtime are verified.
- Approved cadence, clarity, consequence, variety, and replay targets are met or exceptions are explicitly accepted.
- Owner-led unbriefed playtest record is complete and the owner explicitly accepts the result.
- Canonical docs and evidence match the implemented build.
- Release candidate commit/PR/deployment actions remain pending until separately authorized.

## Recommended parts

### Part A — Integration and deterministic matrix

Find and fix cross-package defects, then lock the cumulative technical baseline.

### Part B — Balance and owner playtest

Run fixed-seed tuning, unbriefed observation, focused repairs, and revalidation.

### Part C — Release candidate record

Complete documentation, evidence, release notes, and owner go/no-go decision.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Complete WP07 Integration, Balance, and Release in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline, every WP00–WP06 handoff, and this complete work-package file. Begin with a cross-system risk matrix and inspect git status so unrelated Godot-AI changes remain identifiable. Do not add new roadmap features during stabilization.

Execute the deterministic/integration matrix, fix in-scope defects, and tune only from recorded fixed-seed and playtest evidence. Exercise /GameRun, all changed inputs, every lifecycle/outcome/restart/menu path, profile migration, accessibility variants, peak density, soak, and supported Windows/Web behavior; inspect fresh logs and record exact automated results without suppressing warnings or skips. Prepare the owner-led unbriefed playtest but do not claim its result. After the owner records acceptance or requested corrections, repeat affected checks and reconcile all canonical docs, evidence, and release notes. Stop with a go/no-go record and an unmodified external release state. Do not commit, merge, push, tag, open a PR, or deploy unless the owner separately authorizes it.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP07 Integration, Balance, and Release without stopping until all WP00–WP06 behavior is integrated; approved cadence, consequence, variety, clarity, crew/build viability, migration, accessibility, restart, outcome, and deterministic contracts are validated; the full test suite and Windows/Web/runtime matrices pass with exact clean evidence; the owner-led unbriefed playtest is recorded and explicitly accepted or all requested in-scope corrections are revalidated; canonical documentation and release notes match the build; and a go/no-go record is ready. Never infer qualitative acceptance or publish/merge/commit externally without separate authorization, and preserve unrelated changes.
```
