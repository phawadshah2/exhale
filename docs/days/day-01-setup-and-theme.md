# Day 1: Project setup, design tokens and your first Riverpod provider

**Goal:** turn the Stitch export into a Flutter theme that every later screen
uses, and learn the smallest useful piece of Riverpod.

Run it: `fvm flutter run`. The app opens on a temporary **Design system**
page. Switch Light / Dark / System at the top.

---

## Read the code in this order

1. `lib/core/theme/app_palette.dart`: raw hex values from Stitch.
2. `lib/core/theme/app_color_scheme.dart`: palette → Material `ColorScheme`.
3. `lib/core/theme/exhale_colors.dart`: the `ThemeExtension` for
   success / warning / danger.
4. `lib/core/theme/app_typography.dart`: the Stitch type scale.
5. `lib/core/theme/app_theme.dart`: component themes (buttons, cards, chips…).
6. `lib/features/settings/presentation/providers/theme_mode_provider.dart`:
   your first provider.
7. `lib/app/app.dart` and `lib/main.dart`: where Riverpod is wired in.
8. `lib/core/widgets/pill_segmented_control.dart`: the first reusable widget.
9. `test/`: three test files, one per concept.

---

## Concept 1: Seed colours with `DynamicSchemeVariant.fidelity`

**The problem.** Stitch gave us about 50 colour tokens for dark mode only.
Hard-coding all of them twice (light and dark), and again for every accent
colour in Settings, gives roughly 600 hex values to keep in sync.

**How it works.** `ColorScheme.fromSeed` builds a full Material palette from
one colour. The default variant (`tonalSpot`) mutes your brand colour. The
`fidelity` variant keeps the seed as the `*Container` colour, so
`#2DD4BF` stays `#2DD4BF`. I compared all nine variants against Stitch's
tokens. With `fidelity` and the eucalyptus seed, the dark `primary`,
`primaryContainer` and `onSurfaceVariant` match exactly. Only the blue-slate
surfaces don't match any seed, so they are hand-written in `NeutralRamp`.

Seeds that are very dark or very saturated get nudged for contrast. Coral
`#EF4444` comes out as `#FF5451`. A test caught this; see
`app_color_scheme_test.dart`.

**Micro-exercise (3 min).** In `app_theme.dart` change
`Color accent = AppPalette.eucalyptus` to `AppPalette.accents[2]` (violet).
Hot restart. Every button, chip and selected segment turns violet, the
surfaces stay slate, and you edited one line. Change it back.

---

## Concept 2: `ThemeExtension` for colours Material has no name for

**The problem.** The ring and chart need "over limit = red" and
"at limit = amber". Using `colorScheme.error` would mean
"error" in code that has nothing to do with errors, and `tertiary` for
"warning" is unreadable.

**How it works.** `ExhaleColors extends ThemeExtension<ExhaleColors>` is
registered in `ThemeData.extensions`, and you read it with
`context.exhale.danger.solid`. It needs two methods:

- `copyWith`, for overriding one field.
- `lerp`, for blending between light and dark. `MaterialApp` animates theme
  changes, so without `lerp` your custom colours would snap while everything
  else fades.

**Micro-exercise (2 min).** In `ExhaleColors.lerp`, temporarily
`return other;`. Run the app and switch themes slowly: the status
swatches jump while the rest fades. Revert.

---

## Concept 3: Riverpod, the minimum

**The problem.** `MaterialApp` (at the root) needs the theme mode, and the
Settings page (deep in the tree) needs to change it. Passing callbacks down
through widgets, or using a global variable, doesn't scale and isn't testable.

**How it works.** There are four pieces:

| Piece | Where | What it does |
|---|---|---|
| `ProviderScope` | `main.dart` | Holds the state of every provider. One per app. |
| `@Riverpod` class (Notifier) | `theme_mode_provider.dart` | `build()` returns the initial state; methods change `state`. |
| `ref.watch(provider)` | `app.dart` | Read **and rebuild** when it changes. Use in `build`. |
| `ref.read(provider.notifier)` | `design_system_page.dart` | Get the notifier to call a method. Use in callbacks, never in `build`. |

Codegen: `@Riverpod(keepAlive: true) class ThemeModeController` generates
`themeModeControllerProvider` in the `.g.dart` file. Regenerate after any
change to a provider's signature:

```bash
fvm dart run build_runner watch -d
```

`keepAlive: true`: by default codegen providers are *auto-dispose*, meaning
the state is thrown away when no widget watches them. Theme mode is app-wide,
so it is kept alive. Most screen-level providers later won't be.

**Micro-exercise (5 min).**
1. In `app.dart`, change `ref.watch(...)` to `ref.read(...)`. Run the app and
   tap Light. Nothing happens: the state changed, but `MaterialApp` never
   rebuilt. Revert.
2. Open `theme_mode_provider_test.dart`. `ProviderContainer.test()` is a
   `ProviderScope` without any widgets. Add a test: select `light`, then
   `system`, and expect `system`. Run `fvm flutter test`.

---

## Why a custom `PillSegmentedControl`?

Material's `SegmentedButton` draws bordered boxes with check marks. The design
has a capsule track with a sliding pill (Week | Month, Light | Dark | System).
It's about 100 lines: a `Stack` with an `AnimatedAlign` thumb under a
`Row` of labels. `Alignment.x` runs from -1 to 1, so the thumb for
segment `i` of `n` sits at `-1 + 2*i/(n-1)`.

---

## Decisions made today

- **Static fonts, not variable.** Google Fonts only ships variable `.ttf`
  files, and Flutter's `FontWeight` does not drive a variable font's weight
  axis. I cut static 400–800 files with `fonttools`, so plain
  `FontWeight.w600` just works. Fonts are bundled, so the app works fully offline.
- **Light mode is ours, not Stitch's.** Same cool slate hue as dark, cards are
  white on `#F4F7FA`.
- **Classic constructors.** Dart 3.13 offers a new `const new(...)` syntax.
  Its lint is turned off in `analysis_options.yaml` for now.
- **Theme mode isn't saved yet.** It resets on restart. It gets persisted
  once storage lands.

## Next (Day 2 candidates)

Domain layer for the plan: `ReductionPlan`, "what is the limit on date X",
the day-reset hour, under/at/over status, all pure Dart with unit tests and
no UI.
