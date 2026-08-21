# WP01 — Interface and Visual Language

Status: implemented and technically evidenced — 2026-08-21; owner qualitative checkpoint remains separate
Branch suggestion: `codex/wp-01-interface-language`

## Outcome

Replace the text-heavy, spartan presentation with a coherent and accessible visual system that makes the current phase, next event, and immediate action obvious.

## Required work

1. Create reusable presentation tokens for typography, spacing, surfaces, borders, semantic colors, focus, disabled states, and animation timing.
2. Establish one replaceable icon family for resources, phases, card types, equipment tags, synergies, interventions, and common actions.
3. Pair unfamiliar icons with short labels/tooltips; never use color alone for important state.
4. Build reusable choice-card, stat-comparison, countdown/status, intervention-button, toast, tooltip, and phase-banner components.
5. Implement the approved minimal combat HUD and focused overlay shell.
6. Move non-actionable detail behind focus/hover/inspect disclosure.
7. Preserve keyboard, mouse, and touch behavior required by the approved specification, with visible focus and safe target sizes.
8. Validate representative screens at native 1280 × 720 and supported Web scaling/safe areas.

## Out of scope

- changing gameplay calculations or authoritative state;
- final stage art and combat VFX, owned by WP06;
- inventing new card, item, enemy, or intervention content;
- resolving card flow before WP03.

## Acceptance gate

- A single reusable visual language is used across the representative combat, plan, reward, shop, pause/settings, push/extract, and summary shells.
- In still captures, reviewers can identify current phase, next event, available primary action, health, Heat, and Night Pressure.
- Combat contains no persistent wall of card/equipment rules.
- Every important state has a non-color cue.
- Long names, focus, touch targets, and 1280 × 720 containment pass.
- UI remains presentation-only and all existing authority contracts are intact.
- Fresh Godot output and affected automated/runtime checks are clean.

Status: **Passed for the complete enumerated WP01 technical/visual gate on 2026-08-21.** Evidence: [WP01 acceptance evidence](../product/WP01_ACCEPTANCE_EVIDENCE.md).

WP01 changes presentation only. The gameplay implementation is still the Milestone 6 authority model: the existing card hand/five-slot planner remains functional behind the focused District Plan shell until WP03, the current route lifecycle remains until WP02, and the disabled Focus slot is a compatible presentation shell rather than invented gameplay. The separate five-person unbriefed roadmap checkpoint remains owner-coordinated qualitative evidence and is not fabricated by this technical pass.

## Implemented work

- `NeonUiTokens` centralizes typography, spacing, surfaces, borders, semantic states, focus/disabled treatment, touch minimums, and motion timings.
- Reusable `NeonChoiceCard`, `NeonStatComparison`, `NeonCountdownStatus`, `NeonInterventionButton`, `NeonToast`, `NeonTooltip`, and `NeonPhaseBanner` components now serve the live HUD/overlay and the deterministic visual gallery.
- One replaceable SVG icon family covers resources, phases, actions/interventions, and equipment/synergy tags without becoming gameplay content.
- `GameHUD` now leads with current phase, next event, countdown/approach, compact Heat/Night Pressure, crew health, build inspection, and context-valid actions. Non-actionable route/equipment rules are progressively disclosed.
- Focused shells exist for the current planner/reward authority, finite shop choice, current Push/Extract authority, pause/settings, and run summary. Target-only later-package screens remain presentation fixtures and do not publish or mutate authority.
- Mouse, keyboard, touch fallback, native drag/drop, revision/token checks, stable ordering, and every existing typed intent remain intact.

## Verification summary

- Godot 4.7 cumulative: **254/254 tests, 3,376 assertions, zero failures, zero skips** across the accepted 22-suite Milestone 0–6 baseline plus 10 WP01 tests.
- Configured `/GameRun` smoke exercised start, safe patrol, build inspect/close, District Plan open/close, immutable invalid intervention requests, pause, settings/back, resume, and safe-area layout. Its fresh log contains no warning, error, or debugger entry.
- Eight native 1280×720 representative states, native safe-area combat, a 2560×1440 Web integer-scale artifact, and a configured `/GameRun` capture were rendered and visually inspected.
- The cumulative harness retains the already documented Milestone 6 runner-only shutdown report (48 ObjectDB instances/four resources); the production `/GameRun` log is clean and WP01 introduced no new shutdown diagnostic.

## Recommended parts

### Part A — Tokens and components

Implement the reusable theme/component layer and a visual test gallery.

### Part B — Screen hierarchy

Convert representative runtime screens and the combat HUD to the new layer.

### Part C — Accessibility and visual QA

Render, inspect, fix, and capture the complete screen matrix.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Implement the owner-approved WP01 Interface and Visual Language in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved product rebaseline, and this complete work-package file. Begin by auditing existing HUD/overlay components and producing a concise conversion map; then implement reusable visual tokens, icon-plus-label components, the minimal combat HUD, and focused decision shells.

Keep UI presentation-only, preserve deterministic gameplay and every approved input path, and avoid content or gameplay expansion. Reuse compatible assets and keep placeholders explicitly replaceable. Render and visually inspect every representative state at 1280 × 720, test long labels/focus/touch/safe-area behavior, launch /GameRun, inspect fresh output, and run affected plus cumulative tests. Update owned documentation and capture evidence. Preserve unrelated Godot-AI changes. Stop when the WP01 acceptance gate is met; do not commit, publish, or start WP02 without instruction.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP01 Interface and Visual Language without stopping until the approved reusable design tokens and icon-plus-label components are integrated; combat, plan, reward, shop, pause/settings, push/extract, and summary states share a coherent hierarchy; current phase, next event, and immediate action are legible at 1280×720; accessibility/input/containment checks and affected cumulative tests pass with clean Godot output; visual evidence and documentation are complete; and no gameplay authority or unrelated Godot-AI change has been altered. Do not start another work package or publish externally.
```
