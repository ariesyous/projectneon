# Milestone 6 Playtest Guide

## Purpose and status

This is the historical acceptance guide for the published Milestone 6 build. The build passed its cumulative automated gate: **244/244 tests and 3,234 assertions with no failures or skips across 22 suites**. Its remaining manual evidence stays pending and must not be invented.

On 2026-08-20, the owner approved the WP00 product rebaseline. That decision did not invalidate M6 technical evidence, change the deployed build, or retroactively complete this guide. It superseded M6's former status as the final prospective product boundary. Future WP01–WP07 acceptance uses the rebaseline contract in `TEST_PLAN.md`; this guide remains evidence about the unchanged M6 runtime only.

Play the current build at [ariesyous.github.io/projectneon](https://ariesyous.github.io/projectneon/).

This playtest does not repeat or reopen the separately completed Milestone 1 Human Validation Gate.

## Short tester prompt

Give this section to a tester before their first run. Avoid explaining systems, desired behavior, or the checklist below until the run ends.

> Please play Neon Loop in your browser. Start a run and make your own choices. You may stop when the run ends or whenever you feel finished. Afterward, tell me what you understood, what felt satisfying, what felt confusing, and what you wanted to do next. Please note your browser/device and take a screenshot if anything looks broken.

After the first run, ask:

1. What outcome did you reach: Victory, Extracted, Defeated, or Stopped Early?
2. Approximately how long did the run last? If a summary appeared, record its duration and seed.
3. What did you understand without explanation?
4. Which character, enemy, intervention, reward, or decision was most memorable?
5. What was confusing, hard to read, too slow, too fast, or frustrating?
6. Did you notice a reason to extract instead of continuing? What influenced the decision?
7. If you stopped early, when and why?
8. Would you play another run? What would you try differently?

Do not turn the answers into a pass/fail result while interviewing the tester. Record the tester's words and classify them afterward.

## Curator setup

Record this context for each session:

- Date and tester label; do not require a real name
- Pages URL and, if known, deployed commit
- Desktop/mobile device, operating system, browser, and approximate window size
- New browser profile/private window or returning profile
- Input used: mouse, touch, keyboard, or a combination
- Sound enabled or muted
- Crew member, outcome, summary duration, and summary seed
- Whether the tester had prior Neon Loop experience

Use a fresh/private browser profile for a clean-save test. Use the same ordinary profile for follow-up runs so unlock and settings persistence can be observed. Do not clear site data between persistence runs.

## Recommended coverage assignments

One tester does not need to cover everything. Assign sessions across the group:

| Session | Primary goal | Important observations |
| --- | --- | --- |
| First-contact run | No explanation before play | Tutorial comprehension, HUD clarity, combat readability, when/why the tester stops |
| Extraction run | Accept an extraction opportunity | Whether extraction feels understandable and meaningful; Extracted summary accuracy |
| Victory run | Decline extraction and defeat The Viper | Boss telegraphs, summon/charge/area/enrage readability, music transition, Victory summary |
| Defeat run | Continue until the crew falls | Defeat clarity, pacing, summary accuracy, desire to retry |
| Systems run | Explore interventions, equipment, cards, settings | Feedback, rejection clarity, drag/click alternatives, persistence, accessibility |
| Browser/device run | Use a different browser, resolution, or touch device | Layout, text, audio unlock, fullscreen/window behavior, input reliability |

Aim for at least one ordinary **Victory**, **Extracted**, and **Defeated** result. The intended full-run range is approximately **8–12 eligible active minutes**; record actual summary duration rather than coaching the player toward that number.

## Curator checklist

### Crew and combat identity

- Jax reads as a short-range, high-knockback Brawler with strong environmental collisions.
- Zoey reads as the fastest, lower-health Tech Fighter; reduced intervention cooldowns are noticeable, and Shock comes from equipment synergy rather than unexplained character magic.
- Rex reads as the slow, durable Bruiser who resists control and performs well against elites and The Viper.
- Street Punk, Bat Thug, and Bottle Thrower are visually and mechanically distinguishable.
- Bottle projectiles are slow and readable.
- Viper Enforcer is visibly elite; its armour, charge, control resistance, and increased reward are understandable.
- Hits, damage numbers, flashes, knockback, deaths, combo, and environmental effects are readable without depending on colour alone.

### The Viper

- The dedicated boss bar and music transition make the encounter unmistakable.
- Melee combo, charge, summon, and warned area attack have distinct, readable telegraphs.
- The one-time summon creates exactly two basic enemies without hiding the boss.
- The 40%-health enrage is noticeable and understandable.
- The boss cannot be permanently stun-locked, but player control effects still feel useful.
- The boss is defeatable through ordinary play and the Victory sequence is clear.

### Interventions and optional interaction

- Fire Hydrant clearly communicates name, targets, validity, cooldown, area preview, and activation/rejection feedback.
- Call Backup creates two useful temporary allies; their defeat or departure after roughly 12 eligible combat seconds is understandable.
- Subway Reroute clearly advances a non-boss route segment and reduces Heat without implying that it reduces Night Pressure or skips The Viper.
- Invalid, cooling-down, active, or exhausted requests provide useful feedback and do not appear to spend charges or mutate unrelated state.
- Ignoring coins still grants their full base value. Manual clicking feels optional rather than mandatory.
- Optional ambient actions appear often enough to notice without overwhelming combat.

### Decisions, builds, cards, and cadence

- Equipment and synergy choices feel meaningfully different; record the final build and active synergies from the summary.
- At least three distinct strategies appear viable across the collected sessions.
- Card planning, valid/invalid route slots, Confirm, cancellation, and **Skip / Keep Hand** are understandable.
- Coin clicks are not described as strategic decisions.
- Meaningful build/route/shop/extraction choices do not feel bunched together or absent for long stretches.
- Major continue/extract/boss-risk decisions arrive at a reasonable pace.
- Record exact examples of stretches that feel empty, rushed, repetitive, or modal-heavy.

### Tutorials, HUD, settings, and accessibility

- Contextual prompts explain controls and new systems without developer explanation.
- Prompts are readable, dismissible, nonmodal, and do not cover required action.
- HUD, boss bar, interventions, inventory, cards, settings, and summary remain contained and readable.
- Important information is conveyed with text, labels, icons, shape, or motion as well as colour.
- Exercise Master, Music, and SFX volumes; fullscreen/windowed mode; screen-shake intensity; damage numbers; hit-flash reduction; and pause-on-focus-loss where the browser permits it.
- Confirm ordinary pause works outside unskippable transitions.
- Confirm settings persist after refreshing or restarting the browser.

### Unlocks, outcomes, summaries, and cleanup

- A completed run unlocks Zoey.
- A completed run containing an elite defeat unlocks Hacker Deck.
- Extraction unlocks Gang Hideout.
- Victory unlocks Rex.
- A clean profile starts with Jax and the intended bounded catalogue; unlocks add content without permanent statistical bonuses.
- Victory, Extracted, and Defeated summaries show plausible duration, seed, maximum Heat, final Night Pressure, enemy/elite counts, boss result, coins, manual collections/streak, Scrap, highest combo, equipment, and synergies.
- Same-seed restart, new-seed restart, and Return to Main Menu work.
- Repeated restarts do not show stale actors, allies, boss UI/music, interventions, tutorials, modals, cards, equipment, or summary data.

### Browser presentation

- Check the default 1280 x 720 presentation when practical.
- Include at least one representative 1080p and 1440p desktop check.
- Include at least one touch/mobile check if available.
- Verify the initial sound-unlock gesture, ongoing music/SFX, Help, fullscreen behavior, keyboard input, pointer input, and touch input where supported.
- Record visible clipping, overlap, tiny text, missing glyphs, stretched art, black screens, audio failures, or browser-console errors.

## Feedback record template

Copy this block for each session:

```text
Tester label:
Prior Neon Loop experience:
Date/time:
URL/deployed commit if known:
Device / OS / browser:
Approximate viewport:
Input method:
Fresh or returning profile:
Sound enabled:

Crew:
Outcome: Victory / Extracted / Defeated / Stopped Early
Summary duration:
Seed:
Equipment build:
Active synergies:

What the tester understood without explanation:
Most satisfying moment:
Most confusing moment:
Reason for extracting, continuing, or stopping:
Would play again? Why or why not?

Observed defects:
- Severity: blocking / major / minor / polish
- Steps to reproduce:
- Expected:
- Observed:
- Reproduced again? yes / no / not attempted
- Screenshot/video/console text:

Curator checklist gaps or notable results:
```

## How to interpret results

- Separate defects from preferences and from missing explanation.
- Group repeated observations without erasing dissenting feedback.
- A single blocking progression, save, input, or black-screen defect should be investigated even if other testers did not reproduce it.
- Treat pacing averages cautiously; record specific early/late gaps and the decisions surrounding them.
- Do not convert this playtest into a new milestone or expand the feature roster. Fixes should remain bounded to Milestone 6 correctness, clarity, balance, presentation, and compatibility.
- The project owner decides when the tentative Milestone 6 playtest record is sufficient for final acceptance.
