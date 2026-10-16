# Exhale

A personal, offline smoking-reduction tracker. You set a daily limit, it drops
by one every few days until you reach zero, and you log each cigarette with
one tap.

- **Stack:** Flutter (via FVM), Riverpod 3, get_it, Material 3
- **Design:** Stitch export in [`design/`](design/), tokens in
  [`design/obsidian_sanctuary/DESIGN.md`](design/obsidian_sanctuary/DESIGN.md)

## Run

```bash
fvm flutter pub get
fvm flutter run
```

## Checks

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```

Commit messages follow Conventional Commits (enforced by `.githooks/commit-msg`;
run `git config core.hooksPath .githooks` once after cloning).

Fonts: Manrope and Plus Jakarta Sans, SIL Open Font License (see `assets/fonts/`).
