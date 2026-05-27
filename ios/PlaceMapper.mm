#import "PlaceMapper.h"
#import <GooglePlaces/GooglePlaces.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@implementation PlacesPlaceMapper

+ (NSDictionary *)latLngFromCoord:(CLLocationCoordinate2D)c {
  return @{ @"latitude": @(c.latitude), @"longitude": @(c.longitude) };
}

+ (NSNumber *)tribool:(GMSBooleanPlaceAttribute)v {
  switch (v) {
    case GMSBooleanPlaceAttributeTrue: return @YES;
    case GMSBooleanPlaceAttributeFalse: return @NO;
    default: return nil;
  }
}

+ (NSString *)businessStatusName:(GMSPlacesBusinessStatus)s {
  switch (s) {
    case GMSPlacesBusinessStatusOperational: return @"OPERATIONAL";
    case GMSPlacesBusinessStatusClosedTemporarily: return @"CLOSED_TEMPORARILY";
    case GMSPlacesBusinessStatusClosedPermanently: return @"CLOSED_PERMANENTLY";
    default: return nil;
  }
}

+ (NSString *)priceLevelName:(GMSPlacesPriceLevel)p {
  switch (p) {
    case kGMSPlacesPriceLevelFree: return @"FREE";
    case kGMSPlacesPriceLevelCheap: return @"INEXPENSIVE";
    case kGMSPlacesPriceLevelMedium: return @"MODERATE";
    case kGMSPlacesPriceLevelHigh: return @"EXPENSIVE";
    case kGMSPlacesPriceLevelExpensive: return @"VERY_EXPENSIVE";
    default: return @"MODERATE";
  }
}

