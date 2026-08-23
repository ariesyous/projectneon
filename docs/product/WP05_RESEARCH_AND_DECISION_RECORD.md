# WP05 Research and Decision Record — Part A

Date: 2026-08-22

Status: research and development-gated comparison complete; recommendation approved by owner on 2026-08-23
Production boundary: unchanged WP04 release; no WP05 candidate is production content

## Question

What is the smallest intervention and encounter vocabulary that strengthens Neon Loop's plan/watch/intervene/push loop without becoming direct-control combat, an always-click-the-cooldown routine, or a broad content expansion?

`GameSpecifications.md` remains product authority. Research informs the comparison but does not authorize mechanics or override Environment/Focus/Backup, the fixed 3×3 run, named-stream determinism, or the owner checkpoint.

## Baseline audit

- `FireHydrantController` owns a fixed 112-pixel circle, 18 damage, 300-force left knockback, Wet, an eight-second base cooldown, stable target order, and immutable no-target/cooldown rejection. It has no caller-supplied revision/token.
- `CallBackupController` owns two allies, two charges, 12 eligible combat seconds, a 30-second base cooldown, transactional spawn/registration rollback, internal activation tokens, and cleanup. Its caller supplies no expected revision/token.
- `CombatDirector.acquire_target()` chooses deterministic nearest/retaliating targets. A live target is retained until invalid; there is no priority override.
- Every actor exposes attack state and the active attack ID, but only attacks with `telegraph_seconds > 0` publish `attack_telegraphed`. `GameRun` turns that signal into named world/overlay warnings only for The Viper. Bat Thug and Bottle Thrower rely on pose/windup alone; Viper Enforcer emits a signal that production presentation currently ignores.
- Current authored windups relevant to intervention are Street Punk 0.31s, Bat Thug 0.58s, Bottle Thrower 0.62s, Enforcer charge 0.75s, Viper charge 0.80s, Viper summon 0.90s, and Viper area 1.10s.
- The production combat strip contains Backup and a disabled Focus shell; Environment/Hydrant occupies the side action panel; Subway is already hidden during combat and remains strategic travel.
- Pauses, terminal state, restart, summary, actor caps, WP02 progression, WP03 planning, WP04 build/reward/shop authority, and schema-1 streams are separate owners and remain intact.

## Sources and application

Sources were reviewed on 2026-08-22. Primary/original developer, platform, research, and engine material was preferred.

