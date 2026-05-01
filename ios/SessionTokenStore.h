#import <Foundation/Foundation.h>

@class GMSAutocompleteSessionToken;

NS_ASSUME_NONNULL_BEGIN

@interface PlacesSessionTokenStore : NSObject

- (NSString *)create;
- (nullable GMSAutocompleteSessionToken *)get:(nullable NSString *)tokenId;
- (void)clear:(NSString *)tokenId;

@end

NS_ASSUME_NONNULL_END
