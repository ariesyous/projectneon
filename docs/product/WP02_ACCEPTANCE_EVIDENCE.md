# WP02 Acceptance Evidence

Status: **Technical/runtime/visual gate passed on 2026-08-21; five-person unbriefed comprehension gate pending owner execution.**

WP02 implements the approved three-lap district lifecycle and fresh-production crew access without beginning the WP03 District Plan migration. This record distinguishes executed evidence from the qualitative gate that cannot be inferred from automation or coding-agent review.

## Implemented authority

- `DistrictLoopDefinition` defines exactly three stable laps of three stable blocks, +6 Push Heat, lap pressure multipliers `1.00/1.15/1.30`, reward-tier implications `+0/+1/+2`, and named modifier/risk/next-threat copy.
- Run-owned `DistrictRunLifecycle` owns `SELECT CREW`, `INTRO`, `PLAN`, `BLOCK`, `FIGHT`, `REWARD`, `SHOP`, `LAP DECISION`, `EXTRACTION`, `BOSS`, and `RESULT`; stable lap/block IDs; lifecycle/decision revisions; exact decision tokens; accepted history; and boss commitment.
- Configured `/GameRun` reaches a lap decision only after blocks 3 and 6. The second Push commits to lap 3 and The Viper; block 9 enters the boss boundary. Night Pressure remains irreversible and contributes scaling, but configured pressure thresholds cannot bypass the 3 × 3 lifecycle.
- Invalid, stale, replayed, out-of-phase, paused, transition, and terminal requests are immutable rejections. UI forwards the exact authoritative token and never owns lifecycle state.
- The existing M5 `CardSystem`/`PatrolController` placement and route-effect contracts remain behind the WP02 shell. WP03 release-facing card scheduling and presentation are not implemented here.
- Fresh production access returns `jax`, `zoey`, and `rex` before the first gameplay draw. Version-1 serialized historical Zoey/Rex facts remain loadable, are not invented or rewritten on load, and their retired rules no longer gate or grant crew. Hacker Deck and Gang Hideout breadth rules remain active.
- Same-seed restart reuses the exact content-access snapshot and selected crew; new-seed/restart/menu/terminal paths clear district lifecycle, decisions, actors, effects, and modal state.
- Random schema remains 1 with the same seven named streams. District lifecycle and presentation consume no gameplay draw.

## Automated and configured runtime evidence

Executed with Godot `4.7.2.stable.official.ed1daf0bf`:

| Gate | Result |
| --- | --- |
| WP02 authority | 4/4 tests, 173 assertions, 0 failed, 0 skipped |
| WP02 affected | 27/27 tests, 495 assertions, 0 failed, 0 skipped |
| WP02 cumulative | 264/264 tests, 3,646 assertions, 0 failed, 0 skipped |
| Fixed-seed composed timing | PASS; lap decisions 121.267s/292.683s, boss 584.200s, boss result 599.883s |
| Configured `/GameRun` | Three crew, PLAN/pause/shop, lap-one Push, final commitment, boss/result, extraction, and cleanup passed |
| Release Windows export | Exit 0; fresh export log has 0 warnings and 0 errors |
| Exported Windows runtime | Hidden five-frame runtime smoke exited 0 |
| Release Web export | Exit 0; fresh export log has 0 warnings and 0 errors |
| Production Web runtime | Jax/Zoey/Rex visible; Rex pointer selection and PLAN start passed at 1280 × 720 and 2560 × 1440; warning/error console empty |

The timing gate uses fixed seed `6062026`, Rex's authored starter, no player intervention, and the ordinary composed `/GameRun` authorities at fixed 1/60-second gameplay steps. It uses no Heat, Pressure, damage, health, route, or random-stream accelerator. The fixed route retains its stable ID/node order and uses a 21.0-second represented approach. The exact eligible-time distribution was:

