#import "FieldMapper.h"
#import <GooglePlaces/GooglePlaces.h>

@implementation PlacesFieldMapper

+ (NSDictionary<NSString *, NSString *> *)mapping {
  static NSDictionary<NSString *, NSString *> *map;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    map = @{
      @"id": GMSPlacePropertyPlaceID,
      @"addressComponents": GMSPlacePropertyAddressComponents,
      @"formattedAddress": GMSPlacePropertyFormattedAddress,
      @"location": GMSPlacePropertyCoordinate,
      @"plusCode": GMSPlacePropertyPlusCode,
      @"types": GMSPlacePropertyTypes,
      @"viewport": GMSPlacePropertyViewport,
      @"businessStatus": GMSPlacePropertyBusinessStatus,
      @"displayName": GMSPlacePropertyName,
      @"googleMapsUri": GMSPlacePropertyGoogleMapsLinks,
      @"iconBackgroundColor": GMSPlacePropertyIconBackgroundColor,
      @"iconMaskUrl": GMSPlacePropertyIconImageURL,
      @"utcOffsetMinutes": GMSPlacePropertyUTCOffsetMinutes,
      @"currentOpeningHours": GMSPlacePropertyCurrentOpeningHours,
      // GooglePlaces iOS exposes a single phone number in international format.
      @"internationalPhoneNumber": GMSPlacePropertyPhoneNumber,
      @"openingHours": GMSPlacePropertyOpeningHours,
      @"secondaryOpeningHours": GMSPlacePropertySecondaryOpeningHours,
      @"priceLevel": GMSPlacePropertyPriceLevel,
      @"rating": GMSPlacePropertyRating,
      @"userRatingCount": GMSPlacePropertyUserRatingsTotal,
      @"websiteUri": GMSPlacePropertyWebsite,
      @"allowsDogs": GMSPlacePropertyAllowsDogs,
      @"curbsidePickup": GMSPlacePropertyCurbsidePickup,
      @"delivery": GMSPlacePropertyDelivery,
      @"dineIn": GMSPlacePropertyDineIn,
      @"takeout": GMSPlacePropertyTakeout,
      @"editorialSummary": GMSPlacePropertyEditorialSummary,
      @"evChargeOptions": GMSPlacePropertyEVChargeOptions,
      @"fuelOptions": GMSPlacePropertyFuelOptions,
      @"goodForChildren": GMSPlacePropertyGoodForChildren,
      @"goodForGroups": GMSPlacePropertyGoodForGroups,
      @"goodForWatchingSports": GMSPlacePropertyGoodForWatchingSports,
      @"liveMusic": GMSPlacePropertyLiveMusic,
      @"menuForChildren": GMSPlacePropertyMenuForChildren,
      @"outdoorSeating": GMSPlacePropertyOutdoorSeating,
      @"parkingOptions": GMSPlacePropertyParkingOptions,
      @"paymentOptions": GMSPlacePropertyPaymentOptions,
      @"reservable": GMSPlacePropertyReservable,
      @"restroom": GMSPlacePropertyRestroom,
      @"reviews": GMSPlacePropertyReviews,
      @"accessibilityOptions": GMSPlacePropertyAccessibilityOptions,
      @"servesBeer": GMSPlacePropertyServesBeer,
      @"servesWine": GMSPlacePropertyServesWine,
      @"servesCoffee": GMSPlacePropertyServesCoffee,
      @"servesBreakfast": GMSPlacePropertyServesBreakfast,
      @"servesLunch": GMSPlacePropertyServesLunch,
      @"servesDinner": GMSPlacePropertyServesDinner,
      @"servesBrunch": GMSPlacePropertyServesBrunch,
      @"servesDessert": GMSPlacePropertyServesDessert,
      @"servesVegetarianFood": GMSPlacePropertyServesVegetarianFood,
    };
  });
  return map;
}

+ (NSArray<NSString *> *)toSdkProperties:(NSArray<NSString *> *)jsFields {
  NSDictionary *map = [self mapping];
  NSMutableArray<NSString *> *out = [NSMutableArray arrayWithCapacity:jsFields.count];
  NSMutableArray<NSString *> *unknown = [NSMutableArray new];
  for (NSString *f in jsFields) {
    NSString *prop = map[f];
    if (prop == nil) {
      [unknown addObject:f];
    } else {
      [out addObject:prop];
    }
  }
  if (unknown.count > 0) {
    @throw [NSException exceptionWithName:@"InvalidRequest"
      reason:[NSString stringWithFormat:@"Unknown PlaceField(s): %@",
              [unknown componentsJoinedByString:@", "]]
      userInfo:nil];
  }
  return out;
}

@end
