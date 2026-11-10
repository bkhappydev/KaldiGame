# Kaldi Game

A coffee-themed picture quiz game for young children, in English and Amharic,
by **Aynu Labs PLC** (aynulabs@gmail.com).

Google Play: <https://play.google.com/store/apps/details?id=com.aynu.kids.kaldi_app>

## Build

```bash
flutter pub get
flutter run                          # debug on a device/emulator
flutter test
flutter build appbundle --release --android-skip-build-dependency-validation
```

The Play bundle is written to `build/app/outputs/bundle/release/app-release.aab`.
Copies of uploaded bundles are kept in `release/` (git-ignored).
Signing uses `android/key.properties` + `android/upload-key.jks` (both
git-ignored — never commit them).

Before each Play release, raise `version:` in `pubspec.yaml` (the number after
`+` must be higher than the one on Play). The app forces players onto the
latest Play version at start-up (`lib/utils/app_updater.dart`).

## Project layout

| Path | What it is |
| --- | --- |
| `lib/ui/` | Screens: splash, bottom-nav shell, categories, quiz, result, rewards, my level, settings, force update |
| `lib/common/coffee3d/` | Shared 3D coffee widgets, palette and background themes |
| `lib/rewards/` | Stars, player level, gift boxes and treats |
| `lib/accessibility/` | Read-aloud narration, audio quiz, screen-reader helpers |
| `lib/data/quiz_catalog.dart` | Quiz categories and their order |
| `lib/database/` | Bundled SQLite quiz data (`assets/database/KidsGamesFlutter.db`) |
| `lib/localization/` | English and Amharic strings |
| `assets/items/<level>/` | Quiz pictures |
| `assets/3d/` | 3D icons (Fluent Emoji 3D, MIT — see `LICENSE-fluent-emoji.txt`) |
| `docs/privacy-policy.html` | Public privacy policy (keep in sync with the in-app one) |

Design rules for new UI: `.claude/skills/kaldi-ui-ux/SKILL.md`.

## Credits

- Photos: see `PHOTO_CREDITS.md` (some are CC BY-SA and must stay credited in the app).
- Music: "Children's March Theme" by Cleyton Kauffman (CC0) — `assets/sounds/CREDITS.txt`.
- Fonts: Fredoka and Lilita One (SIL Open Font License), Menbere.
