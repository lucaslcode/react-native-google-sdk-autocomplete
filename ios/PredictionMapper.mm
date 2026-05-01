#import "PredictionMapper.h"
#import <GooglePlaces/GooglePlaces.h>

@implementation PlacesPredictionMapper

+ (NSDictionary *)attributedTextDict:(NSAttributedString *)attr {
  NSString *text = attr.string ?: @"";
  NSMutableArray<NSDictionary *> *matches = [NSMutableArray new];
  NSRange full = NSMakeRange(0, attr.length);
  [attr enumerateAttribute:kGMSAutocompleteMatchAttribute
                   inRange:full
                   options:0
                usingBlock:^(id value, NSRange range, BOOL *stop) {
    if (value != nil && range.length > 0) {
      [matches addObject:@{
        @"offset": @(range.location),
        @"length": @(range.length),
      }];
    }
  }];
  return @{
    @"text": text,
    @"matches": matches,
  };
}

+ (NSDictionary *)dictForSuggestion:(GMSAutocompleteSuggestion *)suggestion {
  GMSAutocompletePlaceSuggestion *place = suggestion.placeSuggestion;
  if (place == nil) return nil;

  NSMutableDictionary *m = [NSMutableDictionary new];
  m[@"placeId"] = place.placeID ?: @"";
  m[@"fullText"] = [self attributedTextDict:place.attributedFullText];
  m[@"primaryText"] = [self attributedTextDict:place.attributedPrimaryText];
  m[@"secondaryText"] = [self attributedTextDict:place.attributedSecondaryText];

  NSMutableArray<NSString *> *types = [NSMutableArray new];
  for (NSString *t in place.types) [types addObject:t];
  m[@"types"] = types;

  if (place.distanceMeters != nil) {
    m[@"distanceMeters"] = place.distanceMeters;
  }
  return m;
}

+ (NSArray<NSDictionary *> *)toArray:(NSArray<GMSAutocompleteSuggestion *> *)suggestions {
  NSMutableArray<NSDictionary *> *out = [NSMutableArray new];
  for (GMSAutocompleteSuggestion *s in suggestions) {
    NSDictionary *d = [self dictForSuggestion:s];
    if (d != nil) [out addObject:d];
  }
  return out;
}

@end
