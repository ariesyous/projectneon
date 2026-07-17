# ADR 0001: Run Engagement, Escalation, Randomness, and Validation

- Status: Accepted
- Date: 2026-07-17
- Scope: Vertical-slice design documentation; no runtime implementation in this revision

## Context

The original vertical-slice design conflated frequent interaction with strategic decisions, allowed reversible Heat to carry irreversible run progression, offered too few overlapping equipment choices, and did not define reproducible randomness or an explicit qualitative gate for the core auto-combat hypothesis.

## Decision

1. Coin clusters are the first ambient optional interaction. A coin-rewarding enemy creates one generous click target that auto-collects its full base value after approximately 2.5 seconds. Manual collection may build an approximately 3-second streak, but the per-cluster bonus is capped at 10%. Optional input can add delight without turning the auto-battler into mandatory precision clicking.
2. Heat and Night Pressure are separate. Heat is reversible tactical alert that affects immediate encounter composition, danger, elites, and reward quality. Night Pressure is monotonically increasing run progression driven by eligible active time and completed encounters; it advances extraction thresholds, scaling, and the unavoidable boss. Finite cooling can change the next tactical situation but cannot rewind the run.
3. Each run has an authoritative integer seed and a `RunDirector`-owned `RunRandomStreams` component rather than a global Autoload. Versioned sub-seeds isolate `encounters`, `spawns`, `rewards`, `equipment`, `cards`, `enemy_variants`, and `cosmetic`. Stable candidate ordering and cosmetic isolation make reproduction useful without coupling every system to one shared draw sequence.
4. Milestone 1 ends with an owner-recorded human validation gate before Milestone 2. At least five uninvolved testers evaluate a minimally explained, 60-second Combat Lab. Technical tests cannot establish whether passive combat is entertaining, and coding agents cannot claim this gate passed.

## Consequences

- Ambient, strategic, and major-risk cadences are measured separately during eligible active play.
- `RewardDirector` will eventually own authoritative coin accounting and at-most-once cluster resolution; world and UI nodes remain presentation/input adapters.
- `RunDirector` will eventually own Heat, Night Pressure, latched progression thresholds, the authoritative seed, and run-scoped streams.
- Cooling sources require finite charges, stock, or purchase limits.
- The vertical-slice catalogue targets at least nine items, with at least three valid two-item combinations per primary synergy and at least two bridge items.
- Reproducibility is scoped to the same supported build, content revision, random-schema version, and gameplay-relevant decisions/timing. A seed alone is not a mid-run save.
- Milestone 2 remains blocked until the project owner records a passing human gate; a failure requires Combat Lab iteration and a full retest.

## Alternatives Rejected

- Mandatory coin clicking: undermines passive play and makes base rewards depend on pointer attention.
- Heat as both tactical alert and run clock: permits repeated cooling to postpone progression and farm high ordinary rewards.
- One global random sequence: cosmetic or unrelated draws would perturb gameplay results.
- Automated or implementation-team sign-off for watchability: cannot supply independent qualitative evidence.
