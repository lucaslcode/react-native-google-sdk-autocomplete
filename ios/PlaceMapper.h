#import <Foundation/Foundation.h>

@class GMSPlace;

NS_ASSUME_NONNULL_BEGIN

@interface PlacesPlaceMapper : NSObject

// Builds a dictionary representing the GMSPlace, emitting only keys whose
// JS field name appears in `requested`.
+ (NSDictionary *)toDict:(GMSPlace *)place requested:(NSSet<NSString *> *)requested;

@end

NS_ASSUME_NONNULL_END
