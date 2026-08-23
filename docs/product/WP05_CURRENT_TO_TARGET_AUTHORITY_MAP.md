# WP05 Current-to-Target Authority Map — Owner Checkpoint

Status: Part A development prototype complete; target not authorized until owner selection

| Concern | WP04 production authority | Part A seam | Recommended Part B owner | Invariant/risk |
| --- | --- | --- | --- | --- |
| Environment role | `FireHydrantController` plus Hydrant world/HUD input | `WP05PrototypeRuntime` adapts Hydrant and compares Power Box/Sign in one contextual slot | A typed context Environment controller dispatches preserved Hydrant or one approved object | One visible slot; shared cooldown/revision/token; no parallel object buttons |
| Focus | Disabled WP01 shell; nearest/retaliation targeting in `CombatDirector` | Windup observer + one-press priority for non-committed permanent crew | New run-scoped `FocusController`; `CombatDirector` exposes typed priority/intent seam | No damage/stun/direct attack; target death/expiry/cleanup exact |
| Backup | `CallBackupController` owns 2 charges, 2 allies, 12s, 30s and rollback | Exact authority reused behind a development request revision/token | Same controller, adding caller-supplied monotonic request context if selected | No recharge; scarcity must remain the hold decision |
| Rally | Absent | Separate `4 DEV` retreat controller directly cancels crew attacks and moves formation | None under recommendation | Direct-control creep, fourth-control footprint, tracking counter |
| Enemy intent | Actor windup/state; boss-only named presentation | All windups become deterministic candidate snapshots/world labels | Typed intent snapshot from combat authority; presentation names target/attack/window | Current short windows need human readability validation |
| Encounter variety | Four existing encounters/roles, authored streams/caps | Four exact dev scenarios using existing actor IDs only | Bounded production combinations/modifiers; no new actor required | No adaptive/unseeded Director or cosmetic permutation counting |
| Telemetry | `RunCadenceTracker` measures only approved cadence | Separate deterministic `WP05PrototypeTelemetry` | Remove or keep development-only | Never schedules, mutates, persists, or consumes a stream |
| UI/input | `GameHUD` snapshot-only; Environment side slot, Backup+disabled Focus strip | Explicit debug gate, exact context signals, native Buttons, separate Rally | Environment/Focus/Backup labelled 1/2/3; Subway strategic | Mouse/touch/keyboard one rules model; important state not colour-only |

The default configured scene creates no prototype node. `GameRun.enable_wp05_prototype_mode()` rejects release builds; Part A Resources use the `wp05_proto_` prefix and are not encounter or content-access candidates.
