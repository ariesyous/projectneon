# WP05 Owner-Approved Production Handoff

Date: 2026-08-23

Pickup branch: `codex/wp05-interventions-handoff`

Baseline before WP05: `782f7fe18fa434d47020f1d4bc837c9c05790dad`

Status: **closed — all WP05 gates passed by owner record on 2026-08-26**

## Resume here

This file preserves the implementation handoff that preceded final acceptance. Read `WP05_ACCEPTANCE_EVIDENCE.md` for the closing decision and use the finalized `main` tip as the WP06 baseline.

The owner replied **“Approved”** on 2026-08-23 to the exact Environment / Focus / Backup recommendation. On 2026-08-26 the owner then reported **“All the gates pass”** and authorized WP05 finalization, merge/push, and WP06. Do not reopen mechanic selection unless the owner requests a change.

## Implemented boundary

- One production `EnvironmentController` owns the encounter context, monotonic caller revision/token, immutable rejection, and shared eligible-time cooldown.
- Fire Hydrant remains exact. Power Box is a 96px context object with 4 damage, interrupt/stun, base three-second Shock, 12-second base cooldown, authored icon/verb/VFX, and a live named-windup validity requirement.
- One production `FocusController` ranks the exact eligible live intent, revalidates target/attack/revision/token plus the 0.35s cutoff, applies three seconds of automatic target priority, protects already committed crew actions, and owns cooldown/result/cleanup.
- Backup retains its existing finite transaction and adds exact caller revision/token validation plus whole-run scarcity copy.
- Bat/Bottle/Enforcer/Viper tells use the owner-approved prospective windows and explicit intent labels/world markers. Street Punk stays at 0.31s and is not Focus eligible.
- Configured bar/keys are `1 Environment`, `2 Focus`, `3 Backup`. Subway remains travel. Rally, Hanging Sign, key 4, and Part A GameRun enable/freeze seams are absent from release composition.
- Alley uses Hydrant. Arcade, Viper Signal, and Viper Showdown use Power Box. The roster, caps, rewards, economy, profile, schema 1, and declared streams are unchanged.
- Isolated `wp05_proto_` definitions/runtime/tests and the two Part A screenshots remain as archived decision evidence only.

## Evidence at shutdown

- Production focused: **18/18 tests, 381 assertions, zero failures/skips**.
- Production matrix: **60 rows** (3 crew × 4 contexts × 5 policies), exact disjoint WP04 builds, exact repeat passed, 50 extra cosmetic draws isolated.
- Matrix outcome: Environment 9 better/equal and 3 tradeoffs; Focus 1 better/equal, 8 same, 3 tradeoffs; immediate Backup beneficial in 12/12; late Backup identical to hold in 12/12 after spending a charge for only 0.183s expression.
- A restricted-sandbox cumulative attempt reported 312/319 because two Help checks needed repair and five persistence tests could not access `user://`. After the Help repair, the affected gate passed **64/64 tests / 911 assertions**. A normal-access cumulative rerun then passed **319/319 tests / 4,734 assertions across 34 suites**, with zero failures/skips.
- The cumulative runner reproduced the inherited post-success **48 ObjectDB / four-resource** aggregate diagnostic.
- Configured headless boot and the focused run had no task parser/runtime error. Restricted-sandbox log/root-certificate messages are not a clean-log pass.

## Closure and successor

- The owner attested that every remaining fresh-log, visual/containment, input, Windows/Web, and five-person gate passed. Raw observation/platform details were not supplied here and are not invented.
- WP05 is authorized for merge/push. A Pages deployment is claimed only after its workflow result is observed.
- WP05 was subsequently fast-forwarded to `main` at `37ebc9d`; Pages run 32931503114 completed successfully.
- WP06 World, Combat, and Presentation Polish is authorized to begin from finalized `main` under `docs/work_packages/WP_06_WORLD_COMBAT_POLISH.md`.
- WP07 remains unauthorized until WP06 reaches its acceptance gate and the owner explicitly proceeds.

## Commands

```powershell
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_affected.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_focused.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_cumulative.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/probes/wp05_production_matrix_probe.gd
```

## Preservation and Git boundary

- The WP05 start snapshot had **57 dirty addon paths: 51 modified + 6 untracked**, with **4,791 insertions / 814 deletions**. At finalization on 2026-08-26, the owner's live tooling work had advanced to **66 addon paths: 53 modified + 13 untracked**. Both snapshots are provenance facts; all addon changes remain excluded from WP05.
- `project.godot` is not part of WP05. Its current Autoload-order-only owner diff remains dirty and excluded.
- The owner authorized the WP05 merge/push and WP06 transition on 2026-08-26. The owner-carried addon remains outside WP05 history.
- Before continuing, run `git status --short` and verify no unexpected staged path and the same addon preservation boundary.
