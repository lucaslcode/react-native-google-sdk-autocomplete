#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlacesFieldMapper : NSObject

// Returns an array of GMSPlaceProperty constants for the given JS field names.
// Throws NSException with name "InvalidRequest" if any field is unknown.
+ (NSArray<NSString *> *)toSdkProperties:(NSArray<NSString *> *)jsFields;

@end

NS_ASSUME_NONNULL_END
