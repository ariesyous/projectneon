**Playability repairs — 2026-09-18 — local, unpublished**

The owner authorized proceeding through the project-state audit. This first implementation boundary repaired encounter cleanup and decision-screen clarity on `codex/playability-repairs`. After that verified boundary, the owner explicitly chose substantially shorter runs while keeping the finite card rules. The continuation is recorded in [short-run pacing](SHORT_RUN_PACING_2026-09-18.md); its timing revision is explicit in `GameSpecifications.md` section 0.9. The verification below remains the initial cleanup/clarity record.

Implemented behavior:

- A projectile whose source is unregistered is hidden and removed from the live ledger synchronously, before a final kill can disable simulation. Completed-encounter/terminal boundaries also clear remaining in-flight attacks. Ordinary pause preserves live projectile state.
- A production world warning observes the exact actor and attack. It retires when windup ends or is interrupted, follows the authoritative remaining windup through hit-stop, and clears at reward/shop/lap/terminal/PLAN boundaries. Ordinary pause/resume, including isolated historical standalone warning fixtures, remains supported.
- Completed focused-plan fights settle pending coin clusters through the existing base-value, stable-order, exact-once authority. The last coin can no longer sit behind decisions with a frozen 2.5-second countdown. No new bonus, spend rule, stream, or profile fact is introduced.
- PLAN/reward/shop/lap decisions use opaque panels and a dimming input blocker below them. Pointer events cannot reach the obscured HUD/world. PLAN shows short complete consequences, `CONFIRM BLOCK` and `CLEAR` fit their actual content areas, the shop is named `SHOP + COOLING`, and Night Pressure says `NO COOLING` instead of `LOCKED`.
- Selected crew buttons use the shared pressed style, restoring readable contrast.

Verification on Godot 4.7.2:

- New repair regressions: **5/5 tests, 35 assertions**, zero failures/skips, after first reproducing all five failures against the original behavior.
- WP06 focused presentation suites: **15/15 tests, 281 assertions**, zero failures/skips. The final warning implementation holds only its `AttackController` timeline; a comparison against an isolated baseline helped identify and remove an extra script-resource shutdown diagnostic introduced by the earlier broader actor/resource binding.
- Preserved cumulative suites: **319/319 tests, 4,734 assertions**, zero failures/skips. The inherited aggregate-only 48-ObjectDB/four-resource shutdown signature remains disclosed.
- Real native GUI event routing: District Plan keyboard/touch selection and confirmation passed; reward/shop keyboard, touch, and mouse checks passed.
- Configured `/GameRun`: native pointer crew/start, plan select/confirm, a controlled encounter completion through the normal authorities, real Skip Gear input, and the next PLAN passed. The next PLAN had **zero projectiles, zero visible warnings, and zero pending coin clusters**. This controlled completion is cleanup/visual evidence, not a timing or unbriefed-play result. The configured game log contained only helper registration, with no runtime error.
- Inspected native 1280×720 [PLAN](../screenshots/playability_repairs/plan.png), [reward](../screenshots/playability_repairs/reward.png), and [next PLAN](../screenshots/playability_repairs/next_plan.png) captures. Labels fit and no world content shows through the decision panel.
- `git diff --check` passed. The owner-carried addon and `project.godot` changes were preserved; the canonical specification was not rewritten.

The first sandboxed cumulative attempt could not write its isolated persistence fixtures; it also found an ordinary-pause compatibility regression, which was repaired without removing the historical assertion. Subsequent execution was allowed to write the existing isolated test fixtures under the Godot user-data directory. The host still lacks Godot 4.7.2 export templates, so fresh exported-Windows and browser-release results are not claimed. Ten existing editor source warnings (unused/shadowed names and integer division), the host certificate-store diagnostic in sandboxed headless runs, and the inherited aggregate shutdown diagnostic remain visible and were not suppressed.

The published WP06 boundary and pending WP02/WP03/WP04 participant records remain unchanged. No commit, push, deployment, new content, permanent progression, or completed WP07 acceptance is claimed.
