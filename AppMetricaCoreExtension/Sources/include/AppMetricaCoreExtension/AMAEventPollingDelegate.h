#import <Foundation/Foundation.h>

@protocol AMAEventPollingDelegate <NSObject>

+ (NSArray<AMACustomEventParameters *> *)eventsForPreviousSession;

@end
