# WP06 — World, Combat, and Presentation Polish

Status: **owner-authorized to begin on 2026-08-26; WP05 entry gate passed**
Branch suggestion: `codex/wp-06-world-combat-polish`

## Outcome

Make Neon Loop look and feel like an authored neon city-block game rather than a debug arena, while improving combat satisfaction without sacrificing readability.

## Required work

1. Establish an approved art-direction sheet covering palette, values, silhouettes, materials, lighting, signage, character scale, telegraphs, and UI/world separation.
2. Replace release-visible lane dots, debug markers, and ambiguous flat bands with street geometry and environmental depth cues; keep logical lanes internal.
3. Create representative block variants and approved lap-to-lap atmosphere escalation without procedural-map expansion.
4. Improve combat feedback hierarchy:
   - anticipation/telegraph;
   - hit/contact;
   - status/proc;
   - defeat/reward;
   - boss/major event.
5. Use animation, particles, sound, camera response, and short text selectively to communicate cause and magnitude.
6. Give PLAN, FIGHT, REWARD, SHOP, PUSH/EXTRACT, BOSS, and RESULT intentional transitions.
7. Preserve accessibility settings for screen shake, hit flash, damage numbers, audio categories, focus pause, and non-color cues.
8. Optimize and validate presentation for Windows and Web at the supported viewport.

## Out of scope

- changing authoritative damage, AI, reward, or progression rules;
- procedural route generation;
- a wholesale replacement of proven gameplay systems;
- uncontrolled screen shake, particles, or animation that obscures intent;
- shipping development/debug affordances in release presentation.

## Acceptance gate

- No release view contains unexplained lane dots, spawn markers, route-slot debug shapes, or placeholder labels.
- The stage reads as a city block with clear entrances, depth, combat space, and interactable silhouettes.
- Major hits, procs, interventions, danger telegraphs, rewards, and phase changes have distinct feedback.
- Combat remains readable at peak supported density with accessibility reductions enabled and disabled.
- Visual captures cover every phase, each crew, representative builds, interventions, elite, boss, and all terminal outcomes.
- Fresh Godot logs, performance checks, affected cumulative tests, and Windows/Web smoke are clean.

## Recommended parts

### Part A — Art direction and stage language

Approve reference boards/mockups, implement environment vocabulary, and remove release debug visuals.

### Part B — Combat feedback hierarchy

Polish the highest-value feedback events and validate readability at peak density.

### Part C — Transitions and platform polish

Complete state transitions, accessibility variants, optimization, capture, and platform smoke.

## GPT-5.6 Sol start prompt

```text
Use GPT-5.6 Sol with high reasoning. Implement the owner-approved WP06 World, Combat, and Presentation Polish in C:\Users\sith\Documents\Code\projectneon. Read the required repository documents in AGENTS.md order, the approved rebaseline and prior handoffs, then this complete work-package file. Audit the stage, debug drawing, combat presentation controllers, audio, accessibility settings, assets, and representative peak-density states. Produce an art-direction sheet and before/after mockups first, and obtain owner approval before a broad asset conversion.

Then replace release-visible debug arena cues with authored city-block depth while retaining logical lanes internally; implement the approved feedback hierarchy and phase transitions using replaceable assets and existing presentation ownership. Do not change gameplay balance or authority to make presentation easier. Validate screen-shake/hit-flash/damage-number/audio variants, peak readability, 1280×720 containment, performance, fresh Godot output, affected and cumulative tests, and Windows/Web exports. Capture the complete visual matrix and update owned docs/catalog. Preserve unrelated Godot-AI changes. Stop at the WP06 acceptance gate; do not commit, publish, or start WP07 unless asked.
```

## Durable `/goal`

```text
/goal Complete Neon Loop WP06 World, Combat, and Presentation Polish without stopping until the owner-approved art direction is implemented; release views read as authored neon city blocks with logical lanes/debug markers hidden; combat intent, impact, status, intervention, reward, boss, and phase transitions have distinct accessible feedback; representative peak-density states remain readable; the full visual matrix, performance evidence, cumulative tests, clean Godot output, and Windows/Web checks are complete; and gameplay authority/balance plus unrelated changes remain intact. Pause for art-direction approval and do not begin WP07 or publish externally.
```
