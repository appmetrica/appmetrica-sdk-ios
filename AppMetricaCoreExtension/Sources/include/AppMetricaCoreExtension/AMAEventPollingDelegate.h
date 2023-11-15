#import <Foundation/Foundation.h>

NS_SWIFT_NAME(EventFlushableDelegate)
@protocol AMAEventPollingDelegate <NSObject>

+ (NSArray<AMACustomEventParameters *> *)eventsForPreviousSession;

@end
