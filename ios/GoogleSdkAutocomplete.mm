#import "GoogleSdkAutocomplete.h"
#import "SessionTokenStore.h"
#import "FieldMapper.h"
#import "PredictionMapper.h"
#import "PlaceMapper.h"

#import <GooglePlaces/GooglePlaces.h>
#import <CoreLocation/CoreLocation.h>

@implementation GoogleSdkAutocomplete {
  PlacesSessionTokenStore *_tokens;
  NSString *_initializedKey;
}

- (instancetype)init {
  if (self = [super init]) {
    _tokens = [PlacesSessionTokenStore new];
  }
  return self;
}

// ---- spec methods ----

- (void)initialize:(NSString *)apiKey
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
  @synchronized (self) {
    if (apiKey == nil || apiKey.length == 0) {
      reject(@"INVALID_REQUEST", @"apiKey is required", nil);
      return;
    }
    if (_initializedKey == nil) {
      [GMSPlacesClient provideAPIKey:apiKey];
      _initializedKey = [apiKey copy];
    } else if (![_initializedKey isEqualToString:apiKey]) {
      reject(@"INVALID_REQUEST",
             @"Places already initialized with a different API key", nil);
      return;
    }
    resolve(nil);
  }
}

- (void)createSessionToken:(RCTPromiseResolveBlock)resolve
                    reject:(RCTPromiseRejectBlock)reject {
  if (![self requireInitialized:reject]) return;
  resolve([_tokens create]);
}

- (void)clearSessionToken:(NSString *)token
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject {
  [_tokens clear:token];
  resolve(nil);
}

- (void)findAutocompletePredictions:(NSDictionary *)request
                            resolve:(RCTPromiseResolveBlock)resolve
                             reject:(RCTPromiseRejectBlock)reject {
  if (![self requireInitialized:reject]) return;

  NSString *query = request[@"query"];
  if (![query isKindOfClass:NSString.class] || query.length == 0) {
    reject(@"INVALID_REQUEST", @"query is required", nil);
    return;
  }

  GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];

  NSArray *types = request[@"types"];
  if ([types isKindOfClass:NSArray.class]) filter.types = types;

  NSArray *countries = request[@"countries"];
  if ([countries isKindOfClass:NSArray.class]) filter.countries = countries;

  NSDictionary *bias = request[@"locationBias"];
  if ([bias isKindOfClass:NSDictionary.class]) {
    filter.locationBias = [self locationOptionFromDict:bias error:reject];
    if (filter.locationBias == nil) return;
  }
  NSDictionary *restriction = request[@"locationRestriction"];
  if ([restriction isKindOfClass:NSDictionary.class]) {
    filter.locationRestriction = [self locationOptionFromDict:restriction error:reject];
    if (filter.locationRestriction == nil) return;
  }
  NSDictionary *origin = request[@"origin"];
  if ([origin isKindOfClass:NSDictionary.class]) {
    filter.origin = [[CLLocation alloc]
      initWithLatitude:[origin[@"latitude"] doubleValue]
             longitude:[origin[@"longitude"] doubleValue]];
  }
  NSString *regionCode = request[@"regionCode"];
  if ([regionCode isKindOfClass:NSString.class]) filter.regionCode = regionCode;

  NSNumber *inputOffset = request[@"inputOffset"];
  if ([inputOffset isKindOfClass:NSNumber.class]) {
    filter.inputOffset = inputOffset.unsignedIntegerValue;
  }

  GMSAutocompleteRequest *autoReq = [[GMSAutocompleteRequest alloc] initWithQuery:query];
  autoReq.filter = filter;

  NSString *sessionTokenId = request[@"sessionToken"];
  if ([sessionTokenId isKindOfClass:NSString.class]) {
    GMSAutocompleteSessionToken *tok = [_tokens get:sessionTokenId];
    if (tok == nil) {
      reject(@"UNKNOWN_SESSION_TOKEN",
             [NSString stringWithFormat:@"Unknown session token: %@", sessionTokenId],
             nil);
      return;
    }
    autoReq.sessionToken = tok;
  }

  [[GMSPlacesClient sharedClient]
    fetchAutocompleteSuggestionsFromRequest:autoReq
                                   callback:^(NSArray<GMSAutocompleteSuggestion *> *suggestions,
                                              NSError *error) {
    if (error != nil) {
      reject([self codeForError:error], error.localizedDescription, error);
      return;
    }
    resolve([PlacesPredictionMapper toArray:suggestions ?: @[]]);
  }];
}

