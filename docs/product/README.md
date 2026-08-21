# Neon Loop Product Rebaseline

Status: **WP00 owner-approved and canonical; WP01 complete; WP02 technical/runtime/visual gate passed — 2026-08-21; WP02 human gate pending**
Prepared: 2026-08-20

This folder turns the August 2026 owner playtest into a research-backed product direction and an executable roadmap. It does not authorize post-Milestone-6 gameplay work by itself. The existing specification remains canonical until the owner approves a direction and Work Package 00 updates the specification and architecture records.

## Why this exists

The current vertical slice is mechanically substantial and technically verified, but the owner playtest did not accept the experience as finished. The reported problems are systemic:

- the game is fun, but its loop and moment-to-moment state are hard to read;
- characters should be available by default rather than withheld behind progression;
- the card planner, shop, route, lane presentation, and waiting periods are confusing;
- the interface is text-heavy, visually sparse, and lacks a coherent icon language;
- many choices do not appear to change the next fight meaningfully;
- Fire Hydrant is a good interaction but cannot carry the intervention layer alone;
- the run does not yet deliver a clear roguelite cycle or a polished, satisfying payoff.

## Reading order

1. [Product research](PRODUCT_RESEARCH.md)
2. [Approved product direction](PRODUCT_DIRECTION.md)
3. [Roadmap](ROADMAP.md)
4. [Codex execution guide](CODEX_EXECUTION_GUIDE.md)
5. The relevant file in `docs/work_packages/`

## Decision record

The owner approved the complete recommended D1–D7 package on 2026-08-20. The canonical target is three laps of three blocks; Extract/Push after laps one and two; a lap-two push that commits to the final boss lap; a focused two-choice District Plan backed by a four-card one-copy lap deck; all three crew available on fresh profiles; breadth/cosmetic/challenge progression only; Environment/Focus/Backup combat roles; and the measurable five-person and timing gates in `TEST_PLAN.md`.

See the [owner decision packet](WP00_DECISION_PACKET.md), [WP00 acceptance evidence](WP00_ACCEPTANCE_EVIDENCE.md), [WP01 acceptance evidence](WP01_ACCEPTANCE_EVIDENCE.md), [WP02 acceptance evidence](WP02_ACCEPTANCE_EVIDENCE.md), [WP02 authority map](WP02_CURRENT_TO_TARGET_AUTHORITY_MAP.md), [WP02 comprehension template](WP02_UNBRIEFED_COMPREHENSION_CHECK.md), [wireframes](wireframes/README.md), and [accepted architecture decision](../decisions/0002-wp00-product-rebaseline.md).

WP00 is documentation-only. WP01 changed presentation only. WP02 now implements the authoritative three-lap/three-block lifecycle, exact-once lap decisions, all-crew production access, state clarity, cadence instrumentation, and lifecycle result fields while preserving the M5 card compatibility boundary. Its five-person owner comprehension gate remains pending. WP03 has not started, and no later package begins without a separate explicit task.
