#import <Foundation/Foundation.h>

@class AMAScreenshotStartupResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AMAScreenshotStartupParser : NSObject

+ (AMAScreenshotStartupResponse *)parse:(NSDictionary*)startupDictionary;

@end

NS_ASSUME_NONNULL_END
