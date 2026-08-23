# WP04 Acceptance Evidence — Builds, Rewards, and Shop

Date: 2026-08-22

Status: **technical/runtime/visual/platform gate passed and browser-playtest build published; owner-run five-person consequence/variety gate pending**

WP04 begins from published WP03 implementation `a6ef571942afb319b3e2c0cdd9c9cffcc1f1bc93` and documentation HEAD `48ffb58fdcdcb1bd4d74bd011c2115c91a5f42a5`. The owner authorized the bounded consequence audit and balance decisions, then separately authorized this exact evidenced boundary for a `main` and GitHub Pages browser-playtest release on 2026-08-22. It was subsequently published from commit `782f7fe18fa434d47020f1d4bc837c9c05790dad`; owner-supplied Pages run 32607599862 succeeded. Publication did not authorize WP05 or satisfy the human gate.

## Decision evidence

[WP04_CONSEQUENCE_AUDIT.md](WP04_CONSEQUENCE_AUDIT.md) records every item, synergy, starter, reward tier, inventory destination, and finite shop path; external design/UX research; balance versus presentation failures; the approved smallest change set; rejected alternatives; and the disjoint three-build matrix.

Selected behavior repairs:

- Shock: +25% damage taken from Environment interventions only;
- equipment attack speed: complete crew windup/active/recovery/cooldown timeline;
- Serrated Wraps: 35% on-hit one-stack/four-second Bleed;
- Chain Sneakers: +10% knockback distance replacing unreachable current-knockback follow-up;
- standard rewards: existing Heat multiplier applied to coins only with deterministic half-up rounding.

No value changed for the other seven items or any threshold. Shop values remain 60 coins/-18 Heat/two global purchases/one Convenience purchase.

## Authority and deterministic evidence

- `EquipmentDefinition`/`SynergyDefinition` own validated role/promise metadata; stable IDs and catalogue ordering are unchanged.
- `RewardDirector` owns one positive monotonic equipment-choice token per offer, latched payout snapshots, exact-once standard/equipment accounting, and stable `rewards`/`equipment` stream usage.
- `SynergySystem` owns exact non-mutating destination and inventory-transaction previews. `BuildConsequenceEvaluator` is pure and derives crew-specific before/after values from authority snapshots.
- `RunCoolingController` owns monotonic visit revisions/sources, preview/result snapshots, reentrancy lock, finite stock, cost, and Heat mutation.
- Invalid/stale/replayed/malformed/wrong-source/reentrant/full/unaffordable/exhausted paths leave Heat, Pressure, coins, stock, inventory, rewards, tokens, and streams unchanged.
- Random schema remains 1 and the seven named streams remain exact. Locked card vector `30301 → [gang_hideout, subway_entrance]` passes inside affected/cumulative runs.
- The three-build test uses all nine items once: Jax Bat/Boots/Chain, Zoey Gloves/Hacker/Flail, Rex Jacket/Wraps/Blade. Each leads a different non-DPS axis and no core item is shared.

## Automated results

Executed with Godot `4.7.2.stable.official.ed1daf0bf` using normal host `user://` access:

| Gate | Result |
| --- | --- |
| WP04 focused | **15/15 tests, 247 assertions, 0 failed, 0 skipped** |
| WP04 affected | **226/226 tests, 3,175 assertions, 0 failed, 0 skipped** |
| WP04 cumulative | **291/291 tests, 4,192 assertions, 0 failed, 0 skipped across 30 suites** |
| Native GUI routing | **PASS — keyboard, touch, mouse reward flow and revisioned shop request** |
| Configured main scene | **PASS — `/GameRun` opens directly with clean log** |

The aggregate single-process runner emits the exact inherited post-success diagnostic: 48 ObjectDB instances and four resources still in use. Focused, affected, native input, configured boot, configured graphical smoke, export, exported Windows, and browser runs do not reproduce it. It was not hidden or reclassified.

An initially flaky historical spawn test was found to depend on wall-clock seed entropy despite asserting an exact finite roster. The test now preserves the real configured crew/menu path, returns to the clean boundary, and restarts with supplied seed `6062026`; standalone, affected, and cumulative results pass. This is a test-determinism repair, not a spawn-content change.

## Configured runtime and visual evidence

`tests/visual/wp04_game_run_smoke.gd` uses an isolated `user://wp04_runtime_smoke/profile.json` and the configured `res://scenes/game/game_run.tscn`. It passes:

`WP04_GAME_RUN_SMOKE=PASS reward/token=pass full/skip=pass shop/purchase/stale/exit=pass proc/cleanup=pass captures=4`

The smoke covers exact equipment offer token and replay rejection; paired standard payout; selected item/destination/outgoing/post-state; full inventory, exact named leave-behind and Skip; accepted purchase, stale shop revision and exit; Shock proc acknowledgement; and synchronous menu cleanup.

Final inspected 1280×720 captures:

- [Reward consequence](../screenshots/wp04/wp04_reward_consequence_1280x720.png)
- [Full inventory](../screenshots/wp04/wp04_full_inventory_1280x720.png)
- [Shop consequence](../screenshots/wp04/wp04_shop_consequence_1280x720.png)
- [Combat proc feedback](../screenshots/wp04/wp04_build_proc_feedback_1280x720.png)

Visual review found and repaired obstructing legacy tutorial/toast layers, selected-card text overload, confirmation overflow, truncated proc copy, and a purchase-result screen that reverted to misleading no-purchase copy. The final captures contain the decision inside panel bounds with no legacy overlay competition.

## Input evidence

`tests/visual/wp04_input_parity_smoke.gd` routes events through the live GUI:

`WP04_INPUT_PARITY_SMOKE=PASS keyboard=true touch=true mouse=true shop=true`

Keyboard, screen touch, and mouse each select one reward, choose a destination, and emit one exact encounter/token-bound acquisition. Shop input emits one exact visit revision/source. Preserved M4.2 tests continue to cover native drag, 8-pixel pointer/touch threshold, first-touch ownership, outside return, no pre-Confirm mutation, all six destinations, and full-inventory drag.

## Export and platform evidence

Release exports completed with exit 0 and clean export logs:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows `NeonLoop.exe` | 109,168,640 | `3D19EE4A764E8BB153BFA7F811F98E0DFB0139C9E0C8BC6B76B93D3ED09185BF` |
| Windows `NeonLoop.pck` | 1,482,264 | `C364D50FFE59877C2A7E5A420BBD86EC5602D3DAF4625AF2AE1D9107D4F9E9D8` |
| Web `index.pck` | 1,482,264 | `C364D50FFE59877C2A7E5A420BBD86EC5602D3DAF4625AF2AE1D9107D4F9E9D8` |

The exact exported Windows binary passed a five-frame headless runtime smoke with exit 0 and no warning/error output.

The locally served final Web export loaded title `Neon Loop` and a visible canvas. Real pointer input completed:

1. Jax selection and run start;
2. Arcade PLAN selection and confirmation;
3. automatic fight and coin delivery;
4. Voltaic Blade selection, Active 2 destination, exact consequence review, and Confirm;
5. Convenience Store selection and entry;
6. accepted 60-coin purchase with persistent `Purchase applied exactly` result;
7. Leave Shop with `BOUGHT 1 / GLOBAL STOCK 1 REMAINS` feedback.

The final browser warning/error console was empty. Default/1280×720 presentation and temporary 2560×1440 viewport containment were inspected; the viewport override was reset afterward. The localhost server and browser tab were closed.

## Scope and provenance

- On 2026-08-22 the owner authorized this exact snapshot for commit to `main` and GitHub Pages deployment, including the integrated owner-carried reward/inventory/combo corrections.
- Commit `782f7fe18fa434d47020f1d4bc837c9c05790dad` and Pages run 32607599862 subsequently completed that browser-playtest publication.
- No WP05 mechanic/content was started.
- No rarity, affix, set, selling, salvage, broad economy, permanent power, save/schema change, new item/card/crew/enemy/boss, or procedural route was added.
- The owner-carried Godot-AI 3.1.5 update remains intact across the same 57 addon paths and is unattributed to WP04.
- The owner-carried reward-modal simplification and combat-only combo correction remain intact and covered; WP04 extends their current files without restoring the removed reward comparison layer.
- `project.godot` owner deletions remain untouched.

## Pending human gate

No participant result is claimed. The owner must run and sign [WP04_UNBRIEFED_CONSEQUENCE_VARIETY_CHECK.md](WP04_UNBRIEFED_CONSEQUENCE_VARIETY_CHECK.md). Until then, describe WP04 as technically evidenced and published for browser playtest, not qualitatively accepted.