- complete-block gaps: `50.167, 21.000, 50.100, 86.783, 63.633, 21.000, 75.633, 124.400, 91.483` seconds; five within 45–90, two short shop outcomes, and two late final-lap fights;
- major gaps: `121.267, 171.417, 291.517` seconds; both actual lap decisions are within 120–180, while the disclosed final-lap-to-boss gap is late;
- ambient gaps: `27.100, 11.550, 11.517, 48.800, 14.083, 8.217, 48.617, 14.167, 14.017, 9.983, 27.650, 10.583, 13.400, 12.000, 48.650, 11.983, 12.000, 15.833, 8.167, 48.650, 10.500, 11.900, 12.150, 16.833, 14.650, 9.717, 27.650, 11.983, 12.000, 12.000, 18.017, 9.833` seconds; 20 within 10–20 and 12 disclosed outliers;
- The Viper boundary at 584.200 seconds and boss-result summary at 599.883 seconds, inside the 8–12-minute target.

This is one deterministic technical trace, not a representative timing distribution or qualitative acceptance result. WP07 and owner-led sessions still own broader distributions, outlier acceptance/tuning, and enjoyment judgments. The long-form runner emits its complete cadence JSON and fails unless the exact 3 × 3 lifecycle, two Push decisions, boss start/result, first two lap bands, and 8–12-minute result all hold.

The cumulative single-process runner retains the pre-existing M6 shutdown-only report of 48 ObjectDB instances and four resources still in use after its success summary. It is not present in the focused/affected/configured runtime or export/browser results, was not hidden, and remains the existing cleanup-audit item rather than a WP02 regression.

The export templates were taken from the official Godot 4.7.2 release into ignored project-local tooling; the bundle matched the official SHA-512 manifest. No global template installation, commit, push, publication, or deployment occurred during the implementation/evidence task. On 2026-08-21 the owner separately authorized the evidenced WP02 boundary for a `main` and GitHub Pages browser-playtest release.

## Visual and input evidence

Every image below was rendered and visually inspected. The first pass found and corrected clipped Push consequences and an overlapping result headline before the final captures were accepted.

- `res://docs/screenshots/wp02/wp02_plan_1280x720.png`
- `res://docs/screenshots/wp02/wp02_fight_arrival_1280x720.png`
- `res://docs/screenshots/wp02/wp02_reward_1280x720.png`
- `res://docs/screenshots/wp02/wp02_shop_1280x720.png`
- `res://docs/screenshots/wp02/wp02_lap_1_decision_1280x720.png`
- `res://docs/screenshots/wp02/wp02_final_lap_commitment_1280x720.png`
- `res://docs/screenshots/wp02/wp02_extraction_1280x720.png`
- `res://docs/screenshots/wp02/wp02_boss_1280x720.png`
- `res://docs/screenshots/wp02/wp02_result_1280x720.png`
- `res://docs/screenshots/wp02/wp02_final_commit_safe_area_1280x720.png`
- `res://docs/screenshots/wp02/wp02_final_commit_web_integer_2560x1440.png`
- `res://docs/screenshots/wp02/wp02_game_run_final_commitment_1280x720.png`

Mouse/touch-sized controls, visible keyboard focus, click/tap/keyboard intent parity, exact decision-token forwarding—including the preserved `E` extraction shortcut—safe-area containment, and 2× integer scaling are automated. Production Web pointer input was also exercised in the browser.

## Pending owner qualitative gate

No participant result is claimed. Use `docs/product/WP02_UNBRIEFED_COMPREHENSION_CHECK.md` with a designated five-person cohort. WP02 is fully accepted only when at least four of five independently identify the current phase, next event, available action, Extract/Push difference, and complete loop sequence, and predict the post-confirm state without coaching.

## Scope audit

WP02 added no card, equipment, crew, enemy, elite, boss, intervention, progression economy, permanent stat, procedural route, Autoload, random stream, or save version. Its implementation task did not publish or deploy; the separately authorized 2026-08-21 browser-playtest release changes no WP02 scope or acceptance result. WP02 did not implement the WP03 focused District Plan, WP04 rebalance, WP05 mechanics/content, or WP06 art pass. Owner-carried Godot-AI and `project.godot` changes remain preserved and unattributed.
