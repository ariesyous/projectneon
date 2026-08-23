# WP04 Current-to-Target Authority Map

Status: implemented local handoff; technical evidence recorded separately; human gate pending

| Concern | WP03 baseline | WP04 result | Preserved invariant |
| --- | --- | --- | --- |
| Equipment data | Nine typed items with tags/modifiers/effects | Same IDs/catalogue plus role/promise metadata and four bounded repairs | No new item, rarity, affix, set, or item-specific UI gameplay branch |
| Build preview | Tags, activation/deactivation, replacement name | Authority snapshot also freezes exact modifiers/procs, crew values, final active/backpack slots, and next-fight promise | `SynergySystem` remains inventory/build authority; preview never mutates |
| Reward context | Pending encounter plus inventory revision | Monotonic choice token + encounter + inventory revision; exact paired payout snapshot | `RewardDirector` remains selection/accounting authority; streams unchanged |
| Standard payout | Authored tier selected; raw coins/Scrap applied | Authored Heat multiplier latched/applied to coins only; raw Scrap | One rewards draw, half-up payout, exact-once ledger |
| Inventory management | Revisioned lossless move/swap/storage and named discard | Same operations plus authority-generated transaction preview | UI still only stages and forwards intent |
| Shop | State/coins/global stock validated by cooling authority | Monotonic visit revision/source, reentrancy lock, exact preview/result | 60/-18/two-global/one-card-visit values unchanged; no Night Pressure mutation |
| Combat feedback | Status markers and generic synergy toast | Rate-limited icon+label status, Environment, Tech, and synergy acknowledgement | Presentation observes resolved signals and consumes no gameplay draw |
| Input | Mouse/touch drag and click/tap/keyboard fallback | Same paths carry exact reward/shop contexts; keyboard drag-source activation repaired | One rules model; Confirm remains authoritative boundary |
| Cleanup | Restart/menu clear inventory/reward/status/presentation | Tokens/revisions remain monotonic; pending previews/callouts/results clear | Same-seed access/card/lifecycle contracts remain |

The focused District Plan, WP02 lifecycle precedence, random schema 1, and historical Milestone 5 compatibility surface are unchanged.
