# Neon Loop Product Rebaseline

Status: **proposal for owner review**
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
2. [Proposed product direction](PRODUCT_DIRECTION.md)
3. [Roadmap](ROADMAP.md)
4. [Codex execution guide](CODEX_EXECUTION_GUIDE.md)
5. The relevant file in `docs/work_packages/`

## Decision boundary

No implementation work package should start until WP00 is approved and complete. WP00 exists to reconcile this proposal with `GameSpecifications.md`, which currently defines Milestone 6 as the stopping boundary and gates some crew/content that the owner now wants available by default.

The owner should explicitly decide these three product questions during WP00:

1. Whether a run should use the proposed district-lap structure, initially targeting three escalating laps before the boss.
2. Whether District Cards should become a focused choice of the next block, instead of a persistent hand placed onto abstract future route slots.
3. Whether long-term progression should unlock breadth, cosmetics, and challenge variants only, with no permanent stat upgrades and all three crew available from the start.
