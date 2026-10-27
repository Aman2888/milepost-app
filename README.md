# Milepost

Free car calculators and NHTSA vehicle lookups (VIN decoder, recalls, safety ratings, owner complaints). Flutter port of the Milepost website.

**Application ID:** `com.milepost.app`

## Run (debug)

```bash
flutter pub get
flutter run
```

Calc formula tests:

```bash
flutter test
```

## Release / Play Store

1. Create an upload keystore (once):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias milepost
```

2. Copy `android/key.properties.example` → `android/key.properties` and fill in passwords / paths.

3. Build:

```bash
flutter build appbundle --release
# or
flutter build apk --release
```

Outputs:

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

`key.properties` and `*.jks` are gitignored — never commit them.

## Notes

- Release builds use R8 minify + resource shrinking.
- Without `key.properties`, release falls back to the debug keystore (local testing only).
- Android release needs the `INTERNET` permission (already in the main manifest) so NHTSA lookups work; iOS needs nothing extra (HTTPS).

## Mapping from the website

| Website | Flutter |
|---|---|
| `lib/calc.ts` | `lib/core/calc.dart` (same formulas and validation) |
| `lib/format.ts` | `lib/core/format.dart` |
| `lib/tools.ts` | `lib/core/tools_data.dart` (generated from it) |
| `app/api/nhtsa/route.ts` + `lib/nhtsa.ts` | `lib/core/nhtsa.dart` (calls NHTSA directly, no proxy) |
| `components/ui.tsx` | `lib/widgets/ui.dart` (Sign, Meter, StackBar, fields) |
| `components/RouteList.tsx` | `lib/screens/route_list.dart` |
| `components/Scenery.tsx`, `glyphs.tsx` | `lib/widgets/scenery.dart`, `lib/core/svg_art.dart` |
| `components/Odometer.tsx`, `HeroTicket.tsx` | `lib/widgets/odometer.dart`, `lib/screens/hero_ticket.dart` |
| `components/calculators/*` | `lib/calculators/calculators_a.dart`, `calculators_b.dart` |
| `components/lookups/*` | `lib/lookups/shared.dart`, `lookup_screens.dart` |
| `app/globals.css` colours | `lib/core/theme.dart` |

Not ported (website only): SEO metadata, sitemap, robots, llms.txt, JSON-LD, OG images,
and carrying a chosen vehicle between lookup tools through the URL.
