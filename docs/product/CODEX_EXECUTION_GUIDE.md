# Codex Execution Guide for the Rebaseline

Status: proposed operating guide
Prepared: 2026-08-20

## Model and reasoning recommendation

Use **GPT-5.6 Sol** for every work package. OpenAI describes GPT-5.6 Sol as the frontier model for complex professional work, with tool support including shell and patch workflows. The model guide recommends concise prompts that specify outcome, context, constraints, success criteria, and output rather than repeating instructions.

Recommended reasoning:

- **High** for normal implementation work.
- **xhigh** for WP00 product/architecture reconciliation and the WP02 lifecycle refactor when the model needs to resolve a genuinely coupled design problem.
- **Medium** for narrow visual-token, copy, or documentation follow-ups.
- Do not default every task to max reasoning; raise effort only when verification shows that high is insufficient.

Official references:

- [GPT-5.6 Sol model](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
- [GPT-5.6 prompting guidance](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [Codex goals](https://learn.chatgpt.com/use-cases/follow-goals)

## When to use a regular prompt versus `/goal`

Use a regular prompt for a bounded task expected to complete in one working turn. Use `/goal` for a durable objective that will require multiple turns, test/fix cycles, rendering, or owner checkpoints. A goal should be larger than one small edit and smaller than an open-ended backlog.

Each work-package file contains both:

- **Start prompt:** establishes scope and directs the first implementation turn.
- **Durable `/goal`:** defines the verifiable stopping condition across turns.

Run only one work-package goal at a time. Inspect the current goal before starting another. Pause at explicit owner approval gates rather than interpreting silence as approval.

## Repository prerequisites

Before any package work:

1. Work from `C:\Users\sith\Documents\Code\projectneon`.
2. Read, in order, the complete `GameSpecifications.md`, `AGENTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, then the selected work-package file and its owned source files.
3. Inspect `git status` and preserve unrelated or owner-carried changes. In particular, do not attribute or rewrite the Godot-AI addon upgrade.
4. Confirm that WP00 is owner-approved and complete before implementing WP01–WP07.
5. Create or use the package's `codex/wp-XX-*` branch only when the owner has requested branch creation.

## Standard execution contract

Every implementation prompt should preserve these boundaries without restating the entire repository guide:

- Implement only the selected package's required outcomes.
- Treat `GameSpecifications.md` as canonical after WP00 rebaselines it.
- Keep gameplay state out of UI scenes and preserve existing runtime ownership.
- Use typed GDScript and deterministic stable ordering.
- Preserve isolated random streams; do not add unseeded gameplay randomness.
- Preserve input parity required by the approved specification.
- Do not suppress parser errors, warnings, skipped tests, or failing tests.
- Update owned documentation when facts change.
- Launch `/GameRun`, exercise changed interactions, inspect fresh output, run affected and cumulative tests, capture visual evidence, and check affected Windows/Web behavior in proportion to risk.
- Do not commit, push, publish, open a PR, or mutate external systems unless the owner explicitly asks.

## Prompt shape

The package prompts intentionally follow this compact order:

1. **Outcome:** what player-visible result to achieve.
2. **Context:** which approved package and source-of-truth files apply.
3. **Constraints:** architecture, determinism, ownership, and scope boundaries.
4. **Success:** concrete artifacts and validation.
5. **Stop:** when to hand back for owner review.

If a package is too large for one context window, split it only at an acceptance boundary already named in the package. Give each part a distinct output and stopping condition; do not split by arbitrary file count.

## Suggested package sessions

| WP | Suggested durable sessions |
|---|---|
| 00 | Decisions/research synthesis → wireframes/prototype → canonical documentation |
| 01 | Design tokens/components → screen conversion → accessibility/visual QA |
| 02 | Lifecycle authority → phase presentation → loop playtest/validation |
| 03 | Card authority migration → planning UI/input → first-use validation |
| 04 | consequence/balance model → reward/shop UI → build validation |
| 05 | intervention prototypes → encounter combinations → tactical validation |
| 06 | world art/readability → combat feedback → transition/platform polish |
| 07 | integration defects → balance/playtest → release evidence/documentation |

## Handoff format

At the end of each package or part, Codex should report:

- the player-visible outcome;
- files and authoritative contracts changed;
- tests and runtime/platform checks executed with exact results;
- visual/manual evidence paths;
- unresolved limitations or owner decisions;
- whether the package acceptance gate is actually met;
- the safest next package or follow-up, without starting it automatically.