| Source | Applicable finding | Neon Loop use | Lesson rejected or bounded |
| --- | --- | --- | --- |
| Riot, [Champion Counterplay](https://www.leagueoflegends.com/en-us/news/dev/quick-gameplay-thoughts-may-14/) | High-impact threats benefit from clear tactical responses such as interruption, long windup, or positioning; stronger effects merit more counterplay, but not every action needs it. | Make only readable high-value intents valid for Focus/Rally; keep low-impact attacks acceptable to ignore. | No response is guaranteed to negate a threat; armour, travel, commitment, and lockout remain counters. |
| Riot TFT, [Into the Arcane Learnings](https://teamfighttactics.leagueoflegends.com/en-us/news/dev/dev-tft-into-the-arcane-learnings/) | Smaller thematic mechanics reduce complexity; broadly useful/simple effects are attractive, while forceable best options reduce variance. | One context Environment slot and one-press Focus; telemetry explicitly checks general-purpose dominance. | No large intervention catalogue and no universally useful stat button. |
| Riot TFT, [Reckoning Learnings](https://teamfighttactics.leagueoflegends.com/en-gb/news/dev/dev-teamfight-tactics-reckoning-learnings/) | Player agency and run-to-run variance must coexist; power/fantasy should be proportional to cost. | Focus gives an authored moment of agency; Backup's power is charged against two finite run uses. | No elimination of deterministic encounter/build variance through a forceable universal answer. |
| Riot Games, [URF Academy Module 3: Meaningful Decisions & Opposition](https://www.riotgames.com/darkroom/original/95f528a2ccdefd27d2d0910ad36c5154%3A97a92a52820d947c346ee46c4293948c/pdf-viewer.pdf) | Repetition without meaningful difference causes boredom; excess complexity, time pressure, and too many choices cause anxiety; solved optimal moves reduce flow. | Four bounded contexts, a three-role permanent bar, and explicit use/hold comparisons. | No fourth permanent button merely to add activity; no intervention requirement every fight. |
| Valve, [Replayable Cooperative Game Design: Left 4 Dead](https://cdn.steamstatic.com/apps/valve/2009/GDC2009_ReplayableCooperativeGameDesign_Left4Dead.pdf) | Peaks/valleys, structured unpredictability, and dramatic anticipation improve replayability; constant combat fatigues. | Author a bounded matrix of distinct questions and preserve ordinary moments where holding is correct. | The adaptive Director and procedural population model are rejected: WP05 uses fixed authored scenarios, existing streams, and no unseeded dynamic events. |
| Microsoft, [XAG 103: Additional channels for visual and audio cues](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103) | Critical cues need redundant sensory/signifier channels and cannot rely on colour alone. | Role/name, intent text, shape/range, countdown, world marker, and existing activation SFX; colour remains supplementary. | Colour simulation is not treated as participant evidence. |
| Microsoft, [XAG 107: Input](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) | Input speed and pointer-only precision create barriers; equivalent digital input should exist; avoid rapid/repeated/simultaneous demands. | One press on a context-selected Focus target; mouse/touch/keyboard route the same exact context token. | Two-step aim-then-confirm and precision enemy clicking are rejected for sub-second intent windows. |
| Microsoft, [XAG 113: UI focus handling](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/113) and [XAG 114: UI context](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114) | Visible focus and nearby labels should identify what an interaction will do before activation. | Buttons name role, contextual verb/intent, affected target, window, charge/cooldown, and invalid reason before input. | Hidden target selection or unexplained automatic context switches are rejected. |
| Microsoft, [XAG 116: Time limits](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/116) | Perceiving, interpreting, deciding, and physically responding all consume a time limit; core gameplay is exempt but still creates access barriers. | Record the complete intent window and require simple input; flag the current 0.58–0.80s windows as a production risk. | The prototype's 0.35s authority cutoff is not claimed as human-readable acceptance. |
| Proctor & Schneider, [Hick's law for choice reaction time: a review](https://web.ics.purdue.edu/~dws/pubs/ProctorSchneider_2018_QJEP.pdf) | Response uncertainty and number/mapping of alternatives affect choice time; practice reduces but does not erase the effect. | Present one authority-selected threat rather than a transient list; retain stable role/key mapping. | The research does not supply a universal game telegraph duration; actual unbriefed testing remains required. |
| GDC, [VFX as a Game Design Language](https://media.gdcvault.com/GDC%2B2022/Speaker%2BSlides/VFXasagamedesignlanguage_Nguyen_An-Tim.pdf) | Affordance is the discoverable potential action of a game object. | Context Environment uses a marked world footprint plus an icon/verb that changes in the existing slot. | Decorative objects without a distinct rule are not counted as variety. |
| GDC, [Blending Autonomy and Control](https://www.gdcvault.com/play/1023383/Blending-Autonomy-and-Control-Creating) | Designers can influence systemic NPC behaviour without replacing autonomy. | Focus changes target priority; crew still approaches, times, and executes attacks automatically. | No player attack command or free movement cursor. |
| Godot, [signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html), [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), and [idle/physics processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html) | Signals reduce coupling, Control provides focus-aware input, and delta-based processing keeps timing frame-independent. | Typed snapshot/signals, native Buttons, and eligible-delta timers; UI remains an observer/intent forwarder. | No UI-owned target, cooldown, effect, or random draw. |

## Research-grounded design decisions for Part A

1. **Context is selected before input.** Environment and Focus each expose one current action/target. The player does not open a transient target list during a 0.58–1.10s windup.
2. **Priority is not an attack command.** Focus redirects only crew who are not already in windup/active/recovery, adds no damage/stun, and lets ordinary navigation/attacks determine whether interruption occurs.
3. **Environment alternatives share one conceptual slot.** The prototype never adds Power Box or Hanging Sign as parallel production buttons.
4. **Every power has an opportunity cost.** Environment shares cooldown or a finite charge; Focus can waste its cooldown on a threat already handled; Backup spends one of two run charges; Rally sacrifices attacks/position.
5. **Rally stays visibly quarantined.** It is labelled `4 DEV`, because its direct formation movement and fourth-control footprint are the exact risks being tested.
6. **Telemetry observes; it does not schedule.** It uses only supplied eligible time, consumes no stream, records opportunities/uses/holds/rejections/results, and changes no outcome.

## Rejected Part A directions

- Adaptive/unseeded encounter Director, dynamic difficulty, procedural hazards, or a new random stream.
- Enemy-selection modal, precision-only enemy click, hold input, rapid tapping, or distinct mouse versus keyboard rule.
- More than one visible Environment button.
- New enemy, crew, card, equipment, reward, shop item, status ID, save field, or permanent power.
- Power Box chain damage, Sign multi-target damage, Focus direct damage/stun, or Backup recharge.
- Rally as assumed permanent content.
- Treating implementer observation, deterministic probes, or screenshots as the five-person qualitative pass.

## Resulting recommendation

Use the production roles **Environment / Focus / Backup**. Add only Power Box beside the preserved Hydrant as a context replacement; implement Focus as one-press temporary priority with readable intent; retain Backup's exact finite authority; remove Hanging Sign and Rally from production. Exact evidence and alternatives are in `WP05_PROTOTYPE_COMPARISON.md` and the owner question is in `WP05_OWNER_SELECTION.md`.
