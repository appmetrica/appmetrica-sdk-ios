
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@class AMADecodedCrashValidator;
@class AMAInternalEventsReporter;

@interface AMADecodedCrashSerializer : NSObject

- (instancetype)initWithReporter:(AMAInternalEventsReporter *)reporter;

- (NSData *)dataForCrash:(AMADecodedCrash *)decodedCrash;

@end

