# Settings redesign

Agreed with Fawad on 2026-11-19. Spec: `docs/superpowers/specs/2026-11-19-settings-redesign-design.md`.

`Settings.html` (open in a browser) shows take 3: the top of Settings and the Subscription
sheet for Annual or Monthly, the free week and Lifetime.

The spec is the source of truth where the mockup differs from it:

- No "Soon" rows. Notifications and Your data appear only when they ship.
- The full list (Logging, Lock Screen, Appearance, About) is in the spec, not in the mockup.

## As built (closed 2026-11-21)

Shipped on `feat/settings-redesign` and walked on Fawad's iPhone. Differences from the
mockup:

- Row values sit at the trailing edge, next to the chevron.
- The Subscription sheet is a content-sized sheet, not a tall draggable one.
- Rate, Send feedback and Privacy policy stay hidden until the App Store ID, feedback
  address and Privacy URL exist; Terms of use is Apple's standard EULA.
- A Lifetime owner whose Annual or Monthly still renews sees an amber note with a
  "Cancel <Plan>" pill. Reminders for it come with notifications.
