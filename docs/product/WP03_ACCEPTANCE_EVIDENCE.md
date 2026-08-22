# WP03 Acceptance Evidence

Date: 2026-08-22

Status: technical/runtime/visual/platform gate passed; owner-run unbriefed first-use gate pending

WP03 replaces the production Milestone 5 hand/five-slot planner with the approved focused next-block District Plan. On 2026-08-22 the owner separately authorized this exact evidenced boundary for a `main` and GitHub Pages browser-playtest release. Publication is a playtest decision only: no WP04 work or qualitative acceptance is claimed.

## Authority and deterministic evidence

- `CardSystem` owns a one-copy accessible lap deck, an offer capacity of two, unselected-card retention, deterministic refill without replacement, current/archived resolved history, exact lifecycle context, staged confirmation, and exact-once selection/effect ledgers.
- Production INTRO consumes no hidden card draw. PLAN is the visible draw boundary.
- Locked schema-1 vector: seed `30301` with four-card access offers `[gang_hideout, subway_entrance]` using only `cards`.
- Perturbing `cosmetic` does not alter that vector; the other gameplay stream snapshots remain unchanged by card selection.
- Stale offer/lifecycle revisions, wrong stable lap/block IDs, malformed requests, confirmation replay, effect replay, wrong phase, unsafe-transition races, restart, and menu cleanup are covered as mutation-free rejection paths.
- `RunDirector.notify_safe_transition_boundary()` still runs before focused card dispatch, so lap decisions and the block-nine boss boundary cannot be bypassed. Cards never lower Night Pressure or alter decision/boss-commitment ledgers.
- A configured focused-dispatch matrix forces each stable ID into a deterministic production offer and verifies its live authored outcome: Arcade starts a standard-only fight and advances one authored reward tier; Convenience Store opens a one-purchase finite visit; Gang Hideout starts `viper_signal` and guarantees equipment; Subway Entrance completes a no-combat block without consuming an intervention charge. Each case applies Heat once, resolves one matching history entry, consumes no extra `cards` draw, and cannot recurse into the removed hand reward.
- Same-seed restart rebuilds the same offer with the same content-access snapshot; random schema remains 1 and no profile/save version changes.

Migration details: [WP03_CURRENT_TO_TARGET_AUTHORITY_MAP.md](WP03_CURRENT_TO_TARGET_AUTHORITY_MAP.md).

## Automated results

| Gate | Result |
| --- | --- |
| Focused WP03 authority | **5/5 tests, 130 assertions, 0 failed, 0 skipped** |
| Isolated release-snapshot affected card/UI/lifecycle/layout | **72/72 tests, 1,388 assertions, 0 failed, 0 skipped** |
| Isolated release-snapshot cumulative M0–M6 + WP01–WP03 | **274/274 tests, 3,919 assertions, 0 failed, 0 skipped across 27 suites** |
| Native GUI input routing | **PASS — keyboard select/confirm and touch select/confirm** |

The canonical cumulative command required normal Godot `user://` access because the persistence suite writes disposable fixtures there. A sandbox-only attempt correctly failed those filesystem-dependent assertions and is not acceptance evidence. The canonical run exited 0.

After its successful summary, the aggregate runner still emits the pre-existing 48-ObjectDB/four-resource shutdown diagnostic recorded at WP01/WP02. Focused, affected, configured runtime, native visual, export, exported-Windows, and browser runs do not reproduce it; it was neither hidden nor reclassified.

## Configured runtime and visual evidence

The configured `/GameRun` native smoke passed:

`WP03_GAME_RUN_SMOKE=PASS offer=2 predict=pass confirm/heat=pass resolved/recognized=pass next-plan=pass insufficient=1 replay/cleanup=pass`

It exercised a production-profile access snapshot, mandatory PLAN pause ownership, native choice buttons, exact prediction, confirmation and Heat, replay rejection, real patrol dispatch, matching effect recognition, completed-history recall, natural one-choice block-three handling, next PLAN, and synchronous menu cleanup.

- [Selected next-block prediction](../screenshots/wp03/wp03_game_run_plan_prediction_1280x720.png)
- [Recognized consequence and resolved history](../screenshots/wp03/wp03_game_run_recognized_history_1280x720.png)
- [Natural one-choice block-three state](../screenshots/wp03/wp03_game_run_insufficient_choice_1280x720.png)

The images were inspected at native 1280×720. They show long authored copy contained with ellipsis/tooltips, clear visible selection, exact block/Heat/special prediction, no close/decline path for the mandatory choice, no route-slot targets, and one-card centering without empty controls or deadlock. “Decline/back” is not applicable: District Plan is a required safe-boundary choice, and ordinary pause cannot bypass it.

The first Web pass exposed a legacy run-controls tutorial banner over the paused plan. WP03 now dismisses legacy queued banners synchronously when focused PLAN opens; the complete teaching copy lives on the decision surface. Automated coverage asserts that no tutorial/help layer obscures first-use prediction.

## Export and platform evidence

- Godot 4.7.2 Windows Desktop release export: passed.
- Godot 4.7.2 Web release export: passed.
- The isolated Windows and Web `.pck` payloads were both produced at `1,433,788` bytes. Their platform export hashes were Windows `DFE58A971374B6ABF77340B86677D9DFB6D63605A8E331E18736C948B93EB39C` and Web `9ADB4DD6D964D580257A4F2D0779FEE4704BAE7C68ED35DF3C3F1022CCA46E49`.
- Exported Windows headless runtime: exit 0 with no warning/error output.
- Local production Web at 2560×1440: real pointer selected Convenience Store, displayed `PREDICTION • NEXT: SHOP + RECOVERY • HEAT -10`, confirmed once, displayed `NEXT BLOCK: CONVENIENCE STORE`, entered `SHOP / CONVENIENCE STORE`, left the shop, and opened block two with `B1 CONVENIENCE STORE COMPLETED` in history.
- The browser warning/error console remained empty throughout selection, occurrence, completion, and next PLAN.
- Fresh configured native boot and explicit runtime logs contain no new parser, runtime, warning, or debugger entry.

## Input parity and release cleanup

- Choice cards and confirmation are native focusable Buttons with at least the 48-pixel touch target.
- Mouse click, tap activation, and keyboard focus/activation forward the same exact stable ID, offer revision, lifecycle revision, lap ID, and block ID.
- `wp03_input_parity_smoke.gd` routes `ui_accept` and `InputEventScreenTouch` through Godot's live GUI input dispatcher and passes selection plus confirmation for both modalities. The separate production-Web run covers real pointer input.
- Double activation emits one authoritative intent; replay is rejected before Heat/effect mutation.
- Production choice cards are not drag sources. The old five-target drag/legality model remains historical test compatibility only.
- The release surface contains no hand capacity, draw pile, future-slot validity, route-dot, card-reward, or `Skip / Keep Hand` clutter.

## Remaining owner gate

Automated and coding-agent evidence cannot establish that an unbriefed human understood the interaction. The owner must run and sign [WP03_UNBRIEFED_FIRST_USE_CHECK.md](WP03_UNBRIEFED_FIRST_USE_CHECK.md). Until then, do not describe WP03 as owner-accepted or claim that the 4/5 qualitative consequence threshold passed.
