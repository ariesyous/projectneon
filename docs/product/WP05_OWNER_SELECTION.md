# WP05 Owner Mechanic-Selection Checkpoint

Status: **approved by owner on 2026-08-23; recommendation selected without tuning changes**

This is the single specification-required WP05 owner checkpoint. The owner replied **“Approved”** on 2026-08-23, selecting the recommended Environment / Focus / Backup set below. This approval authorized WP05 Parts B/C only; it did not authorize publication, deployment, WP06, or a fabricated human gate.

## Recommended permanent production set

Approve **Environment / Focus / Backup**, with Rally and Hanging Sign removed from production.

### Environment

- Preserve Fire Hydrant exactly: 112px, 18 damage, 300-force/0.30s left knockback, Wet 4s, 8s base cooldown.
- Add one Power Box context: 96px marked footprint, 4 damage, 1.0s authored stun before resistance, existing Shock for 3s, 12s base cooldown.
- Hydrant and Power Box replace the same Environment slot's icon/name/verb. They share one monotonic context revision/request token and one Environment cooldown ledger; no cycling or parallel buttons.
- Do not ship Hanging Sign. Its 65-damage one-charge burst is position-dependent and risks becoming a scripted obvious answer without creating enough reusable depth.

### Focus

- One press applies 3.0s temporary target priority to the single authority-ranked live windup; base cooldown 10.0s.
- It redirects only permanent crew not already in windup/active/recovery. It adds no damage, stun, movement, or attack command.
- Accept only exact target/attack/revision/token context with at least 0.35s remaining; target death, expiry, terminal, restart, and menu clear synchronously.
- Production presentation must expose eligible Bat/Bottle/Enforcer/Viper intent with target + attack + countdown + shape/world marker + existing SFX. Exact initial Part B proposal: Bat heavy 0.58→0.90s, Bottle throw 0.62→0.95s, Enforcer charge 0.75→1.00s, Viper charge 0.80→1.05s, Viper summon 0.90→1.10s, and Viper area unchanged at 1.10s. Street Punk remains a low-impact 0.31s tell and is not Focus-prioritized by default. These values remain subject to the fixed human gate; Part A does **not** claim current windows are human-readable.

### Backup

- Keep exactly two allies, two run charges, 12 eligible combat seconds, and 30s base cooldown, including existing crew/Tech scaling and rollback.
- Add/retain exact caller revision/token validation and copy that two uses cover the whole run. Do not recharge charges.
- The isolated matrix found Backup beneficial in 12/12 six-second rows; finite whole-run scarcity and near-terminal waste are therefore mandatory, not optional flavour.

### Encounter footprint

- No new enemy, elite, boss, card, equipment, status ID, reward, economy, save field, random stream, or procedural system.
- Author bounded questions from Street Punk pressure, Bat heavy tells, Bottle ranged pressure, Enforcer charge/crossfire, Viper specials/summons, lap modifiers, and Hydrant/Power Box opportunities.
- Retain global/encounter caps and schema 1.

### Remove or retain development-only

- Remove the `4 DEV` Rally control, reposition behavior, and Rally icon after approval; retain only research/evidence fixtures if useful.
- Remove Hanging Sign runtime/content from the production set; development evidence may remain isolated.
- Remove the visual-freeze/debug scenario seams from release paths; default release already creates none.

## Why this recommendation

- Environment was better on both six-second axes in 8/12 rows, worse in 2, and a tradeoff in 2: useful, not universal.
- Focus was equal in 6/12, better in 1, worse in 2, and a tradeoff in 3: it changes target strategy without becoming free power.
- Rally was unavailable in six contexts and worse/tradeoff in five of six valid contexts. It helped boss survival but directly cancelled attacks, reduced boss damage, and required a fourth control.
- Backup is strong but already pays a run-level finite cost. The test suite proves late use can spend a charge for 0.1s of expression with no refund.
- The recommendation adds one reusable Environment object and one priority authority, not a content library.

## Credible alternatives

1. **Sign instead of Power Box:** ship Hydrant + one-charge Hanging Sign as Environment. This is simpler to understand but more scripted, more position-dependent, and higher dominance risk; it adds burst rather than interruption vocabulary.
2. **Rally folded into the Focus control:** show `FALL BACK` instead of target priority only during area warnings, keeping three visible controls. This preserves HUD width but makes one role change semantic category, adds direct movement, and weakens the approved Focus promise. Not recommended.

## Decision implementation handoff — 2026-08-23

- Fire Hydrant remains exact and Power Box is the second context Environment object in the same slot.
- Power Box is valid only during a named interruptible windup in its marked footprint; once triggered, it affects the marked cluster. This makes holding for a tell part of its permanent counter/tradeoff instead of rewarding an immediate cooldown press on any harmless body.
- Focus uses the approved 3.0s priority, 10.0s base cooldown, 0.35s cutoff, live target/attack/revision/token revalidation, and automatic-crew commitment boundary.
- Backup retains exact 2 allies / 2 run charges / 12 eligible combat seconds / 30s base cooldown and adds the caller revision/token gate and whole-run scarcity copy.
- Rally, Hanging Sign, the fourth key/control, and the Part A GameRun enable/freeze seams are absent from configured release composition. Isolated `wp05_proto_` Resources/runtime/tests remain only as archived decision evidence.
- The continuation boundary and remaining gates are recorded in `docs/product/WP05_HANDOFF.md` and `docs/product/WP05_ACCEPTANCE_EVIDENCE.md`.
