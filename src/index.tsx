import NativePlaces from './NativeGoogleSdkAutocomplete';
import type {
  AutocompletePrediction,
  AutocompleteRequest,
  FetchPlaceRequest,
  LocationArea,
  Place,
  PlacesErrorCode,
} from './types';

export * from './types';

export class PlacesError extends Error {
  code: PlacesErrorCode;
  nativeMessage?: string;

  constructor(code: PlacesErrorCode, message: string, nativeMessage?: string) {
    super(message);
    this.name = 'PlacesError';
    this.code = code;
    this.nativeMessage = nativeMessage;
  }
}

function flattenLocation(area: LocationArea) {
  if (area.type === 'circle') {
    return {
      type: 'circle',
      center: area.center,
      radiusMeters: area.radiusMeters,
    };
  }
  return {
    type: 'rectangle',
    northEast: area.northEast,
    southWest: area.southWest,
  };
}

function rejectInvalid(message: string): never {
  throw new PlacesError('INVALID_REQUEST', message);
}

async function initialize(apiKey: string): Promise<void> {
  if (!apiKey || typeof apiKey !== 'string') {
    rejectInvalid('initialize() requires a non-empty apiKey string');
  }
  await NativePlaces.initialize(apiKey);
}

async function createSessionToken(): Promise<string> {
  return NativePlaces.createSessionToken();
}

async function clearSessionToken(token: string): Promise<void> {
  if (!token) rejectInvalid('clearSessionToken() requires a token');
  await NativePlaces.clearSessionToken(token);
}

async function findAutocompletePredictions(
  request: AutocompleteRequest
): Promise<AutocompletePrediction[]> {
  if (!request?.query || typeof request.query !== 'string') {
    rejectInvalid('findAutocompletePredictions: query is required');
  }
  if (request.types && request.types.length > 5) {
    rejectInvalid('findAutocompletePredictions: at most 5 types allowed');
  }
  if (request.countries && request.countries.length > 15) {
    rejectInvalid('findAutocompletePredictions: at most 15 countries allowed');
  }
  if (request.locationBias && request.locationRestriction) {
    rejectInvalid(
      'findAutocompletePredictions: locationBias and locationRestriction are mutually exclusive'
    );
  }
  if (
    request.inputOffset !== undefined &&
    (request.inputOffset < 0 || !Number.isInteger(request.inputOffset))
  ) {
    rejectInvalid(
      'findAutocompletePredictions: inputOffset must be a non-negative integer'
    );
  }

  const result = await NativePlaces.findAutocompletePredictions({
    query: request.query,
    sessionToken: request.sessionToken,
    types: request.types,
    countries: request.countries,
    locationBias: request.locationBias
      ? flattenLocation(request.locationBias)
      : undefined,
    locationRestriction: request.locationRestriction
      ? flattenLocation(request.locationRestriction)
      : undefined,
    origin: request.origin,
    regionCode: request.regionCode,
    inputOffset: request.inputOffset,
  });
  return result as AutocompletePrediction[];
}

async function fetchPlace(request: FetchPlaceRequest): Promise<Place> {
  if (!request?.placeId) {
    rejectInvalid('fetchPlace: placeId is required');
  }
  if (!request.fields || request.fields.length === 0) {
    rejectInvalid('fetchPlace: fields must contain at least one PlaceField');
  }
  const result = await NativePlaces.fetchPlace({
    placeId: request.placeId,
    fields: request.fields,
    sessionToken: request.sessionToken,
  });
  return result as Place;
}

export const Places = {
  initialize,
  createSessionToken,
  clearSessionToken,
  findAutocompletePredictions,
  fetchPlace,
};

export default Places;
