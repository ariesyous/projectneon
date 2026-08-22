# WP03 Current-to-Target Authority Map

Date: 2026-08-22

Status: implemented and technically evidenced; owner-run unbriefed first-use gate pending

This map records the bounded migration from the historical Milestone 5 future-slot planner to the WP00-approved focused District Plan. It does not authorize WP04 or any content expansion.

| Concern | Historical compatibility authority | WP03 production authority | Preserved invariant |
| --- | --- | --- | --- |
| Player decision | Persistent hand plus five editable future route slots | Mandatory PLAN safe boundary with up to two offered next-block locations; a third appears only if an explicit effect later grants it | UI forwards typed intent and never calculates legality or consequences |
| Finite card state | One run deck, hand capacity three, discard, supplemental card rewards | One-copy accessible lap deck; draw without replacement; unselected offer remains; refill to two; chosen cards are finite for that lap; next lap archives history and rebuilds | Stable filtering/order before every `cards` draw; no reshuffle inside a lap |
| Scheduling | Player targets a future route occurrence | Confirmed card is bound to the exact current lifecycle lap/block and becomes the immediately next meaningful block | `PatrolController` remains internal fixed-route/safe-boundary authority; no procedural route generation |
| Transaction | Hand/route revisions plus staged placement token | Offer revision, lifecycle revision, stable lap ID, stable block ID, then one staged confirmation token | Stale, replayed, malformed, wrong-phase, wrong-block, and transition-race intents are atomic no-ops |
| Heat/effect | Heat applies after route-placement confirmation; effect resolves at the targeted occurrence | Heat applies once only after exact focused confirmation; authored effect resolves once at the bound next block | Cards never reduce Night Pressure or bypass lifecycle/boss precedence |
| Safe boundary | Optional safe-state planning pause | Required PLAN pause owned by `RunDirector`; ordinary pause cannot release it | Eligible time and Night Pressure do not advance while reading; unsafe transitions synchronously clear staged intent |
| Presentation | Hand/draw/discard jargon, route dots, five legality targets, drag-first teaching | Large icon-plus-label choice cards with block type, Heat, special rule, reward/risk, selection prediction, one confirm, compact Next Block, and resolved lap history | Click/tap/keyboard share native `Button` activation; no second drag mental model in production |
| Legacy compatibility | Milestone 5 isolated suites and definitions | Production `GameRun` configures focused mode; isolated historical fixtures keep legacy mode | Historical M5 verification remains factual without exposing its clutter in release |
| Cleanup | Clear hand, placements, rewards, and route modifications | Clear offer/deck/selection/staged token/active effect/current and archived history on terminal, restart, or menu | Same-seed restart resets the `cards` stream and reproduces the same offer given the same access snapshot |
| Persistence | No active-run save | Unchanged: no active-run save and no profile/save-version migration | Application profile v1 remains backward-safe and random schema remains 1 |

## Exact production card mapping

| Stable ID | Presented next block | Heat | Authored consequence |
| --- | --- | ---: | --- |
| `arcade` | `FIGHT + REWARD` | +10 | One non-recursive standard encounter; ordinary reward advances one existing authored tier, clamped |
| `convenience_store` | `SHOP + RECOVERY` | -10 | At most one purchase from existing finite cooling/shop stock; no replenishment |
| `gang_hideout` | `ELITE + GEAR` | +20 | Scaled `viper_signal` elite path and the normal guaranteed equipment-choice phase |
| `subway_entrance` | `TRANSIT + COOLING` | -15 | No combat; replaces exactly one baseline standard encounter without changing Subway charges |

## Deterministic draw boundary

Focused mode performs no hidden `cards` draw during INTRO. The first PLAN builds the accessible one-copy lap deck in stable ID order and draws the visible offer using only `cards`. Locked vector: schema 1, seed `30301`, full four-card access produces `gang_hideout`, then `subway_entrance`. Extra `cosmetic` draws do not change that vector. Changing the seed, content-access snapshot, ordered choices, or supported build may change later offers; no broader replay promise is made.

## Deprecation boundary

The legacy hand, supplemental card-reward flow, five route targets, validity dots, route-slot drag payload, and related jargon remain callable only for isolated Milestone 5 compatibility tests. Production `GameRun` snapshots set `legacy_route_planner_enabled=false` and `supplemental_card_rewards_enabled=false`; focused presentation hides those controls and disables card dragging. Debug route internals remain inspectable without becoming a release interaction.
