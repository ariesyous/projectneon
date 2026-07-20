# Neon Loop

Neon Loop is a Godot 4.x pixel-art auto-brawler about shaping an automatic street fight, managing escalating risk, intervening at decisive moments, and deciding when to extract.

## Play online

Play the technically verified Milestone 4.2 build at **[ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/)**.

The public build is deployed from `main` at commit `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`. This records the actual Milestone 4–4.2 Pages release without assigning a semantic version.

Repository: [github.com/ariesyous/projectneon](https://github.com/ariesyous/projectneon)

## Project status

**Milestone 5 — District Cards: technically implemented and verified on the local working branch**

The current local working branch adds:

- Typed card/effect Resources and exactly four stable-ID, one-copy cards: Arcade, Convenience Store, Gang Hideout, and Subway Entrance; all display `FREE`
- A finite four-card deck, deterministic two-card opening hand, hand capacity three, discard pile, no reshuffle, and clean restart
- Five stable future-route slots with one revisioned card modification per occurrence, staged confirmation, exactly-once Heat, and reached-node resolution
- Arcade's non-recursive fight and one-step authored reward-quality increase; Convenience Store's single existing-stock purchase; Gang Hideout's scaled elite placeholder and guaranteed equipment; Subway Entrance's exact one-encounter skip
- Supplemental card rewards after eligible baseline non-elite encounters, with up to three remaining choices and **Skip / Keep Hand**, without replacing ordinary standard/equipment rewards or recursing
- Selection only through the isolated `cards` stream after stable-ID filtering/sorting, with same-seed replay and cosmetic/other-stream isolation
- Safe planning that pauses eligible time and Night Pressure, preserves extraction/boss precedence, and cannot reopen thresholds or clear/bypass a queued boss
- Native drag/drop plus mouse/touch threshold fallback, first-pointer ownership, right-click cancel, immediate invalid/outside return feedback, and complete click/tap/keyboard alternatives
- A contained native 1280 x 720 card hand, detail, route-slot, highlight, feedback, and pending/resolved minimap presentation alongside all preserved Milestone 0–4.2 systems

Godot 4.7 verification passed **188/188 tests and 2,450 assertions with no failures or skips across 15 suites**. This preserves all 145 Milestone 1–4.2 tests/1,709 assertions and adds 43 Milestone 5 tests/741 assertions. Fresh Windows and Web release exports completed successfully, the exported Windows runtime smoke exited 0, and the locally served Web build passed real pointer/click card flows at 1280 x 720 with an empty warning/error console. Evidence: `docs/screenshots/milestone_5_district_cards.png`.

The project owner recorded the separate five-person Milestone 1 Human Validation Gate as **PASSED** on 2026-07-18. That qualitative decision belongs to the owner and is distinct from automated and coding-agent verification.

The public site does not yet contain Milestone 5. The M5 work remains local and uncommitted on `codex/milestone-5-district-cards`; it has not been pushed, merged, published, or deployed.

![Published Milestone 4.2 Inventory Drag](docs/screenshots/milestone_4_2_inventory_drag.png)

![Local Milestone 5 District Cards verification](docs/screenshots/milestone_5_district_cards.png)

## Running the project

1. Install Godot 4.7 or a compatible Godot 4.x release.
2. Open `project.godot` in the Godot editor.
3. Run the project with <kbd>F5</kbd> or the editor's Run Project button.

The configured main scene opens directly into `GameRun`.

### Player controls

- Click or tap a coin cluster to collect immediately and build a manual streak; ignoring it still grants the full base value
- Click or tap the Fire Hydrant when it is ready and a Street Punk is inside its preview circle
- Use the visible run-action controls to claim rewards, spend finite Subway or shop cooling, continue, extract, and advance the boss trigger
- Use **PLAN CARDS** at a safe route-planning state, then click/tap or drag a hand card to one of the five future route slots; review and press **Confirm** before authority changes
- Right-click to cancel an active card drag; invalid or outside drops return the card to the hand without changing Heat, route state, piles, rewards, or deterministic streams
- Use **Skip / Keep Hand** to decline a card reward, including when the three-card hand is full
- Inspect or manage the three generic active equipment slots and one three-slot inactive backpack through the existing drag or click/tap/keyboard flows; destructive discard remains separately named and confirmed
- Press <kbd>Space</kbd> to pause or resume eligible run time
- Press <kbd>E</kbd> to confirm extraction while an extraction window is available
- Use **Help** to reopen the nonmodal guidance
- Use **Fullscreen** as the primary desktop and mobile presentation control; Escape exits fullscreen where supported

Reward and run-action buttons respond to one ordinary click or tap.

### Development controls

- <kbd>F1</kbd>: show or hide the debug overlay
- <kbd>F2</kbd>: show or hide the three debug combat lanes

<kbd>F11</kbd> requests fullscreen only when the platform delivers it to the game. Browsers that retain F11 continue to use their normal browser behavior.

## Current scope

Milestone 4, including its M4.1 and M4.2 equipment usability corrections, is technically complete and is the current public release from `1b3d5a5118ad31d864266ec2aefd44e652ffafe9`. Milestone 5 District Cards is technically implemented and verified only in the current local working branch.

Milestone 5 stops at the four-card catalogue, finite deck/hand/discard model, supplemental card reward source, five fixed future-route slots, four bounded effects, deterministic `cards`-stream selection, and safe planning UI. The boss scope still ends at threshold latching, safe queueing, `BOSS_INTRO`, and `BOSS_ACTIVE`.

Milestone 6 crew/enemy/elite-actor/boss/intervention/presentation/audio/tutorial/settings/persistence/final-summary work; procedural route generation; additional districts/cards; equipment selling/salvage/rarity/uniques/affixes/sets; a card currency/economy; broad progression; and final-boss content remain unimplemented and unauthorized.

## Documentation

- [GameSpecifications.md](GameSpecifications.md) — product source of truth
- [AGENTS.md](AGENTS.md) — repository rules, verified scope, and milestone gates
- [ARCHITECTURE.md](ARCHITECTURE.md) — scene and system ownership
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — milestone status and next work
- [TEST_PLAN.md](TEST_PLAN.md) — verification history and planned coverage
- [CONTENT_CATALOG.md](CONTENT_CATALOG.md) — implemented and specified content
- [CHANGELOG.md](CHANGELOG.md) — project history
- [ADR 0001](docs/decisions/0001-run-engagement-escalation-and-randomness.md) — engagement, escalation, randomness, and validation decisions

## License

Project licensing is recorded in [LICENSE](LICENSE). The bundled Godot AI development addon retains its own MIT license under `addons/godot_ai/LICENSE`.
