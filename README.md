# Milepost (Flutter)

Flutter port of the Milepost Next.js website: 10 car calculators and 4 NHTSA vehicle
lookups (VIN decoder, recalls, safety ratings, owner complaints).

## What the app looks like

Same look and motion as the website: intro splash where the red car drives along the road,
a hero with the live "Trip ticket" (odometer reels), a winding road through all 14 tools with a
car that drives as you scroll, parallax roadside scenery (petrol pump, trees, billboards),
route-shield icons (shared-element transition into each tool), highway-sign result panels and the
yellow centre-line dividers. Fonts (Overpass, Public Sans) are downloaded by `google_fonts` on first
launch (needs internet once, then cached; falls back to the system font offline).

## Run it

This folder has the Dart source only. Generate the Android/iOS/web runners once:

```bash
cd milepost_app
flutter create . --project-name milepost_app --org com.yourname
flutter pub get
flutter pub get && flutter test   # calc tests
flutter run
```

`flutter create .` keeps the existing `lib/`, `test/` and `pubspec.yaml`.

### Android: internet permission (needed for the lookups in release builds)

After `flutter create`, open `android/app/src/main/AndroidManifest.xml` and add, above `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

(Debug builds have it already, release builds do not, so the lookups would fail
silently without this line.) iOS needs nothing extra: NHTSA is HTTPS.

## Mapping from the website

| Website | Flutter |
|---|---|
| `lib/calc.ts` | `lib/core/calc.dart` (same formulas and validation) |
| `lib/format.ts` | `lib/core/format.dart` |
| `lib/tools.ts` | `lib/core/tools_data.dart` (generated from it) |
| `app/api/nhtsa/route.ts` + `lib/nhtsa.ts` | `lib/core/nhtsa.dart` (calls NHTSA directly, no proxy) |
| `components/ui.tsx` | `lib/widgets/ui.dart` (Sign, Meter, StackBar, fields) |
| `components/RouteList.tsx` | `lib/screens/route_list.dart` |
| `components/Scenery.tsx`, `glyphs.tsx` | `lib/widgets/scenery.dart`, `lib/core/svg_art.dart` (SVGs generated from the site) |
| `components/Odometer.tsx`, `HeroTicket.tsx` | `lib/widgets/odometer.dart`, `lib/screens/hero_ticket.dart` |
| `components/calculators/*` | `lib/calculators/calculators_a.dart`, `calculators_b.dart` |
| `components/lookups/*` | `lib/lookups/shared.dart`, `lookup_screens.dart` |
| `app/globals.css` colours | `lib/core/theme.dart` |

Not ported (website only): SEO metadata, sitemap, robots, llms.txt, JSON-LD, OG images,
and carrying a chosen vehicle between lookup tools through the URL.
