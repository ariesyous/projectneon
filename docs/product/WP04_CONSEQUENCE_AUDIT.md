# WP04 Consequence Audit and Owner-Authorized Decisions

Date: 2026-08-22
Baseline: documentation HEAD `48ffb58fdcdcb1bd4d74bd011c2115c91a5f42a5`, published WP03 implementation `a6ef571942afb319b3e2c0cdd9c9cffcc1f1bc93`
Decision status: approved within the owner's advance WP04 authorization

## Method

The audit inspected every one of the nine stable equipment Resources, all three threshold Resources, the three crew starters, the three standard rewards, every active/backpack destination, equipment draw/filter order, and the global/per-visit finite cooling path. Scenarios use stable catalogue order, fixed Resources, exact current formulas, and the existing schema-1 named streams. The automated package locks the repaired runtime effects, exact reward/shop transactions, and three disjoint build vectors.

The evaluation axes were deliberately not collapsed into DPS: primary-hit cadence, status application and duration, environmental force/damage, intervention cooldown, survival/knockback resistance, target condition, exact reward payout, Heat tier, global/visit stock, and lossless inventory consequence were recorded separately.

The UX decisions also use external evidence:

- [Xbox Accessibility Guideline 114](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/114) supports adjacent labels, understandable pre-activation expectations, contextual detail, and realistic previews.
- [Xbox Accessibility Guidelines 112 and 115](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112) support consistent focus/input paths and staged review/confirmation for consequential actions.
- [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103) supports redundant non-colour critical feedback.
- [Choice-overload meta-analysis](https://academic.oup.com/jcr/article-abstract/37/3/409/1827647) and its [contextual follow-up](https://www.sciencedirect.com/science/article/abs/pii/S1057740814000916) support reducing comparison complexity rather than arbitrarily removing the authored three-choice reward.
- Riot's [TFT Galaxies](https://teamfighttactics.leagueoflegends.com/en-us/news/dev/dev-teamfight-tactics-galaxies-learnings/) and [Reckoning](https://teamfighttactics.leagueoflegends.com/en-us/news/dev/dev-teamfight-tactics-reckoning-learnings/) retrospectives support flexible item relationships and small balance corrections instead of mandatory key-item dependencies or systemic churn.
- Nielsen Norman Group's [visibility/error-prevention/recognition heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) support authoritative snapshots, exact revisions/tokens, and visible post-action state.

## Equipment audit

| Stable ID | Baseline deterministic finding | Failure class | Approved treatment |
| --- | --- | --- | --- |
| `spiked_bat` | +25% heavy damage, 25% heavy-hit Bleed, +15% knockback; immediately strong for Jax/Rex but heavy-only for Zoey | Presentation dependency, not a broken effect | Values unchanged; `HEAVY KNOCKBACK` role and exact promise identify the prerequisite |
| `shock_gloves` | +8% nominal speed and 25% Shock; Shock itself had no effect without Voltaic Blade and speed affected cooldown only | Balance invisibility | Full build-speed cadence plus Shock's inherent +25% Environment damage taken |
| `reinforced_jacket` | +20% health and -20% received knockback are distinct and exact; Rex reaches 864 health and 0.36 received-knockback factor | Presentation only | Values unchanged; `SURVIVAL` role and exact before/after preview |
| `hacker_deck` | -10% intervention cooldown worked, but +1.5s Shock duration was inert in five of six Tech pairs | Balance redundancy inherited from Shock | Item unchanged; inherent Shock consequence makes duration meaningful |
| `steel_toe_boots` | +10% movement and +15% environmental collision damage are materially distinct, especially with Jax/Knockback 2 | Presentation only | Values unchanged; Environment promise and collision acknowledgement |
| `serrated_wraps` | +1 Bleed cap and +15% versus bleeding did nothing without another Bleed source; Spiked Bat could not proc on Zoey's light attack | Non-viable singleton | Added existing typed 35% on-hit Bleed for 4s; cap/conditional values unchanged |
| `magnetic_flail` | +20% Environment knockback, +10% Environment damage, and Tech/Knockback bridge paths are distinct | Presentation only | Values unchanged; explicit `ENVIRONMENT CONTROL` promise |
| `voltaic_blade` | Guaranteed Bleed plus +20% versus Shocked is the strongest self-contained status item, but loses on survival, Environment control, and intervention cadence axes | Strong, not universally dominant | No nerf; exact matrix retains its opportunity cost |
| `chain_sneakers` | +6% movement, nominal +6% speed, and +10% damage only while a target was currently knocked back; a solo crew actor could not self-follow within the 0.10–0.18s window | Hidden/marginal effect | Full build-speed cadence; replaced unreachable follow-up damage with existing +10% knockback distance |

All nine items and all three synergies now have validated `role_label` and `combat_promise` metadata. Existing icons/badges remain replaceable presentation assets and stable IDs are unchanged.

## Synergy audit

| Threshold | Baseline | Decision |
| --- | --- | --- |
| Knockback 2 | +20% attack knockback and +25% environmental collision damage were already distinct | No numerical change; exact wall-hit acknowledgement added |
| Bleed 2 | +2 cap and +20% versus bleeding were strong only after Bleed existed | No threshold change; Serrated makes every valid pair capable of expressing Bleed on every crew |
| Tech 2 | -15% cooldown worked, but +1.5s Shock duration often extended a marker with no consequence | No threshold change; repaired Shock makes the six-second Gloves/Deck/Tech window meaningful |

## Reward audit

Baseline reward definitions remain `street_cache` tier 0 = 20 coins/2 Scrap, `neon_stash` tier 1 = 30/3, and `viper_cache` tier 3 = 45/5. The authored Heat multipliers `1.00/1.05/1.10/1.20/1.35/1.50` existed in `RunDirector` and the HUD but were never applied.

WP04 latches the exact multiplier when the reward is prepared and applies it to coins only using non-negative half-up rounding. Scrap remains raw and summary-only. Examples: Neon at x1.05 gives 32 coins/3 Scrap; Neon at x1.20 gives 36/3; Viper at x1.35 gives 61/5; Viper at x1.50 gives 68/5. Selection still consumes one `rewards` draw; payout calculation consumes none.

The equipment transaction is now bound to a monotonic choice token plus encounter identity and inventory revision. Confirm and Skip both name the paired reward's exact coins/Scrap; stale prior-run tokens cannot acquire or silently decline a new offer.

## Shop audit

The bounded values remain 60 coins, -18 Heat, two global purchases, and one purchase per Convenience Store visit. Raising price, increasing reduction to a guaranteed tier, or adding another coin sink was rejected: pending cluster settlement and the absence of a broader approved economy make those changes riskier than the observed problem.

The observed failure was state communication. The previous UI considered only coins and global stock, so it could advertise AVAILABLE at Heat 0 or after the visit allowance was consumed. WP04 makes `RunCoolingController` publish one exact preview/result containing coins, Heat, Heat tier, reward quality/multiplier, global stock, visit stock, source, revision, and unchanged Night Pressure. Examples locked by tests include:

- affordable: 180→120 coins, Heat 80→62, tier 4→3, global 2→1, visit 1→0, Night Pressure unchanged;
- unaffordable: exact `NEED n MORE COINS`, no mutation;
- visit used: `PURCHASE USED / LEAVE SHOP`, global stock preserved;
- sold out: `SOLD OUT / NO MORE THIS RUN`;
- stale/malformed/wrong-source/reentrant: immutable rejection and explicit review feedback;
- accepted purchase: persistent before/after result and a `LEAVE SHOP` outcome naming coins and stock.

## Approved three-build matrix

The matrix uses all nine items once; no shared core item can be universal.

| Crew/build | Exact expression | Axis led |
| --- | --- | --- |
| Jax: Spiked Bat + Steel-Toe Boots + Chain Sneakers | Knockback 2; +45% attack knockback, +40% Environment collision damage, +16% movement, true +6% cadence, Jax x1.25 collision identity | control, chase, environmental finish |
| Zoey: Shock Gloves + Hacker Deck + Magnetic Flail | Tech 2; 25% Shock lasting 6.0s, true +8% cadence, cooldown factor `0.85 × 0.75 = 0.6375` (Hydrant 5.10s; Backup 19.125s), +20% Environment knockback, +10% Environment damage, Shock +25% vulnerability | status cadence and intervention economy |
| Rex: Reinforced Jacket + Serrated Wraps + Voltaic Blade | 864 health, 0.36 received-knockback factor, Bleed 2 cap 6, guaranteed Blade Bleed plus 35% Wraps proc, +35% versus bleeding, Rex x1.25 elite/boss role | survival and elite/boss Bleed pressure |

The deterministic matrix proves orthogonal technical viability, not enjoyment or human consequence recognition.

## Rejected alternatives

- No rarity, affixes, sets, selling, salvage, new currency, new shop inventory, or permanent power.
- No new status/content ID, tenth item, fourth synergy, or broad item rewrite.
- No Voltaic nerf: it does not dominate the survival, control, or intervention axes.
- No starter tag added to Reinforced Jacket: Rex's authored survival/boss role is distinct without forcing every starter to complete a first-reward synergy.
- No shop price/stock/reduction change before representative economy evidence.
- No restored reward `StatComparison` overlay: the owner-carried single staged layer is preserved and extended inline.
- No WP05 Focus, encounter, or intervention work.

## Human-only remainder

The five-person unbriefed consequence/variety checkpoint remains pending. Use `WP04_UNBRIEFED_CONSEQUENCE_VARIETY_CHECK.md`; automated scenarios and implementers are not participants.
