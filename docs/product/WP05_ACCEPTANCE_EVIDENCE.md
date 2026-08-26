# WP05 Acceptance Evidence — Prototype Decision and Production Handoff

Date: 2026-08-26
Status: **PASSED — production implementation and all remaining gates accepted by owner; merge/push and WP06 authorized**

## Provenance

- Baseline `HEAD`: published WP04 commit `782f7fe18fa434d47020f1d4bc837c9c05790dad`.
- Published Pages run supplied by owner: `32607599862`.
- Initial working tree: exactly 57 owner Godot-AI 3.1.5 paths, comprising 51 modified and six untracked; nothing staged.
- The addon footprint remains intact, unstaged, unattributed, and uncommitted. No `project.godot` or external-state mutation is attributed to WP05.
- WP02/WP03/WP04 human gates remain pending; no result is inferred.

## Part A implementation boundary

- Four typed development-only action definitions: Power Box, Hanging Sign, Focus priority, Rally reposition.
- Four typed fixed scenarios spanning early/middle/elite/boss contexts using only the existing five enemy IDs.
- One debug-created `WP05PrototypeRuntime`, deterministic non-authoritative telemetry ledger, and code-drawn world cues.
- One explicit `GameRun` development API; default configured `/GameRun` creates no prototype and release builds reject enablement.
- One existing-slot Environment presentation, enabled Focus shell, exact Backup request gate, and a separately labelled `4 DEV` Rally control.
- No production mechanic, content access, random stream/schema, save field, project setting, Autoload, reward/economy, or progression change.

## Automated evidence

Executed with Godot `4.7.2.stable.official.ed1daf0bf` and normal `user://` access:

| Gate | Result |
| --- | --- |
| WP05 Part A focused | **13/13 tests, 180 assertions, 0 failed, 0 skipped** |
| WP05 Part A cumulative | **304/304 tests, 4,373 assertions, 0 failed, 0 skipped across 32 suites** on final run; one clean repeat 4,372 |
| Configured matrix | **60 rows: 3 crew × 4 contexts × 5 policies** |
| Same-seed repeat | **PASS — Zoey/elite/Focus gameplay projection identical** |
| Presentation isolation | **PASS — 50 extra cosmetic draws changed no gameplay projection** |
| Configured headless `/GameRun` | **PASS — no parser/runtime error or warning** |

Per-suite diagnostic output showed the 4,372/4,373 difference in inherited `wp02_state_clarity` (99/100 assertions) and `milestone_6_game_run` (160/161) as generated/runtime branches changed. Every cumulative execution ran the same 304 tests with zero failures/skips. No WP05 suite count varied; Part A remains exactly 180 assertions.

Focused coverage includes typed catalogue validation; one-slot context replacement; Power Box interruption/Shock; Hanging Sign one-charge burst/exhaustion; Focus target/revision/token acquisition, priority, expiry, death, cooldown, stale/replay/invalid paths; Rally defensive validity, displacement, attack sacrifice, cooldown/replay; Backup request gate, finite authority, rollback inheritance, replay, and late-use hold; pause/terminal/restart; unseeded-RNG scan; exact UI forwarding; default-surface restoration; and 1280×720 containment.

The cumulative runner prints the exact inherited post-success signature of 48 ObjectDB instances and four resources in use. The accepted WP04 runner and prior evidence record the same signature. Focused and configured production boots do not reproduce it; it was not hidden or relabelled.

## Configured graphical and input evidence

- The graphical project launched the configured main scene with runtime root `/GameRun` at 1280×720.
- The middle Power Box scenario showed one Environment slot with changed icon/`BREAKER` verb, exact marked 96px area, target count, revision/token copy, Focus/Backup, strategic Subway absent, and Rally separately labelled `4 DEV`.
- Initial inspection found and repaired Help/tutorial obstruction, inherited Hydrant effect copy, title/verb clipping, Focus intent clipping, and misleading frozen Backup validity.
- The corrected elite capture shows Power Box, ready `3 BACKUP`, Focus target/intent/window, and contained Rally without overlay competition.
- Saved evidence: [Focus opportunity](../screenshots/wp05_part_a_focus_1280x720.png) and [active Rally comparison](../screenshots/wp05_part_a_rally_1280x720.png).
- Real pointer press/release on Focus at Bottle Thrower's 0.62s windup produced exactly one telemetry use and changed Jax's automatic target to `bottle_thrower`.
- Real keyboard `2` on a fresh frozen opportunity produced the same one use and `bottle_thrower` target. Mouse/touch/keyboard native Buttons forward the same stored target/attack/revision/token snapshot. No UI method calculates an effect.
- A development-only deterministic opportunity freeze was used solely to inspect/click a sub-second window; it is not gameplay tuning or acceptance evidence.
- The final current-run game log contains only helper registration and no warning/error. The editor Debugger lists eight pre-existing GDScript warnings in `attack_position_registry.gd`, `neon_intervention_button.gd`, pre-existing `GameHUD` helpers, `vertical_slice_overlay.gd`, and the pre-existing `GameRun` seed parameter; each exact declaration is present at baseline `HEAD`. They are inherited editor-reload diagnostics, not hidden or attributed to WP05.

## Research and decision evidence

