# ADR 0002 — WP00 Product Rebaseline

Status: Accepted
Date: 2026-08-20
Decision owner: Project owner

## Context

Milestone 6 produced a technically verified vertical slice, but its pressure-threshold patrol, persistent hand/five-slot planner, gated crew defaults, simultaneous HUD, and intervention naming did not yet provide the clear repeating product loop required for the next release direction. WP00 was authorized as a documentation-and-wireframe decision gate. It could preserve implemented history and approve a bounded migration, but could not change gameplay, saves, project settings, Git history, publication, or any other external state.

## Decision

The owner explicitly approved the complete recommended D1–D7 package on 2026-08-20:

1. Neon Loop is a run-based neon-street auto-brawler where the player plans the next block, watches the crew execute the build, intervenes at decisive moments, and chooses whether to bank gains or push through another increasingly dangerous district lap.
2. A boss run has three laps of three blocks. Laps one and two end in Extract/Push. Pushing after lap two commits to lap three and The Viper; there is no routine final-lap extraction. The boss-run target is 8–12 eligible minutes.
3. The release-facing District Plan offers two next-block cards from a finite four-card, one-copy lap deck rebuilt at each lap boundary. Resolved blocks form history; the persistent hand/five editable future slots are deprecated only after WP03 proves the migration.
4. Jax, Zoey, and Rex are available on a fresh production profile. WP02 will retire Zoey/Rex access gates while safely retaining legacy profile facts.
5. Meta-progression may unlock breadth, cosmetics, compendium knowledge, or challenge variants, never permanent stats or viability grind. Hacker Deck and Gang Hideout remain breadth unlocks. Scrap is summary-only until a separate economy decision.
6. The permanent combat roles are Environment, Focus, and Backup. Fire Hydrant is an Environment example; Call Backup maps to Backup; Subway Reroute is strategic travel. Rally is a WP05 candidate, not promised content.
7. The five-person 4/5 clarity, consequence, variety, and replay thresholds and the fight/block/lap/run timing bands in `TEST_PLAN.md` are the approved acceptance contract. Distributions and outliers matter; averages alone do not pass.

## Current versus target

Milestone 6 remains the implemented runtime and its exact automated/export facts remain historical truth. This decision supersedes only prospective product rules that conflict with the approved target: the former no-future-work boundary, pressure-only player-facing loop, release hand/five-slot planner, Zoey/Rex defaults as core-style gates, Subway as a permanent combat role, the simultaneous combat dashboard, and generic strategic cadence as the future acceptance model.

No target behavior is considered implemented until its owning package lands and is verified. `GameSpecifications.md` section 0 and `ARCHITECTURE.md` contain the detailed authority/migration map.

## Consequences

- WP01–WP07 become the bounded prospective sequence; WP00 begins none of them.
- WP01 may change presentation only.
- WP02 owns authoritative lap/block lifecycle and crew/profile migration.
- WP03 owns District Plan scheduling and interaction migration while preserving typed exact-once authority and deterministic stable IDs/streams.
- WP04 owns visible build/reward/shop consequence.
- WP05 prototypes and owner-selects concrete intervention mechanics.
- WP06 owns authored presentation polish without moving gameplay authority into UI.
- WP07 executes integrated technical and owner acceptance.
- Random schema remains version 1 in WP00. An owning package must stop, document, and lock vectors if it discovers a genuinely incompatible draw-semantic change.
- No additional content, permanent power, direct-control combat, procedural map, multiplayer, platform expansion, or external-state change is implied by this decision.

## Evidence

- `docs/product/WP00_DECISION_PACKET.md`
- `docs/product/WP00_ACCEPTANCE_EVIDENCE.md`
- `docs/product/wireframes/wp00_wireframes.svg`
- `docs/product/wireframes/wp00_wireframes.png`
