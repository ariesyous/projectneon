# Rebaseline Roadmap

Status: owner-approved through WP00; WP01–WP04 technically complete locally by 2026-08-22; qualitative checkpoints remain separate; published candidate remains WP03
Prepared: 2026-08-20

## Roadmap outcome

Transform the technically complete vertical slice into a readable and satisfying roguelite experience by repairing the experience spine first, then adding consequence, variety, and production polish.

This roadmap is intentionally organized by player outcome rather than subsystem ownership. Each work package must end in a playable, reviewable state and should be implemented on its own `codex/wp-XX-*` branch only after the preceding approval gates pass.

## Sequence

| WP | Outcome | Depends on | Status | Primary evidence |
|---|---|---|---|---|
| 00 | Product rebaseline is approved and made canonical | Owner review | **Complete — 2026-08-20** | Approved decision record, updated specifications, representative wireframes, acceptance evidence |
| 01 | The interface has a coherent visual language and clear screen hierarchy | WP00 | **Implemented and technically evidenced — 2026-08-21** | Rendered screen set, accessibility/readability review, 254-test cumulative gate, clean `/GameRun` smoke |
| 02 | The run visibly repeats Plan → Fight → Reward → Push/Extract | WP00; WP01 tokens may proceed in parallel | **Implemented and technically evidenced — 2026-08-21; five-person gate pending** | Playable loop slice, deterministic lifecycle tests, runtime/platform/visual evidence |
| 03 | District planning is understandable on first use | WP01, WP02 | **Implemented and technically evidenced — 2026-08-22; first-use gate pending** | Focused authority/card/UI tests, configured runtime/platform evidence, owner first-use record |
| 04 | Equipment, rewards, and the shop create obvious build consequences | WP02, WP03 | **Implemented, evidenced, and published for browser playtest — 2026-08-22; five-person gate pending** | Consequence audit, three disjoint builds, exact decision captures/runtime/platform evidence |
| 05 | Encounters remain varied through a small, coherent intervention system | WP02; coordinate with WP04 | **Owner selection approved — 2026-08-23; local implementation handoff present; final gates pending** | Research record, production 60-row matrix, focused/affected/cumulative/platform/visual evidence, human check |
| 06 | The world and combat feel authored, legible, and satisfying | WP01, WP03, WP04, WP05 | Planned | Final art/presentation captures, Windows/Web smoke |
| 07 | The rebaseline is balanced, integrated, documented, and release-ready | WP00–WP06 | Planned | Full gate, owner playtest record, release candidate |

## Phase A — Decide the game

### [WP00 — Product Rebaseline](../work_packages/WP_00_PRODUCT_REBASELINE.md)

The owner approved all seven consequential decisions, representative wireframes exist, and canonical documentation now records the target/current boundary without touching production gameplay.

Exit gate: **Passed — 2026-08-20.** Evidence: [WP00 acceptance evidence](WP00_ACCEPTANCE_EVIDENCE.md).

## Phase B — Build the experience spine

### [WP01 — Interface and Visual Language](../work_packages/WP_01_INTERFACE_VISUAL_LANGUAGE.md)

Establish reusable layout, type, icon, surface, input, focus, and transition patterns. Produce the minimal combat HUD and focused decision-screen framework.

Exit gate: the current phase, next event, immediate action, and major resources are understandable in representative 1280 × 720 stills without a verbal explanation.

WP01 technical/visual exit gate: **Passed — 2026-08-21.** See [WP01 acceptance evidence](WP01_ACCEPTANCE_EVIDENCE.md). The owner-coordinated five-person unbriefed checkpoint below remains separate qualitative evidence; it is not inferred from automated or coding-agent review.

### [WP02 — Core Run Loop and State Clarity](../work_packages/WP_02_CORE_RUN_LOOP_STATE_CLARITY.md)

Make the proposed loop explicit in runtime state and presentation. All crew are available by default, the shop and waiting states are unmistakable, and the player repeatedly reaches a visible push/extract decision.

Exit gate: an unbriefed player can accurately recount the run sequence and always identify what happens next.

WP02 technical/runtime/visual gate: **Passed — 2026-08-21.** See [WP02 acceptance evidence](WP02_ACCEPTANCE_EVIDENCE.md). The owner-coordinated five-person check remains pending; use [the fixed unbriefed procedure](WP02_UNBRIEFED_COMPREHENSION_CHECK.md) and do not infer a qualitative pass from automation.

### [WP03 — District Planning and Cards](../work_packages/WP_03_DISTRICT_PLANNING_CARDS.md)

Replace or radically simplify the current planner through the approved District Plan model. Preserve deterministic content selection and authoritative validation while making one choice easy to understand.

Exit gate: an unbriefed player makes a valid first card choice, predicts its consequence, and recognizes that consequence in the next block.

