# WP05 Prototype and Encounter Comparison

Date: 2026-08-22

Status: Part A complete; recommendation approved by owner on 2026-08-23; retained as historical comparison evidence
Evidence class: deterministic development probe plus configured graphical/input inspection; not qualitative acceptance

## Development-only candidates

| Candidate | Exact prototype tuning | Strong | Weak / invalid | Reason to hold | Counter / burden |
| --- | --- | --- | --- | --- | --- |
| Fire Hydrant / Environment | Preserved 112px, 18 damage, 300 force/0.30s left, Wet 4s, 8s base cooldown | Opening/cluster control; Jax/Knockback build expression | Low value on one distant/armoured target; invalid outside footprint/cooldown | Wait for a denser group or dangerous wall chain | Fixed footprint/direction and cooldown; one press, world/HUD surfaces |
| Power Box / Environment | 96px, 4 damage, 1.0s authored stun before resistance, existing Shock 3s, 12s shared Environment cooldown | Interrupt clustered Bottle/Enforcer windups; Voltaic/Shock follow-up | Poor against one harmless basic; invalid outside footprint/cooldown | Save breaker for charge/projectile intent | Boss/elite resistance and lockout; one contextual slot/press |
| Hanging Sign / Environment | 56px, 65 damage, 260 force/0.20s left, one charge | Elite/boss burst under a narrow footprint | One target only; invalid out of footprint or after spend | Preserve the only drop for elite/boss | Position denial; high scripted burst risks an obvious answer |
| Focus priority | 3.0s priority, 10.0s base cooldown, 0.35s authority cutoff; current threat chosen deterministically | Redirect available crew to Bottle/Enforcer/Bat intent | No added power; weak if already targeted, unreachable, armoured, or nearly dead; invalid without windup | Accept a low-impact tell or use Environment instead | Travel/current attack commitment/target death; one press, no target picker |
| Rally reposition | 1.1s retreat at 1.5× crew movement, 18s cooldown, valid on charge/area with ≥0.65s | Viper area warning survival | Tracking/ranged attacks; invalid without defensive intent | Keep damage uptime if already safe or threat can be finished | Slow Rex may not clear; direct-control creep and a fourth `4 DEV` button |
| Call Backup | Unchanged two allies, two run charges, 12 combat seconds, 30s base cooldown | Elite/boss tempo and survival | Late/near-finished fight produces negligible expression; invalid active/cooldown/exhausted/outside fight | Save two run charges across nine blocks plus boss | Scarcity is the sole meaningful counter; one press |

All instant requests carry the exact displayed role revision, request token, action/target, and attack identity. Invalid, malformed, stale, replayed, no-target, cooldown, exhaustion, pause, terminal, and restart paths consume no prototype ledger. Backup retains its existing spawn/registration rollback.

## Bounded encounter matrix

No new actor is introduced.

| Context | Exact existing roles | Context Environment | Tactical question |
| --- | --- | --- | --- |
| Early | 1 Bat Thug + 2 Street Punks | Fire Hydrant | Spend crowd control now, Focus the heavy tell, or hold for density? |
| Middle | 2 Bottle Throwers + 1 Street Punk | Power Box | Focus one thrower, interrupt the footprint, or accept one projectile? |
| Elite | Viper Enforcer + Bottle Thrower + Bat Thug | Power Box | Preserve breaker/Focus for the charge or spend finite Backup into crossfire? |
| Boss | The Viper with authored specials/summons | Hanging Sign prototype | Spend the one drop/Backup, Focus the only target, or sacrifice damage to Rally? |

## Exact six-second configured matrix

Each row uses the fixed scenario seed and the exact disjoint WP04 build: Jax Bat/Boots/Chain, Zoey Gloves/Hacker/Flail, Rex Jacket/Wraps/Blade. A cell is `crew HP / live-enemy HP after six eligible seconds`; `—` means the role was not valid in that context. The probe uses actual configured `GameRun`, actors, status/equipment effects, authority, and named streams.

