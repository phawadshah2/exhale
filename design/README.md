# Exhale designs

**Everything in one file: `all-designs.html`.** Open it in any browser. It needs no internet.

Figma, page "Exhale – All designs": https://www.figma.com/design/KMF3WeQgfFv5g2MhOiwXMM

**The Figma import is unfinished (2026-11-01).** The Starter plan's limit on tool calls stopped
it partway. "Plan details: explored" and "Edit plan and Logs: explored" are empty sections.
"Final" holds its 8 frames, but they aren't named or laid out and haven't been checked. Once
Figma allows more calls, import `figma-import/plan.html` and `figma-import/editlogs.html` into
those sections (`cssSelector` `.frame`), name the frames from `figma-import/names.json`, lay
out all three, then delete `figma-import/`.

| Figma section | Source in this folder | Live canvas (private, owner only until shared) |
| --- | --- | --- |
| Final: Plan, Edit plan, Logs | `8._plan_edit_logs/` | https://claude.ai/artifact/JaQJQ5meV7qTnZNeKiPkoK |
| Plan details: explored | `8._plan_edit_logs/` | same |
| Edit plan and Logs: explored | `8._plan_edit_logs/` | same |
| Next-log timer | `9._next_log_timer/` | https://claude.ai/artifact/NBe5B8VGM6iMXDaiuysb88 |
| Paywall, welcome back, locked screen (not in Figma) | `10._paywall/` | – |
| Home, Details and Logs; History charts; Logging, habits and plan; States | `6._home_details_logs/` | https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu |
| Earliest screens and onboarding | `1._` to `5._`, `7._onboarding/` | none |

`obsidian_sanctuary/DESIGN.md` is the original design system, in words.

The live canvases are the source of truth. `*.dc.html` files need the canvas runtime, so they
don't open on their own; each folder's `canvas.json` holds the layout.

`all-designs.html` and Figma hold still copies, one state per frame. Controls such as T's Week
and Month switch or Z's preview slider only work on the canvas, so T's month view and a 180-day
Z have frames of their own. The earliest screens and the onboarding flows are images, not
editable layers. Later canvas edits reach neither copy by themselves.

In `8._plan_edit_logs`, `Main.dc.html` is frame A (The stairs). Frame letters are in `canvas.json`.
