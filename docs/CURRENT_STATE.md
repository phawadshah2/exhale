# Current state

Updated 2026-11-05. Earlier sessions: `docs/history/2026-10-16_to_11-03_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 Habits foundation, M2 Dashboard and Logs, M3 Logging and editing, onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6). Real iPhone pass still open |
| M6 Plan details, Edit plan, Logs (Tasks 1 to 12) | Done on `feat/plan-and-stages`: reviewed, two simulator walks |
| UI fixes from Fawad's review (Phase 4b, F1 to F4) | Done; seen in the simulator, light mode |
| UI review round 2 (Logs, Plan, Home, transitions) | Done, committed (a947c2d) |
| M7 Stage management (Tasks 13 to 20) | Done: reviewed, fixed, simulator walk 2026-11-04 |
| Stage polish P1 to P4 (`docs/superpowers/plans/2026-11-04-stage-polish.md`) | Done, committed; seen in the simulator, approved by Fawad |
| Green under the limit G1, trigger colours G2 (`docs/superpowers/plans/2026-11-04-green-under.md`) | Done, walked light and dark, approved; merged into `feat/plan-and-stages` |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md` (all tasks ticked). Spec for
M7: `docs/superpowers/specs/2026-11-02-stage-management-design.md`.

## Repo

- Branch `feat/plan-and-stages`, 94 commits ahead of `main`; `feat/green-under`
  fast-forwarded into it. Pushed up to 6dcec71; 0854339, 4f45635 and b2c556a (iOS config,
  docs) are local only. No PR is open, and CI was not read.
- Checks at 7a80954: full suite 1211 passed, 0 failed (`build/test-report.json`); format
  and `analyze --fatal-infos` clean. Not rerun since: later commits change no Dart code;
  the release build (`build ipa`) succeeded.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## M7 simulator walk (2026-11-04, `exhale` iOS 26.5)

`lib/main_seed.dart` (git-excluded) now takes `--dart-define=SEED_STAGE=hold|review|reassess`:
12 a day with weekly drops, the latest stage ending yesterday. Uninstall the app between runs.

- Hold, dark and light: "9 can wait.", 76 against 70, next drop Nov 11 (was today), quit
  Jan 13 (was Jan 6). Keep moved today to 9 and stage 4; Got it kept 10 and stage 3.
- Review, light and dark: card without a number (two limits in the 14 days); sheet tiles,
  top 3 triggers, three choices with dates and change labels; Keep variant of button and
  footer. "Shake on it again" started stage 1/10 at 10.
- Reassess, dark and light: card, sheet, Still yours tiles, nicotine support line, Start
  again from 12 (Jan 27, 3 weeks later). Keep my plan closed the card, plan unchanged.

## Walk rulings (Fawad, 2026-11-05)

Plan `docs/superpowers/plans/2026-11-05-walk-rulings.md`, R1 to R3 done and committed, each
with its tests, format and analyze clean. Spec 4, 5.2 and 5.3 updated. R1: the review's
tiles, average, triggers and "Start from your real number" use the two failed weeks (the
hold's window and the review's), not 14 days in a row. R2: hold card tiles stand out in
light mode. R3: "0%" with no arrow vs baseline.

Walked 2026-11-05 (`exhale` iOS 26.5): review seed, light and dark, 157 logged against 147,
About 12, real number 12 a day (Jan 28); card without a number. Hold seed, light: tiles solid
with an outline, 76 against 70 unchanged. Reassess seed: "0%" with the minus icon. Not seen:
R2 and R3 in dark mode beyond the review sheet.

## Stage polish and colours (2026-11-04)

- Stage polish walked and approved; the sheet fix was not seen (no card showed).
- Under the limit is green (`success.solid`) through `LimitStatus.barColor` alone; Home's
  today ring, all text and the week chart's line keep the accent.
- Triggers use 9 fixed slots, 198° to 318° (`trigger_ui.dart`), distinct within each
  habit. 331° looked crimson beside red, so the range stops at 318°.

## TestFlight (2026-11-05)

- Personal team `5W8A3P22WK` (was the office team), iPhone only, portrait,
  `ITSAppUsesNonExemptEncryption` false (0854339, 4f45635). App record created in App
  Store Connect.
- `fvm flutter build ipa --release --build-name=1.0.0 --build-number=1` built
  `build/ios/ipa/exhale.ipa` from `feat/plan-and-stages`, signed with a cloud-managed
  Apple Distribution certificate (no local key to back up). Uploaded via Transporter
  2026-11-05; processing and the internal testing group not yet confirmed.
- Icon and launch image are Flutter placeholders: fine for internal testing, needed before
  external testers or review. Each new upload needs a higher `--build-number`.

## Next action

Fawad confirms the TestFlight build finished processing, adds himself to an internal group
and installs it; he reports what he sees on the real iPhone (open checks below). The
TestFlight build runs `lib/main.dart`, so the seeded M7 screens (`SEED_STAGE`) still need a
debug run on the device. In parallel: push the three local commits, open the PR to `main`
(https://github.com/phawadshah2/exhale/compare/main...feat/plan-and-stages) and read the
"Analyze & test" check. Before external testers: a real app icon (1024×1024 PNG, no alpha)
and launch image from Fawad. To continue, read only this file.

## Open checks

- Not seen: dark mode of the F1 to F4 screens, Reduce Transparency, text at 200% in the
  simulator, a real iPhone (glass performance, chart scrolling with 90+ days, returning
  from the background, the M6 and M7 screens), a long plan, Plan details at 200%.
- Round 2 not seen in the simulator: range mode, the date wheel, tab fade, dark mode.
- M7 not seen: Reduce Transparency, text at 200%, the alcohol line, a late-open hold card.
- Colours walked only under Ink: Eucalyptus and Ocean accents not seen.
