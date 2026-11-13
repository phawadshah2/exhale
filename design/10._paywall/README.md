# 10. Paywall

Agreed with Fawad on 2026-11-13. Spec: `docs/superpowers/specs/2026-11-13-paywall-design.md`.
Research behind the paywall: `docs/research/2026-11-13-paywall-research.md`.
Light mode in the default Ink accent; every fill is the theme's emphasis colour. Open any
file in a browser.

| File | Screens |
| --- | --- |
| `WelcomeBack.html` | The plan reveal today, and reopened with a saved, unpaid plan (only the eyebrow and headline change) |
| `Paywall.html` | The paywall, to scale and live (tap a plan): with the free week, no price given, trial already used, App Store unreachable, and both on a small iPhone |
| `NoPrice.html` | The paywall with no price given: the build of 2026-11-13 and options A to C on three sizes; Fawad chose B (2026-11-14), with the plain "What you get" lines |
| `LockedSettings.html` | The locked screen (Home behind a glass sheet, and with Reduce Transparency) and Settings' Subscription card |

Layout and content only: glass, motion and type come from the app's widgets
(`OnboardingStepFrame`, `ChevronButton`, `StepReveal`, `showAppSheet`-style glass,
`SectionCard`). Icons are stand-ins for Cupertino icons through `AppIcons`.
