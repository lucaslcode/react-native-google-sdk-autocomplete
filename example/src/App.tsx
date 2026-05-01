import { useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import {
  Places,
  type AttributedText,
  type AutocompletePrediction,
  type Place,
  type PlaceField,
  PlacesError,
} from 'react-native-google-sdk-autocomplete';

// Replace with your own key — see https://developers.google.com/maps/documentation/places
const GOOGLE_PLACES_API_KEY = 'YOUR_API_KEY_HERE';

const DETAIL_FIELDS: PlaceField[] = [
  'id',
  'displayName',
  'formattedAddress',
  'location',
  'rating',
  'userRatingCount',
  'priceLevel',
  'websiteUri',
  'internationalPhoneNumber',
  'businessStatus',
];

export default function App() {
  const [ready, setReady] = useState(false);
  const [initError, setInitError] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [predictions, setPredictions] = useState<AutocompletePrediction[]>([]);
  const [selected, setSelected] = useState<Place | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sessionTokenRef = useRef<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    Places.initialize(GOOGLE_PLACES_API_KEY)
      .then(() => setReady(true))
      .catch((e) => setInitError(e?.message ?? String(e)));
  }, []);

  async function ensureSession(): Promise<string> {
    if (sessionTokenRef.current) return sessionTokenRef.current;
    const tok = await Places.createSessionToken();
    sessionTokenRef.current = tok;
    return tok;
  }

  function onChangeText(text: string) {
    setQuery(text);
    setSelected(null);
    setError(null);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!text.trim()) {
      setPredictions([]);
      return;
    }
    debounceRef.current = setTimeout(() => {
      runAutocomplete(text).catch(() => {});
    }, 200);
  }

  async function runAutocomplete(text: string) {
    try {
      const sessionToken = await ensureSession();
      const result = await Places.findAutocompletePredictions({
        query: text,
        sessionToken,
      });
      setPredictions(result);
    } catch (e: any) {
      setError(formatError(e));
    }
  }

  async function onPickPrediction(p: AutocompletePrediction) {
    setBusy(true);
    setError(null);
    try {
      const sessionToken = sessionTokenRef.current ?? undefined;
      const place = await Places.fetchPlace({
        placeId: p.placeId,
        fields: DETAIL_FIELDS,
        sessionToken,
      });
      setSelected(place);
      // Native side auto-clears the session token on successful fetchPlace.
      sessionTokenRef.current = null;
    } catch (e: any) {
      setError(formatError(e));
    } finally {
      setBusy(false);
    }
  }

  if (initError) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.error}>Init failed: {initError}</Text>
        <Text style={styles.hint}>
          Set GOOGLE_PLACES_API_KEY in example/src/App.tsx.
        </Text>
      </SafeAreaView>
    );
  }

  if (!ready) {
    return (
      <SafeAreaView style={styles.container}>
        <ActivityIndicator />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Google Places Autocomplete</Text>
      <TextInput
        style={styles.input}
        placeholder="Try: sicilian piz"
        autoCorrect={false}
        autoCapitalize="none"
        value={query}
        onChangeText={onChangeText}
      />
      {error && <Text style={styles.error}>{error}</Text>}
      {selected ? (
        <PlaceDetails place={selected} onBack={() => setSelected(null)} />
      ) : (
        <FlatList
          data={predictions}
          keyExtractor={(p) => p.placeId}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => onPickPrediction(item)}
              style={styles.row}
            >
              <RichText attr={item.primaryText} style={styles.primary} />
              <RichText attr={item.secondaryText} style={styles.secondary} />
              {item.distanceMeters != null && (
                <Text style={styles.distance}>{item.distanceMeters} m</Text>
              )}
            </Pressable>
          )}
        />
      )}
      {busy && (
        <View style={styles.busyOverlay}>
          <ActivityIndicator />
        </View>
      )}
    </SafeAreaView>
  );
}

function RichText({ attr, style }: { attr: AttributedText; style: any }) {
  const parts: { text: string; bold: boolean }[] = [];
  let cursor = 0;
  const sorted = [...attr.matches].sort((a, b) => a.offset - b.offset);
  for (const m of sorted) {
    if (m.offset > cursor) {
      parts.push({ text: attr.text.slice(cursor, m.offset), bold: false });
    }
    parts.push({
      text: attr.text.slice(m.offset, m.offset + m.length),
      bold: true,
    });
    cursor = m.offset + m.length;
  }
  if (cursor < attr.text.length) {
    parts.push({ text: attr.text.slice(cursor), bold: false });
  }
  return (
    <Text style={style}>
      {parts.map((p, i) => (
        <Text key={i} style={p.bold ? styles.bold : undefined}>
          {p.text}
        </Text>
      ))}
    </Text>
  );
}

function PlaceDetails({ place, onBack }: { place: Place; onBack: () => void }) {
  return (
    <ScrollView style={styles.detail}>
      <Pressable onPress={onBack} style={styles.back}>
        <Text style={styles.backText}>← Back</Text>
      </Pressable>
      <Text style={styles.detailTitle}>{place.displayName ?? '(no name)'}</Text>
      {place.formattedAddress && (
        <Text style={styles.detailLine}>{place.formattedAddress}</Text>
      )}
      {place.rating != null && (
        <Text style={styles.detailLine}>
          ⭐ {place.rating} ({place.userRatingCount ?? 0} reviews)
        </Text>
      )}
      {place.priceLevel && (
        <Text style={styles.detailLine}>Price: {place.priceLevel}</Text>
      )}
      {place.businessStatus && (
        <Text style={styles.detailLine}>Status: {place.businessStatus}</Text>
      )}
      {place.internationalPhoneNumber && (
        <Text style={styles.detailLine}>{place.internationalPhoneNumber}</Text>
      )}
      {place.websiteUri && (
        <Text style={styles.detailLine}>{place.websiteUri}</Text>
      )}
      {place.location && (
        <Text style={styles.detailLine}>
          {place.location.latitude.toFixed(5)}, {place.location.longitude.toFixed(5)}
        </Text>
      )}
    </ScrollView>
  );
}

function formatError(e: unknown): string {
  if (e instanceof PlacesError) return `[${e.code}] ${e.message}`;
  if (e instanceof Error) return e.message;
  return String(e);
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  title: { fontSize: 22, fontWeight: '600', marginBottom: 12 },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 12,
  },
  row: {
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#ddd',
  },
  primary: { fontSize: 16 },
  secondary: { fontSize: 13, color: '#666', marginTop: 2 },
  distance: { fontSize: 11, color: '#999', marginTop: 2 },
  bold: { fontWeight: '700' },
  detail: { flex: 1 },
  detailTitle: { fontSize: 20, fontWeight: '600', marginBottom: 8 },
  detailLine: { fontSize: 15, marginVertical: 4 },
  back: { paddingVertical: 8 },
  backText: { fontSize: 15, color: '#0066cc' },
  error: { color: 'red', marginVertical: 8 },
  hint: { color: '#666', marginTop: 8 },
  busyOverlay: {
    position: 'absolute',
    top: 0, left: 0, right: 0, bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.4)',
  },
});