- (void)fetchPlace:(NSDictionary *)request
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
  if (![self requireInitialized:reject]) return;

  NSString *placeId = request[@"placeId"];
  if (![placeId isKindOfClass:NSString.class] || placeId.length == 0) {
    reject(@"INVALID_REQUEST", @"placeId is required", nil);
    return;
  }
  NSArray<NSString *> *jsFields = request[@"fields"];
  if (![jsFields isKindOfClass:NSArray.class] || jsFields.count == 0) {
    reject(@"INVALID_REQUEST", @"fields must contain at least one field", nil);
    return;
  }
  NSArray<NSString *> *sdkProps;
  @try {
    sdkProps = [PlacesFieldMapper toSdkProperties:jsFields];
  } @catch (NSException *e) {
    reject(@"INVALID_REQUEST", e.reason, nil);
    return;
  }
  NSSet *requested = [NSSet setWithArray:jsFields];

  NSString *sessionTokenId = request[@"sessionToken"];
  GMSAutocompleteSessionToken *tok = nil;
  if ([sessionTokenId isKindOfClass:NSString.class]) {
    tok = [_tokens get:sessionTokenId];
    if (tok == nil) {
      reject(@"UNKNOWN_SESSION_TOKEN",
             [NSString stringWithFormat:@"Unknown session token: %@", sessionTokenId],
             nil);
      return;
    }
  }

  GMSFetchPlaceRequest *req = [[GMSFetchPlaceRequest alloc]
    initWithPlaceID:placeId placeProperties:sdkProps sessionToken:tok];

  NSString *regionCode = request[@"regionCode"];
  if ([regionCode isKindOfClass:NSString.class]) req.regionCode = regionCode;

  __weak typeof(self) weakSelf = self;
  [[GMSPlacesClient sharedClient]
    fetchPlaceWithRequest:req
                 callback:^(GMSPlace *place, NSError *error) {
    if (error != nil) {
      reject([weakSelf codeForError:error], error.localizedDescription, error);
      return;
    }
    if (place == nil) {
      reject(@"API_ERROR", @"Place not found", nil);
      return;
    }
    if (sessionTokenId != nil) [weakSelf->_tokens clear:sessionTokenId];
    resolve([PlacesPlaceMapper toDict:place requested:requested]);
  }];
}

// ---- helpers ----

- (BOOL)requireInitialized:(RCTPromiseRejectBlock)reject {
  if (_initializedKey == nil) {
    reject(@"NOT_INITIALIZED",
           @"Places.initialize(apiKey) must be called first", nil);
    return NO;
  }
  return YES;
}

- (id<GMSPlaceLocationOption>)locationOptionFromDict:(NSDictionary *)dict
                                                error:(RCTPromiseRejectBlock)reject {
  NSString *type = dict[@"type"];
  if ([@"circle" isEqualToString:type]) {
    NSDictionary *center = dict[@"center"];
    if (![center isKindOfClass:NSDictionary.class]) {
      reject(@"INVALID_REQUEST", @"circle.center is required", nil);
      return nil;
    }
    CLLocationCoordinate2D coord =
      CLLocationCoordinate2DMake([center[@"latitude"] doubleValue],
                                  [center[@"longitude"] doubleValue]);
    double radius = [dict[@"radiusMeters"] doubleValue];
    return GMSPlaceCircularLocationOption(coord, radius);
  }
  if ([@"rectangle" isEqualToString:type]) {
    NSDictionary *ne = dict[@"northEast"];
    NSDictionary *sw = dict[@"southWest"];
    if (![ne isKindOfClass:NSDictionary.class] || ![sw isKindOfClass:NSDictionary.class]) {
      reject(@"INVALID_REQUEST", @"rectangle requires northEast and southWest", nil);
      return nil;
    }
    CLLocationCoordinate2D neC =
      CLLocationCoordinate2DMake([ne[@"latitude"] doubleValue], [ne[@"longitude"] doubleValue]);
    CLLocationCoordinate2D swC =
      CLLocationCoordinate2DMake([sw[@"latitude"] doubleValue], [sw[@"longitude"] doubleValue]);
    return GMSPlaceRectangularLocationOption(neC, swC);
  }
  reject(@"INVALID_REQUEST",
         [NSString stringWithFormat:@"Unknown location type: %@", type], nil);
  return nil;
}

- (NSString *)codeForError:(NSError *)error {
  if (error == nil) return @"UNKNOWN";
  if ([error.domain isEqualToString:NSURLErrorDomain]) return @"NETWORK_ERROR";
  if ([error.domain isEqualToString:kGMSPlacesErrorDomain]) return @"API_ERROR";
  return @"UNKNOWN";
}

// ---- TurboModule plumbing ----

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeGoogleSdkAutocompleteSpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"GoogleSdkAutocomplete";
}

@end
