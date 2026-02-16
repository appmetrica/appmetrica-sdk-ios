
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

@interface AMACrashEventConverter : NSObject

- (nullable AMADecodedCrash *)decodedCrashFromCrashEvent:(nullable AMACrashEvent *)event;

- (nullable AMACrashEvent *)crashEventFromDecodedCrash:(nullable AMADecodedCrash *)decodedCrash;

@end

NS_ASSUME_NONNULL_END
