# WP05 Owner-Approved Production Handoff

Date: 2026-08-23

Pickup branch: `codex/wp05-interventions-handoff`

Baseline before WP05: `782f7fe18fa434d47020f1d4bc837c9c05790dad`

Status: implementation/focused/matrix evidence present; final verification and human gate remain

## Resume here

Check out `codex/wp05-interventions-handoff` and use its tip commit. Read, in order, `GameSpecifications.md`, `AGENTS.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, this handoff, `WP05_ACCEPTANCE_EVIDENCE.md`, and `WP05_OWNER_SELECTION.md`.

The owner replied **“Approved”** on 2026-08-23 to the exact Environment / Focus / Backup recommendation. Do not reopen mechanic selection unless the owner requests a change. This branch is not publication approval, does not start WP06, and does not satisfy any pending five-person gate.

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

## Required next work

1. Launch configured `/GameRun`, exercise Hydrant and Power Box contexts, Focus strong/hold/cutoff/race paths, both Backup charges, pause/resume, terminal, restart, and menu; inspect a fresh normal-user log.
2. Capture representative 1280×720 production evidence and inspect 2560×1440 containment. The existing `wp05_part_a_*` images are prototype evidence, not production captures.
3. Export Windows and Web release builds, run exported Windows, then test local production Web with real pointer input and an empty browser warning/error console.
4. Finish any lower-priority prose reconciliation in `CHANGELOG.md` and detailed catalogue/architecture historical sections; preserve historical M0–M6 numbers and label prospective WP05 facts correctly.
5. Run `WP05_UNBRIEFED_INTENT_VARIETY_CHECK.md` with five unbriefed participants. Do not infer a pass from automation. WP02/WP03/WP04 qualitative gates remain pending too.
6. Obtain separate owner authorization before any push, PR, merge, Pages publication/deployment, or WP06 work.

## Commands

```powershell
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_affected.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_focused.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_wp05_cumulative.gd
& 'C:\Users\sith\Documents\Code\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/probes/wp05_production_matrix_probe.gd
```

## Preservation and Git boundary

- The pre-existing Godot-AI 3.1.5 update remains exactly **57 dirty addon paths: 51 modified + 6 untracked**, with the original tracked diff of **4,791 insertions / 814 deletions**. It is intentionally excluded from the WP05 commit and must remain unstaged/unattributed.
- `project.godot` is not part of WP05 and remains untouched.
- No WP05 push, PR, publication, deployment, external message, or WP06 change is included.
- Before continuing, run `git status --short` and verify no unexpected staged path and the same addon preservation boundary.
