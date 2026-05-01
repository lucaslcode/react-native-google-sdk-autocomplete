# react-native-google-sdk-autocomplete

A React Native plugin wrapping the native Google Places SDK (Android + iOS) for programmatic Place Autocomplete and Place Details. This plugin was basically vibe-coded with Claude Opus 3.7.

## Why?

Other libraries use plain `fetch` which uses the web api, and can't be restricted to certain apps.

## Installation

```sh
npm install react-native-google-sdk-autocomplete
# or
yarn add react-native-google-sdk-autocomplete
```

This library uses the native Google Places SDKs:
- Android: `com.google.android.libraries.places:places:5.1.1`
- iOS: `GooglePlaces` (~> 10.0)

You do not need to add them yourself.

## Setup

You must be using new architecture.

### Google Cloud

1. Create a project in the [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **Places API (New)** (not the legacy Places API).
3. Create an API key and **restrict it**:
   - iOS: restrict to your bundle ID.
   - Android: restrict to your app's signing certificate fingerprint.
   - API restriction: limit to **Places API (New)**.

### Bare React Native

You **do not** need to modify `AppDelegate`, `MainApplication`, `Info.plist`, or `AndroidManifest.xml`. Autolinking handles registration; the API key is provided at runtime via JS.

You may need to bump two minimum-version floors:

**iOS** — `ios/Podfile`:
```ruby
platform :ios, '16.0'   # GooglePlaces 10.x requires iOS 16+
```

**Android** — `android/build.gradle` (project-level):
```gradle
buildscript {
  ext {
    minSdkVersion = 23   # Places SDK 5.x requires API 23+
    compileSdkVersion = 34
  }
}
```

Then:
```sh
cd ios && pod install
```

### Expo

> Expo Go is not supported. TurboModules require a development build.

This library does not require a config plugin — just set the deployment-target floors in `app.json` / `app.config.ts`:

```json
{
  "expo": {
    "ios": { "deploymentTarget": "16.0" },
    "android": { "minSdkVersion": 23, "compileSdkVersion": 34 }
  }
}
```

Then:
```sh
npx expo prebuild
npx expo run:ios     # or run:android
```

## Usage

### Initialize once at app startup

```ts
import { Places } from 'react-native-google-sdk-autocomplete';

await Places.initialize(process.env.GOOGLE_PLACES_API_KEY!);
```

### Autocomplete + place details (with session token)

A session token groups one user's typing + final selection into a single billable session. Create one when the user starts typing, pass it through every autocomplete call and the final `fetchPlace`. The native side auto-clears it on a successful `fetchPlace`.

```ts
import { Places, type PlaceField } from 'react-native-google-sdk-autocomplete';

const sessionToken = await Places.createSessionToken();

const predictions = await Places.findAutocompletePredictions({
  query: 'sicilian piz',
  sessionToken,
  countries: ['us'],
  locationBias: {
    type: 'circle',
    center: { latitude: 37.7749, longitude: -122.4194 },
    radiusMeters: 5000,
  },
  origin: { latitude: 37.7749, longitude: -122.4194 }, // for distanceMeters
});

const fields: PlaceField[] = [
  'id',
  'displayName',
  'formattedAddress',
  'location',
  'rating',
  'websiteUri',
];

const place = await Places.fetchPlace({
  placeId: predictions[0].placeId,
  fields,
  sessionToken,   // same token — bundles autocomplete + details into one session
});
```

If the user abandons the search without selecting a place, free the token explicitly:
```ts
await Places.clearSessionToken(sessionToken);
```

### Highlighting matched substrings

Each `AutocompletePrediction` exposes `fullText`, `primaryText`, and `secondaryText` as `AttributedText` — plain text plus the offsets/lengths that matched the user's query.

```tsx
function PredictionRow({ p }: { p: AutocompletePrediction }) {
  const { text, matches } = p.primaryText;
  const sorted = [...matches].sort((a, b) => a.offset - b.offset);
  const parts: { text: string; bold: boolean }[] = [];
  let i = 0;
  for (const m of sorted) {
    if (m.offset > i) parts.push({ text: text.slice(i, m.offset), bold: false });
    parts.push({ text: text.slice(m.offset, m.offset + m.length), bold: true });
    i = m.offset + m.length;
  }
  if (i < text.length) parts.push({ text: text.slice(i), bold: false });

  return (
    <Text>
      {parts.map((p, k) => (
        <Text key={k} style={p.bold ? { fontWeight: '700' } : undefined}>
          {p.text}
        </Text>
      ))}
    </Text>
  );
}
```

## API

### `Places.initialize(apiKey: string): Promise<void>`
Must be called before any other method. Calling again with the same key is a no-op; calling with a different key throws.

### `Places.createSessionToken(): Promise<string>`
Creates a fresh session token and returns its opaque id. Keep this id alive for the lifetime of one user's typing-to-selection flow.

### `Places.clearSessionToken(token: string): Promise<void>`
Releases a session token. The native side also auto-clears the token after a successful `fetchPlace`.

### `Places.findAutocompletePredictions(request): Promise<AutocompletePrediction[]>`
Returns up to 5 predictions. See `AutocompleteRequest` in [`src/types.ts`](src/types.ts).

### `Places.fetchPlace(request): Promise<Place>`
`request.fields` is required and drives both the response shape and your billing tier. The returned `Place` only includes keys you asked for.

## Errors

All methods reject with a `PlacesError` whose `.code` is one of:

| code | meaning |
|---|---|
| `NOT_INITIALIZED` | call made before `Places.initialize()` |
| `INVALID_REQUEST` | bad inputs (>5 types, both bias+restriction set, empty query, unknown field name, etc.) |
| `UNKNOWN_SESSION_TOKEN` | session id passed but not found in the native store |
| `NETWORK_ERROR` | transient network failure |
| `API_ERROR` | non-OK SDK response (quota, invalid key, etc.) |
| `UNKNOWN` | anything else |

```ts
import { PlacesError } from 'react-native-google-sdk-autocomplete';

try {
  await Places.findAutocompletePredictions({ query: 'pizza' });
} catch (e) {
  if (e instanceof PlacesError && e.code === 'NOT_INITIALIZED') {
    // ...
  }
}
```