WP03 technical/runtime/visual/platform gate: **Passed and published for browser playtest — 2026-08-22.** Implementation commit `a6ef571942afb319b3e2c0cdd9c9cffcc1f1bc93` and [Pages run 32586634393](https://github.com/ariesyous/projectneon/actions/runs/32586634393) are the publication provenance. See [WP03 acceptance evidence](WP03_ACCEPTANCE_EVIDENCE.md) and the [authority map](WP03_CURRENT_TO_TARGET_AUTHORITY_MAP.md). The owner-coordinated five-person first-use check remains pending; use [the fixed procedure](WP03_UNBRIEFED_FIRST_USE_CHECK.md) and do not infer a qualitative pass from automation.

## Phase C — Make choices and fights matter

### [WP04 — Builds, Rewards, and Shop](../work_packages/WP_04_BUILDS_REWARDS_SHOP.md)

Rebalance and present items, synergies, rewards, and purchasing around visible next-fight changes. Make tradeoffs and replacement consequences obvious.

Exit gate: three builds play and read differently, and testers can explain why they selected or rejected representative rewards.

WP04 technical/runtime/visual/platform gate: **Passed and owner-authorized for `main`/Pages browser playtest — 2026-08-22.** See [acceptance evidence](WP04_ACCEPTANCE_EVIDENCE.md), [consequence audit](WP04_CONSEQUENCE_AUDIT.md), and [authority map](WP04_CURRENT_TO_TARGET_AUTHORITY_MAP.md). The five-person unbriefed check remains pending under [the fixed procedure](WP04_UNBRIEFED_CONSEQUENCE_VARIETY_CHECK.md). Publication does not satisfy that gate or authorize WP05.

### [WP05 — Interventions and Encounter Variety](../work_packages/WP_05_INTERVENTIONS_ENCOUNTER_VARIETY.md)

Prototype the smallest intervention and encounter set that sustains tactical attention without undermining automatic combat.

Exit gate: the player encounters recurring but non-identical tactical questions, and no intervention is a universally correct cooldown button.

Part A technical/research/prototype gate: **Passed — 2026-08-22.** See [research](WP05_RESEARCH_AND_DECISION_RECORD.md), [comparison matrix](WP05_PROTOTYPE_COMPARISON.md), [authority map](WP05_CURRENT_TO_TARGET_AUTHORITY_MAP.md), [technical evidence](WP05_ACCEPTANCE_EVIDENCE.md), and the [single owner-selection checkpoint](WP05_OWNER_SELECTION.md). Default/release `/GameRun` remains WP04; Part B is paused and no qualitative pass is inferred.

## Phase D — Make it feel finished

### [WP06 — World, Combat, and Presentation Polish](../work_packages/WP_06_WORLD_COMBAT_POLISH.md)

Replace debug-like stage communication with an authored city-block presentation, strengthen animation/VFX/audio feedback, and give every phase an intentional transition.

Exit gate: release presentation contains no unexplained lane dots/debug markers, important combat relationships remain readable, and changed Windows/Web paths are clean.

### [WP07 — Integration, Balance, and Release](../work_packages/WP_07_INTEGRATION_BALANCE_RELEASE.md)

Tune cadence and consequence, complete cumulative QA, update documentation, and run owner-led acceptance on the finished experience.

Exit gate: all automated and platform checks pass, the manual matrix is complete, the owner accepts the experience, and remaining limitations are explicitly recorded.

## Cross-package constraints

- `GameSpecifications.md` remains the product source of truth. WP00 must update it before later work starts.
- Preserve typed GDScript, system ownership, deterministic stable ordering, isolated random streams, and revision/token validation.
- Do not convert UI into gameplay authority.
- Do not attribute, remove, or rewrite the owner-carried Godot-AI addon changes.
- Keep debug tooling available in development while removing debug affordances from release presentation.
- Each package includes automated coverage, fresh Godot/runtime inspection, changed-input exercise, documentation updates, visual evidence when relevant, and proportionate Windows/Web checks.
- No package may silently expand into procedural maps, direct-control combat, multiplayer, permanent stats, or unrelated platform features.
- Roadmap approval is not implementation authorization. WP01–WP05 began only under separate explicit tasks; the owner explicitly approved WP05's recommendation on 2026-08-23. That decision does not authorize WP05 publication or WP06.

## Playtest checkpoints

### Checkpoint 1 — Paper/wireframe comprehension (WP00/WP01)

Five short unbriefed tasks: identify current phase, next event, available action, District Card consequence, and extract/push risk. Record failures rather than coaching.

### Checkpoint 2 — Loop prototype (WP02/WP03)

Testers complete at least one lap and explain the sequence back. Target: at least four of five correctly identify every phase and predict the next block after choosing a card.

### Checkpoint 3 — Consequence/variety (WP04/WP05)

Testers create multiple builds, use interventions, and name consequential decisions. Record choice rationale, unused mechanics, dominant actions, confusing effects, and dead time.

### Checkpoint 4 — Release acceptance (WP07)

Owner-defined cohort plays without a feature briefing. Record run duration, completion/outcome, clarity issues, satisfaction, perceived variety, and desire to start another run. Do not invent a pass from automated evidence.

## Scope-control rule

If a work package reveals a new feature idea, record it in that package's follow-up section. Do not implement it unless it is necessary to meet the approved outcome and acceptance criteria. The roadmap succeeds by making the current premise coherent, not by maximizing feature count.
