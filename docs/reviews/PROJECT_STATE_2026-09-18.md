**Neon Loop project-state audit — 2026-09-18**

The project has a substantial, testable gameplay foundation, but its current experience spends too much time between meaningful events and asks the player to interpret too much implementation-oriented text. The reported stuck visuals have reproducible lifecycle causes. Further presentation detail alone will not resolve the pacing, choice, and payoff problems.

This review used `main` at `62f203db6ef0bb2a2e7c0b207470693a3d69e946` (documentation after WP06 gameplay commit `224ed5c`), Godot 4.7.2, source inspection, real native pointer input through the first fight/reward/next PLAN, six deterministic first-lap probes, one complete fresh-profile run, and two controlled effect reproductions. The owner-carried Godot-AI 4.1.0 working-tree changes and Autoload ordering were preserved. Gameplay, authored Resources, scenes, and settings were not edited. This audit does not start WP07 or change any historical owner acceptance.

1. **Confirmed bug: projectiles can freeze after the last enemy dies.**

   A Bottle Thrower can launch a projectile and die before the projectile resolves. Normal encounter completion immediately enters REWARD_SELECTION. `RunFlowController` disables combat simulation, and `CombatDirector.step_simulation()` returns before its projectile pass can remove the projectile whose source just died. Ordinary encounter completion does not clear that projectile list. It remains visible throughout the reward screen and subsequent PLAN, until eligible simulation resumes or run cleanup occurs.

   In a controlled one-Bottle-Thrower fixture, the authored attack created one projectile. Killing that final enemy produced REWARD_SELECTION with zero enemies and one projectile. After 300 attempted 1/60-second combat updates, its remaining lifetime was still **2.500 seconds**. This is a reproducible lifecycle defect, not evidence of a GPU rendering problem.

   Relevant code: [combat early return](../../scripts/combat/combat_director.gd#L109), [projectile invalidation](../../scripts/combat/combat_director.gd#L459), [state-to-simulation wiring](../../scripts/run/run_flow_controller.gd#L709). Repair the encounter-end cleanup path and cover the actual final-kill → reward → PLAN sequence. Preserve projectiles across an ordinary pause inside an unfinished fight.

2. **Confirmed bug: obsolete attack warnings can be suspended indefinitely by PLAN.**

   `CombatTelegraph` owns a copied position and duration, with no live association to the originating attacker or attack. Killing/interruption does not cancel it. `GameRun` suspends all existing telegraphs on every PAUSED transition, including the mandatory District Plan pause, and only explicitly clears them on selected terminal/restart/menu paths.

   In a separate fixture, a final Bottle Thrower began its ordinary windup and was defeated. Immediately declining its equipment reward entered the real next PLAN. The warning remained suspended with **0.950 seconds** left after five seconds of presentation updates. A slower reward decision lets this warning expire, which explains why this symptom is intermittent.

   Relevant code: [warning creation](../../scripts/run/game_run.gd#L1478), [pause handling](../../scripts/run/game_run.gd#L658), [warning expiry](../../scripts/effects/combat_telegraph.gd#L61). Bind warnings to threat validity and clear obsolete warnings at encounter boundaries. Treat PLAN separately from pausing a live attack.

   There is also a **confirmed presentation contributor**: the final coin cluster remains visible behind rewards/PLAN while its authoritative collection clock is stopped. The native reward capture showed `CLICK / TAP 2.5s`; the same cluster remained behind the next PLAN minutes later. Base rewards remain protected; the frozen countdown looks broken. Resolve its presentation at decision boundaries while preserving exact-once coin accounting. See [reward timer](../../scripts/rewards/reward_director.gd#L127) and [coin countdown](../../scripts/interactables/coin_cluster.gd#L126).

3. **Measured pacing problem: most early eligible time has no live enemy.**

   The fixed route takes **21 seconds per approach**, and ordinary encounters wait **3 seconds** before the first spawn and **12 seconds** between later spawns. Early enemies die much faster than that interval. The encounter may last approximately 30 seconds while containing only eight to ten seconds of actual enemy presence.

   All rows below use seed `6062026`, authored crew starters, no interventions, skipped gear, no shop purchases, and a fixed card preference of Arcade → Gang Hideout → Convenience Store → Subway. Modal thinking time is excluded. These are deterministic diagnostic samples, not participant observations or representative distributions.

   | Access | Crew | First lap | Travel | Fight-state time | No enemy inside fights | Share of lap without a live enemy |
   | --- | --- | ---: | ---: | ---: | ---: | ---: |
   | Fresh production | Jax | 92.783s | 63.000s | 29.783s | 20.017s | 89.5% |
   | Fresh production | Zoey | 92.250s | 63.000s | 29.250s | 21.217s | 91.3% |
   | Fresh production | Rex | 92.183s | 63.000s | 29.183s | 21.183s | 91.3% |
   | Full catalogue | Jax | 157.017s | 63.000s | 94.017s | 59.417s | 78.0% |
   | Full catalogue | Zoey | 157.017s | 63.000s | 94.017s | 45.083s | 68.8% |
   | Full catalogue | Rex | 157.250s | 63.000s | 94.250s | 54.300s | 74.6% |

   “Without a live enemy” includes intentional shop/transit approach and spawn gaps; it is not a claim that every such second must contain combat. The proportions nevertheless explain the weak sense of momentum. A countdown makes a wait understandable but does not make it interesting.

   The fresh-profile Rex continuation reached lap decisions at **92.183s and 184.283s**, the boss at **293.017s**, and Defeated at **329.583s**. It used starter gear, skipped rewards, bought nothing, used no interventions, and pushed twice. The ordinary fights lasted 29.183s, 29.100s, and 45.733s. This current path differs materially from the preserved pre-WP03 599.883-second historical timing trace.

   Relevant data: [route pacing](../../data/routes/downtown_loop_route.tres#L8), [early encounter](../../data/encounters/alley_scuffle.tres#L27), [Arcade encounter](../../data/encounters/arcade_ambush.tres#L33). Tune the amount of meaningful activity, empty gaps, and decision payoff together. Simply increasing delays to hit an eight-minute total would worsen the experience.

4. **Design limitation: fresh-profile planning largely chooses order, not a route strategy.**

   Fresh production offers exactly Arcade, Convenience Store, and Subway Entrance. Three one-copy cards must fill three blocks. Consequently every fresh-profile lap contains one standard fight, one cooling-shop block, and one no-combat transit block; block three has no remaining alternative. Full catalogue access adds the elite choice, so developer sessions experience materially different variety.

   This follows the approved content-access/deck contract and is not an implementation error. It does, however, constrain the intended repeated strategic decisions. In the sampled fight-first route, new gear is followed by **63 seconds of approach/transit** before its next fight can demonstrate its value. A future decision about the starting deck or block rules needs a bounded product revision; it should not be silently disguised as a bug fix.

   Relevant code: [fresh card access](../../scripts/persistence/persistent_profile_data.gd#L49), [lap-deck authority](../../scripts/cards/card_system.gd). Reassess meaningful alternatives and time from build choice to visible consequence before expanding the catalogue.

5. **Confirmed clarity defects: information exists, but its hierarchy and wording obscure the action.**

   Native 1280×720 inspection showed repeated phase information behind a translucent choice layer, truncated risk descriptions, and clipped `CONFIRM NEXT BLOCK` / `CLEAR SELECTION` labels. The Confirm text measured 197px at the actual 18px font; its 210px button has 12px horizontal padding on each side, leaving only 186px. The existing containment checks do not establish that the text fits.

   PLAN repeats the location name and mixes the actionable consequence with phrases such as “non-recursive standard encounter,” “authored quality tier,” and “existing finite stock.” These describe system contracts rather than helping the player imagine the next event. “SHOP + RECOVERY” promises more than the implemented cooling-only shop supplies. In the fresh first-lap probe, its optional 60-coin purchase would lower Heat **4 → 0**, staying in tier zero and healing nobody.

   Prefer a short decision headline, a concrete consequence, and optional detail: for example, “Arcade — Fight for better loot · +10 Heat” and “Convenience Store — Cool the district · -10 Heat.” Keep the existing exact transaction details accessible. Give the current choice screen clear visual ownership, and test text fit in actual selected, disabled, keyboard-focus, and long-name states.

   Relevant code: [PLAN copy](../../scripts/ui/game_hud.gd#L3624), [button geometry](../../scripts/ui/game_hud.gd#L3380), [theme padding](../../scripts/ui/theme/neon_ui_tokens.gd#L226), [shop definition](../../scripts/run/run_cooling_controller.gd#L220).

6. **Design weakness: interventions and extraction have limited opportunity to deliver the promised agency.**

   Focus never became available in the three sampled fresh-profile first laps. In the full-catalogue laps it was available only briefly, with the longest continuous window measuring 0.65–0.75 seconds. Its actual effect is temporary target priority; it does not itself interrupt, so usefulness depends on current positions, attack timing, and competing threats. Sparse one-enemy fights provide little target-selection leverage. This is a tuning/readability concern, not a claim that the validated Focus authority is broken.

   Extract/Push has genuine run-ending consequences, but the “secure gains” motivation is underdeveloped: coins currently buy finite cooling, Scrap is explicitly summary-only, and the summary records accumulated coins/Scrap for defeat as well as extraction. There is no outcome-based banking conversion in `finalize_summary()`. After the existing breadth unlocks, replay motivation rests heavily on combat enjoyment and personal challenge—the two things the empty pacing makes harder to establish.

   Relevant code: [Focus validation](../../scripts/interventions/focus_controller.gd#L203), [Focus timing](../../data/interventions/wp05_focus.tres), [Extract copy](../../scripts/ui/game_hud.gd#L1591), [summary accounting](../../scripts/run/run_director.gd#L479). Clarify what success secures within the approved progression boundary; permanent statistical upgrades are not an appropriate repair.

7. **Verification gap: current passing tests do not cover the failing experience.**

   The existing WP06 focused suite passed again: **15/15 tests, 281 assertions, zero failures/skips**. Its cleanup test explicitly invokes cleanup methods; it does not demonstrate that the real final-kill → reward → PLAN sequence invokes them. The new controlled probes reproduce stuck objects despite that passing suite.

   The historical long-form runner also lacks a focused PLAN resolver: its modal handler covers rewards, shops, and extraction, while its loop bound depends on eligible time. With the current mandatory planning pause it can stall at PLAN. This was identified by source inspection; that obsolete runner was not launched as a fresh acceptance gate. The historical WP02 result remains valid for its recorded build.

   Relevant code: [explicit cleanup in the WP06 test](../../tests/integration/wp06_game_run_presentation_suite.gd#L124), [old timing loop](../../tests/run_milestone_6_long_form_probe.gd#L46), [old modal handler](../../tests/run_milestone_6_long_form_probe.gd#L163). Add real transition regressions and current fresh-profile end-to-end traces before relying on cumulative counts. The pending WP02/WP03/WP04 human records remain pending.

The recommended next scope is a small, ordered repair pass: first remove stale encounter visuals and add the reproductions as regressions; then reduce empty approach/spawn time and put equipment payoff closer to its choice; then simplify screen ownership and copy. Follow that with explicit product decisions on starting-deck variety and Extract/Push stakes. Evaluate the resulting first lap with unbriefed players before adding content. Existing authorities, deterministic streams, inventory safety, and the historical compatibility boundary are useful foundations to retain.

Evidence is in the ignored local [audit directory](../../build/state_audit_2026_09_18/): `probe.gd` / `results.json` contain the six fixed-step samples; `artifacts.gd` / `artifact_results.json` contain the two separate reproductions; `full_run.gd` / `full_run_results.json` contain the complete current-profile trace. [Reward capture](../../build/state_audit_2026_09_18/native_reward.png) and [next-PLAN capture](../../build/state_audit_2026_09_18/native_plan_after_fight.png) show the actual native UI. Diagnostic scripts use disposable workspace profile paths and do not edit the player's profile.

Limits: this was not a fresh Pages/browser acceptance pass, a representative balance study, or a human fun test. Fixed-step samples manually advance the production authorities, excluding modal thinking time and asynchronous presentation timing. Their single seed and explicit policy bound the timing conclusions. The headless host emitted a certificate-store diagnostic; the full-run diagnostic harness also reported two ObjectDB instances at shutdown. The first test invocation had a sandbox log-path error, and initial diagnostic-only method/compile mistakes were corrected for subsequent probes. Editor-run FPS was low, but background execution and instrumentation make it unsuitable as a release-performance verdict. These environment/harness issues were not presented as gameplay regressions or a clean platform gate.
