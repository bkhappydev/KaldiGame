---
name: kaldi-ui-ux
description: UI/UX design rules for the Kaldi kids' quiz game (Flutter). Use before adding or restyling any screen, card, popup, button or tab so it matches the 3D coffee look and does not drift into a generic, template-like style.
---

# Kaldi UI/UX rules

Kaldi is a quiz game for young children (Amharic first, English second),
branded around coffee: the legend of Kaldi, his goats and the red coffee
cherries. Every screen should feel like one hand-made object, not a template.

## 1. One material: cream ceramic on roasted wood

- **Background:** `CoffeeBackdrop` shows the picture chosen in Settings
  (`BackgroundTheme` in `lib/common/coffee3d/background_theme.dart`): Theme2,
  the dark default, plus light Theme1 and dark Theme3. Add new backgrounds
  there. Anything placed straight on the background must take its colours from
  `BackgroundTheme.of(context)` (`onBackdrop`, `pill`, `textShadows`) or be
  `OutlinedGameText`; never hard-code white or cream, or it vanishes on Theme1.
- **Content cards:** cream ceramic (`CoffeePalette.foam` → `crema`), caramel
  rim, darker cinnamon edge underneath for thickness. Use `Coffee3DPanel` or
  the same recipe.
- **Text on cards:** `CoffeePalette.roast` / `mocha`. White text belongs only on
  coloured buttons and the title ribbon.

## 2. Colour is an accent, not a fill

- A card gets **at most one accent colour**, used in **one place**: an icon
  chip, the plate behind a picture, or a progress fill.
- **No full-card rainbow gradients.** Different categories are told apart by
  their accent chip and picture, not by painting each card a different colour.
- Brand colours live in `CoffeePalette`. Category accents come from
  `QuizCategory.colors.last`. Do not invent new colours inline.
- Gold (`CoffeePalette.gold`) means stars and rewards only.
- Cherry red means "new / tap me" (gift badge, open gift) — and the Yes in a
  destructive confirm. Leaf green means "go / done / ok".

## 3. Depth is consistent

- Cards: a solid edge 6–8 px below in a darker shade + one soft shadow.
- Buttons: `Coffee3DButton` / `Coffee3DIconButton` (face over a darker side,
  presses down). Don't hand-roll another button style.
- Only **one** glowing or floating element per screen (the focal point:
  the current gift, the level bean, the quiz picture).

## 4. Skip the template tells

- No faded watermark icons in card corners.
- No gloss stripe on every surface — buttons have it, cards don't.
- No emoji in UI chrome (treats may use emoji art inside `Treat3D` only).
- No "stat tile trio" as decoration — only show a number a child or parent
  would act on.
- Don't repeat information: if a progress bar shows it, don't also print
  the same fraction twice on the same card.

## 5. Type

- Titles, numbers, badges: `kGameFont` (Lilita One) with the espresso outline
  (`OutlinedGameText`). Amharic falls back to Menbere automatically.
- Body text: theme font (Fredoka for Latin, Menbere for Ethiopic), weight 600–800.
- Never below 14 px for anything a child must read.

## 6. Kids' UX

- Tap targets ≥ 48 px. Primary actions ≥ 56 px tall.
- Every tap gets feedback: squash (`BouncyButton` / `Coffee3DButton`), click,
  light haptic.
- The next thing to do pulses (`Pulse`); nothing else does.
- No reading-only instructions: pair text with an icon or picture.
- No gates or settings a parent must unlock — settings are minor and open
  directly from the bottom bar.

## 7. Layout

- Spacing scale: 4, 8, 12, 16, 20, 24. Screen side gutter 20.
- Radii: cards 24, inner elements 16, pills fully rounded.
- Bottom navigation (Play · Treats · My Level · Settings) is always the way
  between tabs; screens pushed on top (category, quiz, result) show only a
  3D back button and the title ribbon (`CommonTopBar`).
- The Play tab has no title bar; content starts under the status bar.

## Checklist before finishing a UI change

1. Does every card use the cream material, with colour only as one accent?
2. Is there exactly one focal glow/float on the screen?
3. Are buttons the shared 3D components?
4. Does it read in both Amharic and English (check long Amharic strings)?
5. Does anything drawn straight on the background read on both the light and dark themes?
6. Run it on the emulator and look at it — screenshots, not assumptions.
