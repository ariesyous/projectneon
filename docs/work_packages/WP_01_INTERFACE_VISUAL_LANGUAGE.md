# WP01 — Interface and Visual Language

Status: proposed; requires completed WP00
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