| Context / crew | Hold | Environment | Focus | Backup | Rally |
| --- | ---: | ---: | ---: | ---: | ---: |
| Early / Jax | 498 / 118 | 500 / 35 | 502 / 91 | 516 / 0 | — |
| Early / Zoey | 376 / 132 | 376 / 92 | 368 / 166 | 378 / 60 | — |
| Early / Rex | 838 / 80 | 838 / 62 | 834 / 107 | 852 / 0 | — |
| Middle / Jax | 514 / 0 | 508 / 0 | 514 / 0 | 516 / 0 | — |
| Middle / Zoey | 389 / 42 | 382 / 38 | 389 / 42 | 392 / 0 | — |
| Middle / Rex | 848 / 72 | 848 / 64 | 848 / 72 | 862 / 0 | — |
| Elite / Jax | 479 / 472 | 469 / 399 | 446 / 447 | 487 / 344 | 455 / 503 |
| Elite / Zoey | 348 / 508 | 340 / 508 | 317 / 482 | 356 / 418 | 348 / 544 |
| Elite / Rex | 799 / 426 | 807 / 392 | 804 / 492 | 799 / 249 | 807 / 426 |
| Boss / Jax | 448 / 1656 | 448 / 1546 | 448 / 1656 | 448 / 1576 | 484 / 1700 |
| Boss / Zoey | 303 / 1692 | 303 / 1620 | 303 / 1692 | 303 / 1604 | 328 / 1716 |
| Boss / Rex | 767 / 1591 | 767 / 1583 | 767 / 1591 | 767 / 1475 | 767 / 1701 |

These are comparison windows, not fight-duration or balance acceptance. Zero live-enemy HP may mean the run has already entered Reward.

### Dominance classification against Hold

| Policy | Accepted rows | Better/equal on both axes | Tradeoff | Worse/equal on both axes | Same outcome | Unavailable |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Environment | 12 | 8 | 2 | 2 | 0 | 0 |
| Focus | 12 | 1 | 3 | 2 | 6 | 0 |
| Backup | 12 | 12 | 0 | 0 | 0 | 0 |
| Rally | 6 | 1 | 2 | 3 | 0 | 6 |

Interpretation:

- Environment is clearly situational. Power Box's control can cost damage/survival depending on timing; Hanging Sign's net expression varies sharply by build/position.
- Focus is not an on-cooldown damage button. It is best when changing target choice matters; it is neutral on the single-target boss and harmful when it pulls crew off a better current action.
- Rally creates the clearest defensive tradeoff: Jax/Zoey retain 36/25 more boss HP but leave 44/24 more boss HP. In the elite matrix it is frequently worse.
- Backup is positive in every isolated six-second window. Its hold case therefore depends entirely on two charges across nine blocks plus boss. A focused test proves a request 0.1s before terminal spends one charge, removes both allies, refunds nothing, and leaves almost the full cooldown. Production must communicate this run-level scarcity; adding recharge would create dominance.

## Intent/readability evidence

- Authority detects every actor windup from the actual attack phase/active attack ID, rather than trusting UI animation names.
- One threat is sorted by boss/elite role, area/charge/projectile/heavy impact, shorter window, then registration order.
- The configured visual freeze captured Bottle Thrower / Throw at 0.62s with text, target brackets, a world cue, and the same exact context on the Focus Button.
- Real pointer input on that Button applied one Focus use and changed Jax's automatic target to `bottle_thrower`; it did not execute or cancel an attack directly.
- Current 0.58–0.80s non-area windows remain an accessibility/comprehension risk. The prototype proves authority/input plumbing, not that unbriefed humans can perceive and respond in time.

## Determinism and technical evidence

- Focused Part A: **13/13 tests, 180 assertions, 0 failed, 0 skipped** across authority and UI suites.
- Cumulative final run: **304/304 tests, 4,373 assertions, 0 failed, 0 skipped** across the 30 accepted WP04 suites plus two Part A suites. Clean repeats reported 4,372/4,373; per-suite diagnostics showed one conditional assertion in inherited `wp02_state_clarity` and `milestone_6_game_run`, while both WP05 suite counts remained exact.
- Matrix: **60 configured rows** = three crew × four contexts × five policies.
- Exact repeat: passed for Zoey/elite/Focus.
- Fifty extra `cosmetic` draws: identical gameplay projection; schema remains 1 and no prototype consumes an unseeded/global random call.
- The cumulative runner retains the inherited post-success 48-ObjectDB/four-resource shutdown signature. Focused and configured boots do not reproduce it.

## Comparison result

| Candidate | Part A disposition |
| --- | --- |
| Hydrant | Preserve exactly as the first Environment object. |
| Power Box | Recommend production migration after owner selection, with one shared Environment slot and cooldown ledger. |
| Hanging Sign | Remove/retain development-only; high burst plus one-charge scripting does not justify content footprint. |
| Focus | Recommend production migration with one-press context targeting, clearer eligible intent presentation, and no direct power. |
| Backup | Preserve exact 2/12s/30s authority; add caller revision/token and stronger whole-run scarcity copy, no recharge. |
| Rally | Reject as a permanent role; retain development-only until owner decision, then remove if recommendation is approved. |
