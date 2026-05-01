#import "SessionTokenStore.h"
#import <GooglePlaces/GooglePlaces.h>

@implementation PlacesSessionTokenStore {
  NSMutableDictionary<NSString *, GMSAutocompleteSessionToken *> *_tokens;
  dispatch_queue_t _queue;
}

- (instancetype)init {
  if (self = [super init]) {
    _tokens = [NSMutableDictionary new];
    _queue = dispatch_queue_create("com.googlesdkautocomplete.sessiontokens",
                                    DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (NSString *)create {
  NSString *tokenId = [[NSUUID UUID] UUIDString];
  GMSAutocompleteSessionToken *tok = [[GMSAutocompleteSessionToken alloc] init];
  dispatch_barrier_sync(_queue, ^{
    self->_tokens[tokenId] = tok;
  });
  return tokenId;
}

- (GMSAutocompleteSessionToken *)get:(NSString *)tokenId {
  if (tokenId == nil) return nil;
  __block GMSAutocompleteSessionToken *result = nil;
  dispatch_sync(_queue, ^{
    result = self->_tokens[tokenId];
  });
  return result;
}

- (void)clear:(NSString *)tokenId {
  if (tokenId == nil) return;
  dispatch_barrier_async(_queue, ^{
    [self->_tokens removeObjectForKey:tokenId];
  });
}

@end
