---
name: Obsidian Sanctuary
colors:
  surface: '#0e141d'
  surface-dim: '#0e141d'
  surface-bright: '#343944'
  surface-container-lowest: '#080e17'
  surface-container-low: '#161c25'
  surface-container: '#1a2029'
  surface-container-high: '#242a34'
  surface-container-highest: '#2f353f'
  on-surface: '#dde2f0'
  on-surface-variant: '#bacac5'
  inverse-surface: '#dde2f0'
  inverse-on-surface: '#2b313b'
  outline: '#859490'
  outline-variant: '#3c4a46'
  surface-tint: '#3cddc7'
  primary: '#57f1db'
  on-primary: '#003731'
  primary-container: '#2dd4bf'
  on-primary-container: '#00574d'
  inverse-primary: '#006b5f'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffd29f'
  on-tertiary: '#472a00'
  tertiary-container: '#ffad3a'
  on-tertiary-container: '#6d4400'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#62fae3'
  primary-fixed-dim: '#3cddc7'
  on-primary-fixed: '#00201c'
  on-primary-fixed-variant: '#005047'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#0e141d'
  on-background: '#dde2f0'
  surface-variant: '#2f353f'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Manrope
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1.25rem
  margin-lg: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a tranquil, non-judgmental environment engineered to support personal smoking reduction and cessation. The experience avoids punitive or clinical visual tropes, instead offering a serene, sanctuary-like atmosphere where progress is tracked with dignity and mindfulness. 

The aesthetic merges minimal dark-mode glassmorphic touches with warm tactile surfaces:
- **Atmosphere:** Deep obsidian grounds the interface, eliminating eye fatigue during evening or trigger-prone moments.
- **Tone:** Encouraging, steady, understated, and restorative. Luminous eucalyptus signals vitality and steady breath.
- **Visual Movement:** Soft layered depth using dark slate containers, subtle borders, and delicate outer glows rather than harsh planar separation.

## Colors

The palette is tuned specifically for an immersive, low-arousal night-mode canvas that emphasizes clarity and emotional composure:

- **Primary (`#2DD4BF`):** Serene luminous eucalyptus. Serves as the primary touchpoint, active state indicator, and key interactive focal point.
- **Secondary / Success (`#10B981`):** Restorative emerald. Applied to successful intervals, under-limit streaks, and milestone achievements.
- **Tertiary / Warning (`#F59E0B`):** Warm golden amber. Applied when approaching target limits, prompting mindfulness without triggering anxiety.
- **Danger / Over-Limit (`#EF4444`):** Soft coral red. Balanced with muted saturation to signal over-limit states objectively without feeling punitive.
- **Background (`#0B111A`):** Deep obsidian slate providing an anchor for all views.
- **Surface Tiers:**
  - `surface`: `#131D2A` (primary card backings and elevated modules).
  - `surface-container`: `#1B2737` (nested metrics, interactive panels, navigation docks).
  - `surface-variant`: `#243447` (borders, dividers, inactive pill backings).
- **Typography & Icons:**
  - `text-primary`: `#F8FAFC` (high readability, titles, active counters).
  - `text-muted`: `#94A3B8` (contextual metadata, secondary metrics, unit labels).

## Typography

Typography pairs structured, geometric clarity in headlines (`Manrope`) with soft, organic legibility in running copy (`Plus Jakarta Sans`).

- **Display & Headlines:** Set in `Manrope` with slightly tightened tracking to provide grounded, modern confidence for large counter displays, day counts, and daily reflections.
- **Titles & Body:** Set in `Plus Jakarta Sans` to ensure clear scanability at small sizes within mobile tiles, time stamps, and health benefit timelines.
- **Numerics:** Hero smoke-free timer counters and interval stats use tabular figures within `Manrope` to eliminate jitter during real-time tick-ups.

## Layout & Spacing

The layout is built for single-handed mobile navigation using a 4-column mobile grid expanding to 8 columns on tablets:

- **Horizontal Margins:** Set to `1.25rem` (20px) on standard viewports, expanding to `1.5rem` (24px) on wider displays, keeping content within optimal thumb reach.
- **Rhythm & Stacking:** Cards and milestone widgets maintain vertical spacing through `space-md` (16px) and `space-lg` (24px) distributions. Inner component paddings follow an 8pt modular discipline (`space-sm` for compact tags, `space-md` for standard card insets, and `space-lg` for breathing room around the central progress dial).
- **Responsive Handling:** Layouts adapt through responsive bottom sheets, sticky footers for rapid smoke logging, and flexible grids for quick-stat summaries.

## Elevation & Depth

Visual hierarchy relies on structural tonal tiers combined with soft perimeter illumination rather than sharp drop shadows:

- **Layer 0 (Canvas):** Pure `#0B111A`.
- **Layer 1 (Cards & Baseline Surfaces):** `#131D2A` paired with a 1px border of `#243447` to preserve boundary definition without visual harshness.
- **Layer 2 (Interactive Floating Modules & Modals):** `#1B2737` supplemented by an ultra-diffused shadow: `0px 12px 32px -4px rgba(0, 0, 0, 0.45)`.
- **Eucalyptus Glow (Active Accent States):** Key components (such as the primary log trigger and active ring indicators) utilize an ambient diffuse aura: `0px 0px 24px -2px rgba(45, 212, 191, 0.25)`.

## Shapes

The interface embraces organic curvature to soften interactions and reinforce wellness:

- **Cards & Sheets:** Base cards feature smooth continuous radii (20px to 24px), matching `rounded-lg`.
- **Interactive Controls:** Action buttons, metric tags, pill toggles, and chips strictly adopt full capsule silhouettes (`9999px` / `rounded-xl`).
- **Inner Containers:** Nested elements inside cards maintain proportional concentric geometry, scaling down to 12px–16px radii.

## Components

- **Buttons:**
  - *Primary Action:* Full pill button (`9999px`), background in luminous eucalyptus (`#2DD4BF`), text in dark slate (`#0B111A`, bold). Subtle teal halo on focus/press.
  - *Secondary / Ghost:* Full pill button with `#1B2737` fill, 1px border in `#243447`, and `#F8FAFC` typography.
- **Cards & Metric Panels:**
  - Built with `#131D2A` background, 20px–24px corners, and 16px internal padding. Secondary data badges inside cards use `#1B2737` fills.
- **Circular Progress Rings:**
  - Track background rendered in `#1B2737` with an 8px–12px stroke width. Active stroke applies a clean linear gradient from `#10B981` to `#2DD4BF` with rounded end-caps. Center area accommodates the primary timer or cigarette counter.
- **Segmented Buttons & Chips:**
  - Filter chips and time-range selectors utilize full pill forms. Selected state fills with `#2DD4BF` (text `#0B111A`); unselected state uses `#1B2737` surface with `#94A3B8` label.
- **Timeline Tiles:**
  - Vertical milestone feeds connected with a 2px `#243447` spine. Passed milestones use `#10B981` circular icons; upcoming recovery checkpoints use muted `#1B2737` nodes.
- **Bottom Navigation & Sheets:**
  - Floating dock navigation with a frosted translucent slate surface (`rgba(19, 29, 42, 0.85)` with blur filter) and active icon indicators highlighted with `#2DD4BF`. Bottom sheets utilize a 24px top radius and centered pill drag handle (`#64748B`).
- **SnackBars & Alerts:**
  - Non-intrusive floating capsules aligned above bottom navigation, featuring tonal indicator dots (`#10B981`, `#F59E0B`, or `#EF4444`) accompanied by supportive, mindful microcopy.