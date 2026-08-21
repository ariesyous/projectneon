# WP01 Acceptance Evidence — Interface and Visual Language

Status: **complete for the enumerated WP01 technical/visual acceptance gate — 2026-08-21**

This evidence records the owner-authorized WP01 implementation against the WP00-canonical target. It does not claim the separate owner-coordinated five-person unbriefed checkpoint, Milestone 6 final playtest acceptance, WP02 lifecycle authority, WP03 District Plan authority, WP05 Focus behavior, or WP06 final art.

## Current-to-target conversion map

| Previous M6 presentation | WP01 result | Authority boundary |
| --- | --- | --- |
| Broad simultaneous dashboard and route wall | Phase banner, compact resource/crew/build surfaces, clear combat center, focused inspect paths | Snapshot presentation only; route authority unchanged |
| Text-first current interventions | Shared icon + role + action + textual status controls | Hydrant/Backup authorities unchanged; Focus is disabled because none exists; Subway stays strategic travel |
| Card/equipment rules always near combat | Compact District Plan/build entry; detailed current M5/M6 interaction opens only on demand | Hand/five-slot planner and inventory revision/token contracts unchanged |
| Shop/extraction actions embedded in the generic strip | Focused finite-shop and current Extract/Push shells with exact before/after copy | Existing typed cooling, continuation, and extraction intents only |
| Inline scene-specific colors/styles | Shared typography/spacing/surface/border/semantic/focus/disabled/motion tokens | No gameplay data references the theme |
| Text-only state and browser-default disclosure | Replaceable SVG icon family, custom tooltip, non-color labels/shapes, visible focus | Icons and tooltips are presentation assets only |
| Flat statistic-first result | Outcome/build/highlight hierarchy before complete preserved statistics | `RunSummaryRecord` remains authoritative and complete |

## Acceptance matrix

| WP01 criterion | Evidence | Result |
| --- | --- | --- |
| One reusable language across combat, plan, reward, shop, pause/settings, Extract/Push, summary | `NeonUiTokens`; seven reusable components; eight-state gallery | Pass |
| Phase, next event, immediate action, health, Heat, Night Pressure visible in stills | Combat capture and configured `/GameRun` capture | Pass |
| No persistent card/equipment rule wall in combat | Minimap hidden; compact build/plan entries; focused modal disclosure | Pass |
| Non-color cues | READY/COOLDOWN/UNAVAILABLE/SELECTED/HIGH RISK text, borders, pressed state, icons/shapes | Pass |
| Long names, focus, touch, containment | Ellipsis + full tooltips; focus outlines; 48-pixel minimums; automated native/safe-area audit | Pass |
| Presentation-only, authority intact | No gameplay-owner edit; random-stream snapshot invariant; complete M0–M6 suite preserved | Pass |
| Fresh runtime and cumulative checks | Clean configured `/GameRun` log; 254/254 tests and 3,376 assertions | Pass |

## Visual evidence

Native 1280×720 representative states:

- [Combat](../screenshots/wp01/wp01_combat_1280x720.png)
- [District Plan presentation shell](../screenshots/wp01/wp01_plan_1280x720.png)
- [Equipment reward](../screenshots/wp01/wp01_reward_1280x720.png)
- [Shop](../screenshots/wp01/wp01_shop_1280x720.png)
- [Extract or Push](../screenshots/wp01/wp01_extract_1280x720.png)
- [Pause](../screenshots/wp01/wp01_pause_1280x720.png)
- [Settings and accessibility](../screenshots/wp01/wp01_settings_1280x720.png)
- [Summary](../screenshots/wp01/wp01_summary_1280x720.png)

Runtime/scaling:

- [Configured `/GameRun` patrol](../screenshots/wp01/wp01_game_run_patrol_1280x720.png)
- [Native 32/24 safe-area combat](../screenshots/wp01/wp01_combat_safe_area_1280x720.png)
- [Supported 2× Web integer scale at 2560×1440](../screenshots/wp01/wp01_combat_web_integer_2560x1440.png)

Visual review checked hierarchy, central combat readability, long/dynamic copy, focus outlines, selected/disabled/high-risk differentiation, touch-size affordances, icon-label pairing, non-color consequences, tutorial/action-strip separation, top-panel/safe-area containment, and progressive disclosure. Pixel review found and corrected Pressure wrapping, Environment/Focus/Hydrant clipping, safe-area overlap, excess combat-strip width, and tutorial/action overlap before this record was finalized.

## Automated evidence

Command: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_wp01_cumulative.gd`

Result: **254/254 tests, 3,376 assertions, zero failures, zero skips across 23 suites.** This is the complete accepted 244-test Milestone 0–6 baseline plus 10 WP01 tests covering tokens, components, icons, combat hierarchy, focused shop/Extract shells and typed intents, safe area, overlay focus/hierarchy, long names, the state matrix, and random-stream immutability.

The cumulative harness repeats the already documented Milestone 6 shutdown-only report of 48 ObjectDB instances and four resources after its successful summary. The configured production-scene smoke below does not reproduce it; WP01 neither introduced nor suppressed that baseline diagnostic.

## Configured `/GameRun` evidence

`res://tests/visual/wp01_game_run_smoke.gd` instantiated the configured `res://scenes/game/game_run.tscn` composition and exercised:

1. selected-crew start and authored intro into safe patrol;
2. build inspect/open/close progressive disclosure;
3. current District Plan open/close through the preserved planning authority;
4. invalid Backup/Hydrant requests and immutable textual feedback;
5. pause, settings, Back, and Resume with visible keyboard focus;
6. native safe-area geometry and final runtime capture.

The fresh `.godot/wp01_game_run.log` contains the engine/renderer header and Godot-AI registration only—no parser error, script error, runtime error, warning, or debugger entry.

## Scope/provenance audit

- No run, combat, reward, card, equipment, persistence, content Resource, or random-stream owner changed.
- Random schema remains version 1 with the same seven streams and unchanged draw state through UI presentation.
- WP02 lap/block/crew-default work, WP03 card scheduling/authority migration, WP05 Focus mechanics, WP06 stage art, and unrelated refactors were not implemented.
- The owner-carried Godot-AI update and `project.godot` changes remain preserved and unattributed.
- No commit, push, publish, deployment, external message, or profile-setting write occurred.
