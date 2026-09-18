**Short-run pacing — 2026-09-18 — owner-authorized Pages playtest release**

After reviewing the completed work and its disclosed verification limits, the owner explicitly requested committing and pushing the latest build to trigger GitHub Pages. This authorizes this repair/pacing boundary's publication; it does not imply a new participant-gate pass or completed WP07 acceptance. Deployment evidence will be recorded after GitHub Actions completes.

The owner chose “Make the runs substantially shorter” after being offered shorter runs with the current card rules versus retaining an 8–12-minute goal with a revised block mix. The configured game keeps the same three laps, nine blocks, finite accessible lap deck, card effects, crew, gear, interventions, Extract/Push decisions, and boss boundary.

The live scene uses separate `data/pacing/short_run_*.tres` Resources. Approaches are **4 seconds instead of 21**, first-enemy entry is **1 second instead of 3**, and subsequent non-boss spawns are **4 seconds apart instead of 12**. Stable route/encounter IDs, rosters, budgets, concurrency caps, rewards, Heat deltas, Pressure rates, actor stats, attack timings, and cooldowns match the original definitions. No global time acceleration is used. Original Resources remain available to the historical fixtures.

Current engineering targets are roughly **90–240 eligible seconds for a boss attempt**, **10–35 seconds for an ordinary fight**, **20–60 for elite/boss fights**, and measurement bands of **1–8 ambient / 3–60 block / 20–90 lap seconds**. Fast extraction or early defeat can be shorter. These are evaluation bands, not timers that pad the run. Time spent reading and choosing is excluded and adds to wall-clock session length. Shorter eligible time naturally accumulates less passive Pressure, while faster spawns create more overlap; no claim of unchanged encounter difficulty or completed human balance acceptance is made.

Paired seed `6062026` comparisons use starter gear, no interventions, no purchases, declined gear, and the same preference order Arcade → Gang Hideout → Convenience Store → Subway. All six comparison policies ended in defeat. Full-access cases may die at different points, so their outcome durations are not matched boss-clear comparisons. First-lap values compare completed laps under the same policy.

| Access | Crew | Previous outcome | Short outcome | Reduction | First lap, previous → short |
| --- | --- | ---: | ---: | ---: | ---: |
| Fresh | Jax | 315.217s | 99.667s | 68.4% | 92.783 → 23.850s |
| Fresh | Zoey | 313.867s | 97.383s | 69.0% | 92.250 → 23.317s |
| Fresh | Rex | 329.583s | 121.100s | 63.3% | 92.183 → 23.250s |
| Full | Jax | 567.433s | 167.583s | 70.5% | 157.017 → 52.233s |
| Full | Zoey | 280.150s | 100.750s | 64.0% | 157.017 → 71.333s |
| Full | Rex | 561.850s | 160.817s | 71.4% | 157.250 → 60.833s |

The longest continuous eligible gap without an enemy fell **66.000 → 13.033 seconds** on the fresh route and **45.000 → 9.017 seconds** on the full-access policy. These gaps can span more than one utility/approach segment; modal decision time is not counted. Nine approaches total about **36 seconds**, compared with 189 previously.

Additional short-run coverage uses seeds `6062026` and `30301` across all three crew and fresh/full access. Its simple build policy equips the first offered item into empty active slots, uses valid Environment/Focus, calls Backup on bosses or multi-enemy elites, leaves shops without purchasing, and pushes twice unless the extraction probe requests a specific lap. It is deterministic instrumentation, not an expert policy or a human playtest.

- Twelve build/intervention run samples ended between **82.483 and 198.933 eligible seconds**. All six fresh-profile attempts reached the boss; Rex on fresh seed `30301` won at **122.850 seconds**. The other samples ended in defeat. The full-access policy repeatedly selects the elite and is deliberately risky; none of those six samples reached the boss. This does not establish all-crew/build balance.
- First-lap extraction succeeded in all six requested cases at **22.733–52.017 seconds**.
- Second-lap extraction succeeded in all six requested cases at **46.300–126.083 seconds**.
- Together with the six short-profile comparison rows, this is **30 completed short-run samples**, plus six historical comparison rows. Every row completed without a rejected modal intent. A probe PASS means bounded completion/valid intents; it is not a participant or universal timing-band pass.
- All recorded cadence events, gaps, and outliers remain in the raw JSON. Coin clusters are optional and their full base value remains automatic; events were not delayed to fit a target band.

Reproducible raw evidence:

- [Paired historical/short comparison](evidence/short_runs/hold_6062026_extract_0_comparison.json)
- [Build policy, seed 30301](evidence/short_runs/build_30301_extract_0.json)
- [Build policy, seed 6062026](evidence/short_runs/build_6062026_extract_0.json)
- [Extract after lap one](evidence/short_runs/build_6062026_extract_1.json)
- [Extract after lap two](evidence/short_runs/build_6062026_extract_2.json)

The current runner is `tests/probes/short_run_pacing_probe.gd`. It advances the existing authorities at 1/60 second, handles required PLAN/reward/shop/lap intents with their live tokens, disables only the expensive full-HUD snapshot observer, and enforces a total-step bound. It uses disposable workspace profile paths and leaves the player's save untouched. It does not alter damage, health, RNG, or combat timing to obtain a result. The configured graphical check separately covers presentation and real input.

Verification on Godot 4.7.2:

- **319/319 cumulative tests, 4,731 assertions**, zero failures/skips. The assertion total varies with existing conditional fixture paths; no historical assertions were deleted to obtain this result.
- **15/15 WP06 focused tests, 281 assertions**, zero failures/skips.
- **7/7 repair/pacing tests, 67 assertions**, zero failures/skips. The two added cases compare all non-timing encounter data and stable route identity against the unchanged historical Resources, then exercise the live 4-second approach, 1-second first spawn, 4-second reinforcement, and pause/resume boundaries through the composed authorities. The pacing fixture uses a single accessible combat card so offer randomness cannot distract from its scheduling contract.
- Total: **341 passing tests / 5,079 assertions**, plus all **36 bounded timing samples** (30 short, six historical), with no incomplete run or rejected modal intent.
- The configured `/GameRun` launched successfully and runtime inspection confirmed the actual 4/1/4 values and `short_run_cadence`. Real native menu/start and plan selection/confirmation input was exercised. The final live timing-event/screenshot capture was interrupted by the user's PC crash; after restart, the files/results were intact and the project launched with no reported boot error, but the live-inspection tool then hung. That inspection attempt was stopped. A completed post-restart visual/timing capture is **not claimed**.
- `git diff --check` passed. The owner-carried addon and `project.godot` changes remain preserved. No gameplay time multiplier was changed; the 60-FPS inspection cap applied only to the disposable live process.

Historical compatibility remains explicit: the old Resources and WP02 cadence assertions are preserved; the WP02 fixture selects its historical cadence Resource, while the new composed tests inspect the configured short preset and actual pause-aware spawn boundaries. The historical long-form runner now rejects unsupported modal states promptly and has a total-step bound; it is no longer the current timing runner.

Publication is authorized but deployment success is not yet claimed in this pre-deployment record. No qualitative acceptance is inferred. The inherited aggregate-runner shutdown diagnostic and host sandbox certificate-store limitation remain disclosed. Godot 4.7.2 export templates are still absent on this host, so new local exported-Windows and Web-release gates are not claimed; the existing Pages workflow performs the official Web export.
