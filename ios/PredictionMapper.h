#import <Foundation/Foundation.h>

@class GMSAutocompleteSuggestion;

NS_ASSUME_NONNULL_BEGIN

@interface PlacesPredictionMapper : NSObject

+ (NSArray<NSDictionary *> *)toArray:(NSArray<GMSAutocompleteSuggestion *> *)suggestions;

@end

NS_ASSUME_NONNULL_END
