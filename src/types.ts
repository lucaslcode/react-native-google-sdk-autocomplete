export type LatLng = {
  latitude: number;
  longitude: number;
};

export type LocationArea =
  | { type: 'circle'; center: LatLng; radiusMeters: number }
  | { type: 'rectangle'; northEast: LatLng; southWest: LatLng };

export type AutocompleteRequest = {
  query: string;
  sessionToken?: string;
  types?: string[];
  countries?: string[];
  locationBias?: LocationArea;
  locationRestriction?: LocationArea;
  origin?: LatLng;
  regionCode?: string;
  inputOffset?: number;
};

export type SubstringMatch = {
  offset: number;
  length: number;
};

export type AttributedText = {
  text: string;
  matches: SubstringMatch[];
};

export type AutocompletePrediction = {
  placeId: string;
  fullText: AttributedText;
  primaryText: AttributedText;
  secondaryText: AttributedText;
  types: string[];
  distanceMeters?: number;
};

export type FetchPlaceRequest = {
  placeId: string;
  fields: PlaceField[];
  sessionToken?: string;
  regionCode?: string;
};

export type AddressComponent = {
  shortName?: string;
  longName?: string;
  types: string[];
};

export type Viewport = {
  northEast: LatLng;
  southWest: LatLng;
};

export type PlusCode = {
  compoundCode?: string;
  globalCode?: string;
};

export type TimeOfWeek = {
  day: number;
  hour: number;
  minute: number;
  date?: { year: number; month: number; day: number };
  truncated?: boolean;
};

export type OpeningHoursPeriod = {
  open?: TimeOfWeek;
  close?: TimeOfWeek;
};

export type OpeningHours = {
  periods?: OpeningHoursPeriod[];
  weekdayText?: string[];
  type?: string;
};

export type AuthorAttribution = {
  displayName?: string;
  uri?: string;
  photoUri?: string;
};

export type Review = {
  text?: string;
  originalText?: string;
  rating?: number;
  publishTime?: number;
  relativePublishTimeDescription?: string;
  authorAttribution?: AuthorAttribution;
};

export type AccessibilityOptions = {
  wheelchairAccessibleParking?: boolean;
  wheelchairAccessibleEntrance?: boolean;
  wheelchairAccessibleRestroom?: boolean;
  wheelchairAccessibleSeating?: boolean;
};

export type ParkingOptions = {
  freeParkingLot?: boolean;
  paidParkingLot?: boolean;
  freeStreetParking?: boolean;
  paidStreetParking?: boolean;
  valetParking?: boolean;
  freeGarageParking?: boolean;
  paidGarageParking?: boolean;
};

export type PaymentOptions = {
  acceptsCreditCards?: boolean;
  acceptsDebitCards?: boolean;
  acceptsCashOnly?: boolean;
  acceptsNfc?: boolean;
};

export type EvConnectorAggregation = {
  type?: string;
  maxChargeRateKw?: number;
  count?: number;
  availableCount?: number;
  outOfServiceCount?: number;
};

export type EvChargeOptions = {
  connectorCount?: number;
  connectorAggregations?: EvConnectorAggregation[];
};

export type FuelPrice = {
  type?: string;
  priceUnits?: string;
  priceNanos?: number;
  currencyCode?: string;
  updateTime?: number;
};

export type FuelOptions = {
  fuelPrices?: FuelPrice[];
};

export type BusinessStatus =
  | 'OPERATIONAL'
  | 'CLOSED_TEMPORARILY'
  | 'CLOSED_PERMANENTLY';

export type PriceLevel =
  | 'FREE'
  | 'INEXPENSIVE'
  | 'MODERATE'
  | 'EXPENSIVE'
  | 'VERY_EXPENSIVE';

export type Place = {
  id?: string;
  displayName?: string;
  formattedAddress?: string;
  shortFormattedAddress?: string;
  addressComponents?: AddressComponent[];
  location?: LatLng;
  viewport?: Viewport;
  plusCode?: PlusCode;
  types?: string[];
  primaryType?: string;
  primaryTypeDisplayName?: string;
  businessStatus?: BusinessStatus;
  rating?: number;
  userRatingCount?: number;
  priceLevel?: PriceLevel;
  websiteUri?: string;
  googleMapsUri?: string;
  iconMaskUrl?: string;
  iconBackgroundColor?: string;
  internationalPhoneNumber?: string;
  nationalPhoneNumber?: string;
  utcOffsetMinutes?: number;
  openingHours?: OpeningHours;
  currentOpeningHours?: OpeningHours;
  secondaryOpeningHours?: OpeningHours[];
  currentSecondaryOpeningHours?: OpeningHours[];
  editorialSummary?: string;
  reviews?: Review[];
  accessibilityOptions?: AccessibilityOptions;
  allowsDogs?: boolean;
  curbsidePickup?: boolean;
  delivery?: boolean;
  dineIn?: boolean;
  takeout?: boolean;
  goodForChildren?: boolean;
  goodForGroups?: boolean;
  goodForWatchingSports?: boolean;
  liveMusic?: boolean;
  menuForChildren?: boolean;
  outdoorSeating?: boolean;
  reservable?: boolean;
  restroom?: boolean;
  servesBeer?: boolean;
  servesWine?: boolean;
  servesCoffee?: boolean;
  servesBreakfast?: boolean;
  servesLunch?: boolean;
  servesDinner?: boolean;
  servesBrunch?: boolean;
  servesDessert?: boolean;
  servesVegetarianFood?: boolean;
  parkingOptions?: ParkingOptions;
  paymentOptions?: PaymentOptions;
  fuelOptions?: FuelOptions;
  evChargeOptions?: EvChargeOptions;
};

export type PlaceField =
  | 'id'
  | 'addressComponents'
  | 'formattedAddress'
  | 'shortFormattedAddress'
  | 'location'
  | 'plusCode'
  | 'types'
  | 'viewport'
  | 'businessStatus'
  | 'displayName'
  | 'googleMapsUri'
  | 'iconBackgroundColor'
  | 'iconMaskUrl'
  | 'primaryType'
  | 'primaryTypeDisplayName'
  | 'utcOffsetMinutes'
  | 'currentOpeningHours'
  | 'currentSecondaryOpeningHours'
  | 'internationalPhoneNumber'
  | 'nationalPhoneNumber'
  | 'openingHours'
  | 'secondaryOpeningHours'
  | 'priceLevel'
  | 'rating'
  | 'userRatingCount'
  | 'websiteUri'
  | 'allowsDogs'
  | 'curbsidePickup'
  | 'delivery'
  | 'dineIn'
  | 'takeout'
  | 'editorialSummary'
  | 'evChargeOptions'
  | 'fuelOptions'
  | 'goodForChildren'
  | 'goodForGroups'
  | 'goodForWatchingSports'
  | 'liveMusic'
  | 'menuForChildren'
  | 'outdoorSeating'
  | 'parkingOptions'
  | 'paymentOptions'
  | 'reservable'
  | 'restroom'
  | 'reviews'
  | 'accessibilityOptions'
  | 'servesBeer'
  | 'servesWine'
  | 'servesCoffee'
  | 'servesBreakfast'
  | 'servesLunch'
  | 'servesDinner'
  | 'servesBrunch'
  | 'servesDessert'
  | 'servesVegetarianFood';

export type PlacesErrorCode =
  | 'NOT_INITIALIZED'
  | 'INVALID_REQUEST'
  | 'UNKNOWN_SESSION_TOKEN'
  | 'NETWORK_ERROR'
  | 'API_ERROR'
  | 'UNKNOWN';