`WP05_RESEARCH_AND_DECISION_RECORD.md` records sources, applicable findings, rejected lessons, and Neon Loop implications. `WP05_PROTOTYPE_COMPARISON.md` records exact tuning, strong/weak/invalid/hold/counter cases, the matrix, dominance counts, crew/build interactions, and risks. `WP05_CURRENT_TO_TARGET_AUTHORITY_MAP.md` freezes ownership. `WP05_OWNER_SELECTION.md` is the one required checkpoint.

## Honest boundary

- No five-person intent/variety result exists. Use `WP05_UNBRIEFED_INTENT_VARIETY_CHECK.md` only after the selected production build exists.
- Current short intent windows are a human readability risk, not a pass.
- The 60-row six-second matrix is deterministic comparison evidence, not fight/block/run timing acceptance or enjoyment evidence.
- Windows/Web export/runtime/browser gates belong to completed Part B/C; they are not claimed at this Part A checkpoint.
- No commit, push, publication, deployment, external message, or WP06 work was performed.

## Owner-approved production implementation — 2026-08-23

The owner replied **“Approved”** to `WP05_OWNER_SELECTION.md`, selecting Environment / Focus / Backup without tuning changes. The implementation now includes:

- `EnvironmentController`: one encounter-authored `fire_hydrant` or `power_box` context; monotonic revision/request-token validation; immutable malformed/stale/replay/wrong-context rejection; one shared eligible-time cooldown ledger that survives pauses, contextless reward/travel, and multiplier changes.
- Fire Hydrant preserved at 112px, 18 damage, 300-force/0.30s fixed-left knockback, Wet 4s, and 8s base cooldown.
- Power Box at 96px, 4 base Environment damage, 1.0s authored stun before actor resistance/caps, base Shock 3s with existing build duration modifiers, and 12s base cooldown. It becomes valid only for a named interruptible windup in the footprint, then affects the marked cluster.
- `FocusController`: stable live-threat ranking, exact target/attack/revision/token acceptance, 0.35s live cutoff revalidation, 3.0s automatic target priority, 10s base cooldown, current-attack commitment protection, named result, target-death/expiry/terminal/restart cleanup, and no direct damage/stun/movement/attack command.
- Exact prospective tell windows: Bat 0.90s, Bottle 0.95s, Enforcer charge 1.00s, Viper charge 1.05s, Viper summon 1.10s, Viper area 1.10s. Street Punk remains 0.31s and Focus-ineligible.
- Backup caller hardening without changing its existing 2 allies / 2 charges / 12 combat seconds / 30s base authority, rollback, crew/Tech scaling, or no-recharge rule.
- Configured combat keys and bar are exactly `1 Environment`, `2 Focus`, `3 Backup`; Subway is strategic travel. Rally, Hanging Sign, key 4, and Part A GameRun enable/freeze seams are removed from configured release composition.
- Encounter contexts use the bounded existing roster: Alley/Hydrant; Arcade, Viper Signal, and Viper Showdown/Power Box. No actor, card, equipment, status ID, reward/economy, save field, random stream, schema, project setting, or progression entry was added.

### Current production evidence

| Gate | Result |
| --- | --- |
| WP05 production focused | **18/18 tests, 381 assertions, 0 failed, 0 skipped** across authority, post-selection HUD isolation, configured GameRun, pointer/touch/keyboard, pause, terminal, restart, and menu cleanup |
| WP05 affected | **64/64 tests, 911 assertions, 0 failed, 0 skipped** after Help containment/compatibility repair |
| WP05 cumulative with normal `user://` access | **319/319 tests, 4,734 assertions, 0 failed, 0 skipped across 34 suites**; inherited 48-ObjectDB/four-resource aggregate shutdown diagnostic remains |
| Production encounter matrix | **60 rows: 3 crew × 4 contexts × 5 policies** using the exact disjoint WP04 builds |
| Matrix repeat | **PASS** — Zoey/elite/Focus projection identical |
| Cosmetic isolation | **PASS** — 50 extra `cosmetic` draws changed no gameplay projection; schema remains 1 |
| Dominance/hold signal | Environment: 9 better/equal + 3 tradeoffs; Focus: 1 better/equal + 8 same + 3 tradeoffs; immediate Backup: 12 better/equal; late Backup: 12 same with only 0.183s expression and one finite charge spent |
| Configured headless boot | **PASS** with no task parser/runtime diagnostic; sandbox-only log/root-certificate access messages still require a normal-user fresh-log rerun |

The live matrix probe is `res://tests/probes/wp05_production_matrix_probe.gd`. The old Part A GameRun probe path now prints an archive pointer rather than recreating removed release seams.

## Final owner acceptance — 2026-08-26

The project owner explicitly reported **“All the gates pass”** and authorized WP05 finalization, merge/push, and the start of WP06. This closes the configured fresh-log, production visual/containment, real-input, Windows/Web, and five-person unbriefed intent/variety gates listed in the handoff.

The owner's statement is the authoritative gate decision. This repository session was not supplied the underlying participant rows, quotations, device/browser matrix, captures, export run identifiers, or timing distributions, so this record does not fabricate those details. The exact automated evidence remains **18/18 focused / 381 assertions**, **64/64 affected / 911 assertions**, and **319/319 cumulative / 4,734 assertions across 34 suites**, plus the repeatable/cosmetic-isolated 60-row production matrix. The inherited aggregate-only 48-ObjectDB/four-resource shutdown diagnostic remains disclosed and accepted; focused/configured/platform paths do not relabel it.

WP05 is complete. WP06 is separately authorized to begin. WP02/WP03/WP04 qualitative records remain unchanged by this decision.