+ (NSString *)hexFromColor:(UIColor *)color {
  if (color == nil) return nil;
  CGFloat r, g, b, a;
  if (![color getRed:&r green:&g blue:&b alpha:&a]) return nil;
  return [NSString stringWithFormat:@"#%02X%02X%02X",
          (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

+ (NSDictionary *)addressComponentDict:(GMSAddressComponent *)c {
  NSMutableDictionary *m = [NSMutableDictionary new];
  if (c.shortName) m[@"shortName"] = c.shortName;
  if (c.name) m[@"longName"] = c.name;
  m[@"types"] = c.types ?: @[];
  return m;
}

+ (NSDictionary *)plusCodeDict:(GMSPlusCode *)c {
  NSMutableDictionary *m = [NSMutableDictionary new];
  if (c.compoundCode) m[@"compoundCode"] = c.compoundCode;
  if (c.globalCode) m[@"globalCode"] = c.globalCode;
  return m;
}

+ (NSDictionary *)timeOfWeekDict:(GMSEvent *)t {
  return @{
    @"day": @(t.day),
    @"hour": @(t.time.hour),
    @"minute": @(t.time.minute),
  };
}

+ (NSDictionary *)openingHoursDict:(GMSOpeningHours *)h {
  NSMutableArray *periods = [NSMutableArray new];
  for (GMSPeriod *p in h.periods) {
    NSMutableDictionary *pm = [NSMutableDictionary new];
    if (p.openEvent) pm[@"open"] = [self timeOfWeekDict:p.openEvent];
    if (p.closeEvent) pm[@"close"] = [self timeOfWeekDict:p.closeEvent];
    [periods addObject:pm];
  }
  return @{
    @"periods": periods,
    @"weekdayText": h.weekdayText ?: @[],
  };
}

+ (NSDictionary *)reviewDict:(GMSPlaceReview *)r {
  NSMutableDictionary *m = [NSMutableDictionary new];
  if (r.text) m[@"text"] = r.text;
  if (r.originalText) m[@"originalText"] = r.originalText;
  m[@"rating"] = @(r.rating);
  if (r.authorAttribution) {
    NSMutableDictionary *aa = [NSMutableDictionary new];
    if (r.authorAttribution.name) aa[@"displayName"] = r.authorAttribution.name;
    if (r.authorAttribution.URI) aa[@"uri"] = r.authorAttribution.URI.absoluteString;
    if (r.authorAttribution.photoURI) aa[@"photoUri"] = r.authorAttribution.photoURI.absoluteString;
    m[@"authorAttribution"] = aa;
  }
  return m;
}

+ (void)addBool:(NSMutableDictionary *)m
            key:(NSString *)key
       requested:(NSSet *)requested
          value:(GMSBooleanPlaceAttribute)v {
  if (![requested containsObject:key]) return;
  NSNumber *n = [self tribool:v];
  if (n != nil) m[key] = n;
}

+ (NSDictionary *)toDict:(GMSPlace *)place requested:(NSSet<NSString *> *)requested {
  NSMutableDictionary *m = [NSMutableDictionary new];
  #define HAS(k) [requested containsObject:k]
  #define PUT_IF(k, v) do { if (HAS(k) && (v) != nil) m[k] = (v); } while (0)

  PUT_IF(@"id", place.placeID);
  PUT_IF(@"displayName", place.name);
  PUT_IF(@"formattedAddress", place.formattedAddress);

  if (HAS(@"addressComponents") && place.addressComponents) {
    NSMutableArray *arr = [NSMutableArray new];
    for (GMSAddressComponent *c in place.addressComponents) {
      [arr addObject:[self addressComponentDict:c]];
    }
    m[@"addressComponents"] = arr;
  }
  if (HAS(@"location") && CLLocationCoordinate2DIsValid(place.coordinate)) {
    m[@"location"] = [self latLngFromCoord:place.coordinate];
  }
  if (HAS(@"viewport") && place.viewportInfo) {
    m[@"viewport"] = @{
      @"northEast": [self latLngFromCoord:place.viewportInfo.northEast],
      @"southWest": [self latLngFromCoord:place.viewportInfo.southWest],
    };
  }
  if (HAS(@"plusCode") && place.plusCode) {
    m[@"plusCode"] = [self plusCodeDict:place.plusCode];
  }
  if (HAS(@"types") && place.types) {
    m[@"types"] = place.types;
  }
  if (HAS(@"businessStatus")) {
    NSString *s = [self businessStatusName:place.businessStatus];
    if (s != nil) m[@"businessStatus"] = s;
  }
  if (HAS(@"rating") && place.rating > 0) m[@"rating"] = @(place.rating);
  if (HAS(@"userRatingCount")) m[@"userRatingCount"] = @(place.userRatingsTotal);
  if (HAS(@"priceLevel") && place.priceLevel != kGMSPlacesPriceLevelUnknown) {
    m[@"priceLevel"] = [self priceLevelName:place.priceLevel];
  }
  if (HAS(@"websiteUri") && place.website) m[@"websiteUri"] = place.website.absoluteString;
  if (HAS(@"googleMapsUri") && place.googleMapsLinks.placeURL) {
    m[@"googleMapsUri"] = place.googleMapsLinks.placeURL.absoluteString;
  }
  if (HAS(@"iconMaskUrl") && place.iconImageURL) m[@"iconMaskUrl"] = place.iconImageURL.absoluteString;
  if (HAS(@"iconBackgroundColor")) {
    NSString *hex = [self hexFromColor:place.iconBackgroundColor];
    if (hex) m[@"iconBackgroundColor"] = hex;
  }
  // GooglePlaces iOS exposes a single phone number in international format.
  PUT_IF(@"internationalPhoneNumber", place.phoneNumber);
  if (HAS(@"utcOffsetMinutes") && place.UTCOffsetMinutes) {
    m[@"utcOffsetMinutes"] = place.UTCOffsetMinutes;
  }
  if (HAS(@"openingHours") && place.openingHours) {
    m[@"openingHours"] = [self openingHoursDict:place.openingHours];
  }
  if (HAS(@"currentOpeningHours") && place.currentOpeningHours) {
    m[@"currentOpeningHours"] = [self openingHoursDict:place.currentOpeningHours];
  }
  if (HAS(@"secondaryOpeningHours") && place.secondaryOpeningHours) {
    NSMutableArray *arr = [NSMutableArray new];
    for (GMSOpeningHours *h in place.secondaryOpeningHours) {
      [arr addObject:[self openingHoursDict:h]];
    }
    m[@"secondaryOpeningHours"] = arr;
  }
  PUT_IF(@"editorialSummary", place.editorialSummary);
  if (HAS(@"reviews") && place.reviews) {
    NSMutableArray *arr = [NSMutableArray new];
    for (GMSPlaceReview *r in place.reviews) [arr addObject:[self reviewDict:r]];
    m[@"reviews"] = arr;
  }
  if (HAS(@"accessibilityOptions") && place.accessibilityOptions) {
    NSMutableDictionary *ao = [NSMutableDictionary new];
    NSNumber *p = [self tribool:place.accessibilityOptions.wheelchairAccessibleParking];
    if (p) ao[@"wheelchairAccessibleParking"] = p;
    NSNumber *e = [self tribool:place.accessibilityOptions.wheelchairAccessibleEntrance];
    if (e) ao[@"wheelchairAccessibleEntrance"] = e;
    NSNumber *r = [self tribool:place.accessibilityOptions.wheelchairAccessibleRestroom];
    if (r) ao[@"wheelchairAccessibleRestroom"] = r;
    NSNumber *s = [self tribool:place.accessibilityOptions.wheelchairAccessibleSeating];
    if (s) ao[@"wheelchairAccessibleSeating"] = s;
    m[@"accessibilityOptions"] = ao;
  }

  [self addBool:m key:@"allowsDogs" requested:requested value:place.allowsDogs];
  [self addBool:m key:@"curbsidePickup" requested:requested value:place.curbsidePickup];
  [self addBool:m key:@"delivery" requested:requested value:place.delivery];
  [self addBool:m key:@"dineIn" requested:requested value:place.dineIn];
  [self addBool:m key:@"takeout" requested:requested value:place.takeout];
  [self addBool:m key:@"goodForChildren" requested:requested value:place.goodForChildren];
  [self addBool:m key:@"goodForGroups" requested:requested value:place.goodForGroups];
  [self addBool:m key:@"goodForWatchingSports" requested:requested value:place.goodForWatchingSports];
  [self addBool:m key:@"liveMusic" requested:requested value:place.liveMusic];
  [self addBool:m key:@"menuForChildren" requested:requested value:place.menuForChildren];
  [self addBool:m key:@"outdoorSeating" requested:requested value:place.outdoorSeating];
  [self addBool:m key:@"reservable" requested:requested value:place.reservable];
  [self addBool:m key:@"restroom" requested:requested value:place.restroom];
  [self addBool:m key:@"servesBeer" requested:requested value:place.servesBeer];
  [self addBool:m key:@"servesWine" requested:requested value:place.servesWine];
  [self addBool:m key:@"servesCoffee" requested:requested value:place.servesCoffee];
  [self addBool:m key:@"servesBreakfast" requested:requested value:place.servesBreakfast];
  [self addBool:m key:@"servesLunch" requested:requested value:place.servesLunch];
  [self addBool:m key:@"servesDinner" requested:requested value:place.servesDinner];
  [self addBool:m key:@"servesBrunch" requested:requested value:place.servesBrunch];
  [self addBool:m key:@"servesDessert" requested:requested value:place.servesDessert];
  [self addBool:m key:@"servesVegetarianFood" requested:requested value:place.servesVegetarianFood];

  if (HAS(@"parkingOptions") && place.parkingOptions) {
    NSMutableDictionary *po = [NSMutableDictionary new];
    NSNumber *v;
    if ((v = [self tribool:place.parkingOptions.freeParkingLot])) po[@"freeParkingLot"] = v;
    if ((v = [self tribool:place.parkingOptions.paidParkingLot])) po[@"paidParkingLot"] = v;
    if ((v = [self tribool:place.parkingOptions.freeStreetParking])) po[@"freeStreetParking"] = v;
    if ((v = [self tribool:place.parkingOptions.paidStreetParking])) po[@"paidStreetParking"] = v;
    if ((v = [self tribool:place.parkingOptions.valetParking])) po[@"valetParking"] = v;
    if ((v = [self tribool:place.parkingOptions.freeGarageParking])) po[@"freeGarageParking"] = v;
    if ((v = [self tribool:place.parkingOptions.paidGarageParking])) po[@"paidGarageParking"] = v;
    m[@"parkingOptions"] = po;
  }
  if (HAS(@"paymentOptions") && place.paymentOptions) {
    NSMutableDictionary *pm = [NSMutableDictionary new];
    NSNumber *v;
    if ((v = [self tribool:place.paymentOptions.acceptsCreditCards])) pm[@"acceptsCreditCards"] = v;
    if ((v = [self tribool:place.paymentOptions.acceptsDebitCards])) pm[@"acceptsDebitCards"] = v;
    if ((v = [self tribool:place.paymentOptions.acceptsCashOnly])) pm[@"acceptsCashOnly"] = v;
    if ((v = [self tribool:place.paymentOptions.acceptsNFC])) pm[@"acceptsNfc"] = v;
    m[@"paymentOptions"] = pm;
  }
  if (HAS(@"fuelOptions") && place.fuelOptions) {
    NSMutableArray *prices = [NSMutableArray new];
    for (GMSPlaceFuelPrice *p in place.fuelOptions.fuelPrices) {
      NSMutableDictionary *pd = [NSMutableDictionary new];
      pd[@"type"] = @(p.type).stringValue;
      if (p.price) {
        if (p.price.currencyCode) pd[@"currencyCode"] = p.price.currencyCode;
        pd[@"priceUnits"] = [@(p.price.units) stringValue];
        pd[@"priceNanos"] = @(p.price.nanos);
      }
      if (p.lastUpdateTime) pd[@"updateTime"] = @(p.lastUpdateTime.timeIntervalSince1970 * 1000);
      [prices addObject:pd];
    }
    m[@"fuelOptions"] = @{ @"fuelPrices": prices };
  }
  if (HAS(@"evChargeOptions") && place.evChargeOptions) {
    NSMutableDictionary *ev = [NSMutableDictionary new];
    ev[@"connectorCount"] = @(place.evChargeOptions.connectorCount);
    NSMutableArray *aggs = [NSMutableArray new];
    for (GMSPlaceConnectorAggregation *a in place.evChargeOptions.connectorAggregations) {
      NSMutableDictionary *am = [NSMutableDictionary new];
      am[@"type"] = @(a.type).stringValue;
      am[@"maxChargeRateKw"] = @(a.maxChargeRateKW);
      am[@"count"] = @(a.count);
      am[@"availableCount"] = @(a.availableCount);
      am[@"outOfServiceCount"] = @(a.outOfServiceCount);
      [aggs addObject:am];
    }
    ev[@"connectorAggregations"] = aggs;
    m[@"evChargeOptions"] = ev;
  }

  #undef HAS
  #undef PUT_IF
  return m;
}

@end
