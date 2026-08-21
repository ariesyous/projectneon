# WP00 Product Rebaseline — Acceptance Evidence

Status: **Complete; ready for owner review**
Owner approval recorded: 2026-08-20
Scope: documentation and representative wireframes only

## Owner decision

The owner reviewed the complete recommended D1–D7 package in `WP00_DECISION_PACKET.md` and explicitly responded: “Yeah I approve, proceed.” The approval was recorded before canonical documents were reconciled.

| Required decision | Approved answer | Canonical evidence |
| --- | --- | --- |
| North star | Plan the next block, watch the crew execute the build, intervene decisively, and bank gains or push through escalating district laps | `GameSpecifications.md` 0.1; ADR 0002 |
| Lap loop | Three laps × three blocks; Extract/Push after laps one and two; second Push commits to final lap/boss; boss run targets 8–12 eligible minutes | `GameSpecifications.md` 0.2 |
| District Plan | Two next-block choices from a finite four-card, one-copy lap deck rebuilt per lap; no release hand/five-slot planner after WP03 migration | `GameSpecifications.md` 0.3 |
| Default crew | Jax, Zoey, and Rex available on fresh production profiles | `GameSpecifications.md` 0.4 |
| Progression | Breadth/cosmetic/compendium/challenge only; Hacker Deck and Gang Hideout retained; no permanent stats; Scrap summary-only | `GameSpecifications.md` 0.4 |
| Intervention vocabulary | Environment, Focus, Backup; Subway is strategic travel; Rally is only a WP05 candidate | `GameSpecifications.md` 0.5 |
| Acceptance metrics | Five-person 4/5 clarity/consequence/variety/replay gates, 3/5 concrete replay intention, approved timing distributions, and technical compatibility rules | `GameSpecifications.md` 0.6; `TEST_PLAN.md` |

## Representative wireframes

The evidence set covers all six requested contexts:

1. Minimal combat HUD
2. Focused District Plan
3. Reward/equipment decision
4. Shop
5. Lap-end Extract/Push
6. Run summary

Files:

- [Rendered overview](wireframes/wp00_wireframes.png)
- [Editable SVG source](wireframes/wp00_wireframes.svg)
- [Wireframe notes](wireframes/README.md)

Verification: the SVG parses as valid XML; the rendered PNG is 1580 × 1400 and 318,453 bytes; visual inspection confirmed all six frames render, use one-decision-at-a-time hierarchy, and pair unfamiliar symbols with labels. They are structural evidence, not approved final art or implemented UI.

## Canonical reconciliation

| Document | Reconciliation completed |
| --- | --- |
| `GameSpecifications.md` | Added authoritative WP00 section, exact D1–D7 target, superseded-rule table, presentation/intervention/card/progression updates, and WP01–WP07 roadmap |
| `AGENTS.md` | Added the approved boundary, current-versus-target warning, preserved deterministic/authority rules, and bounded roadmap scope |
| `ARCHITECTURE.md` | Added lifecycle, authority/migration, compatibility/deprecation, presentation, content-access, and sequencing maps |
| `IMPLEMENTATION_PLAN.md` | Marked WP00 complete, recorded WP01–WP07 as planned/not started, and replaced only the prospective M6 stopping boundary |
| `TEST_PLAN.md` | Added the approved qualitative, timing, evidence, and technical-compatibility contract while retaining M0–M6 results |
| `CONTENT_CATALOG.md` | Separated current M6 content/access from approved WP02/WP03 targets and recorded that WP00 adds no content |
| `CHANGELOG.md` | Appended the documentation-only decision and preserved historical release entries with time-qualified scope language |
| `MILESTONE_6_PLAYTEST.md` | Marked it as historical M6 evidence rather than the future rebaseline acceptance gate |
| Product docs and WP00 package | Changed proposal statuses to approved, aligned exact choices/roadmap, and recorded acceptance |
| ADR 0002 | Recorded the accepted decision, supersessions, consequences, ownership, and exclusions |

## Milestone 6 conflict resolution

All conflicts named in the decision packet are resolved prospectively without rewriting implementation history:

- final stopping boundary → bounded WP01–WP07 roadmap, with no Milestone 7;
- pressure-only player loop → explicit three-by-three lap structure, with Heat/Night Pressure authority retained pending WP02;
- persistent hand/five slots → focused next-block District Plan pending WP03;
- Jax-only production default → all crew target pending safe WP02 migration;
- Zoey/Rex core-style unlock gates → retired prospectively; Hacker Deck/Gang Hideout breadth gates retained;
- Hydrant/Backup/Subway bar → Environment/Focus/Backup target; Subway classified as strategic travel;
- broad simultaneous HUD → minimal actionable combat layer plus focused decisions;
- generic 30–60 strategic cadence → 45–90 complete-block target; M6 tracker evidence remains historical;
- M6 pending manual guide → historical build evidence, not future product acceptance;
- schema-1 risk → unchanged in WP00, with a mandatory WP03 compatibility stop if draw semantics prove incompatible;
- current cooling shop and statistical summary → preserved as implemented until WP04/WP01/WP07 presentation work.

## Scope and preservation audit

Audit run after reconciliation:

- `git diff --name-only -- scripts scenes data tests` returned no paths.
- SVG XML validation passed.
- PNG header validation reported 1580 × 1400.
- `git diff --check` returned no errors for tracked WP00 changes.
- A canonical conflict scan found no active unresolved stopping-boundary, owner-approval, or proposal-status wording. The only exact old stopping-boundary sentence is quoted in the approved decision packet's conflict table as the rule being superseded.
- The pre-existing dirty `project.godot` and Godot-AI paths remained outside all WP00 edits. The audit still reports 52 such owner-carried paths; none is attributed to WP00.
- No gameplay code, scene, Resource, test implementation, project setting, profile/save, random schema, Git branch/history, commit, push, publication, deployment, or external service was changed.
- No Godot launch was performed or claimed because WP00 changes no runtime/input behavior; runtime verification belongs to the package that changes it.
- WP01 is explicitly recorded as not started.

## Acceptance-gate result

| WP00 criterion | Result |
| --- | --- |
| Explicit owner approval for all seven decisions | **Passed** |
| Representative wireframes exist | **Passed** |
| Authority/migration/compatibility map exists | **Passed** |
| Every named M6 prospective conflict reconciled canonically | **Passed** |
| Historical M0–M6 verification preserved | **Passed** |
| Canonical docs agree on target, current runtime, ownership, scope, and validation | **Passed** |
| No gameplay or external-state change | **Passed** |
| Unrelated Godot-AI/project changes preserved | **Passed** |
| WP01 not begun | **Passed** |

WP00 is complete. The next eligible package is WP01, but it requires a separate explicit owner request.
