# 10. Paywall

Agreed with Fawad on 2026-11-13. Spec: `docs/superpowers/specs/2026-11-13-paywall-design.md`.
Light mode in the default Ink accent; every fill is the theme's emphasis colour, so the
locked screen and Settings follow the user's chosen accent. Open any file in a browser.

| File | Screens |
| --- | --- |
| `WelcomeBack.html` | The plan reveal today, and reopened with a saved, unpaid plan (only the eyebrow and headline change) |
| `Paywall.html` | The paywall after the reveal: Annual with the 7-day trial |
| `LockedSettingsStates.html` | The locked screen, Settings' Subscription card, the paywall without a trial, the paywall offline |

Layout and content only: glass, motion and type come from the app's widgets
(`OnboardingStepFrame`, `ChevronButton`, `StepReveal`, Home's stat tiles, `SectionCard`).
