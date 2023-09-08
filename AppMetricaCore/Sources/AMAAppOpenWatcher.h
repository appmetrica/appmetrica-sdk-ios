
#import <Foundation/Foundation.h>
#import "AMAStartupCompletionObserving.h"

@class AMAStartupParametersConfiguration;
@class AMAReporter;
@protocol AMAExecuting;
@class AMADeepLinkController;

@interface AMAAppOpenWatcher : NSObject

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)center;
- (void)startWatchingWithDeeplinkController:(AMADeepLinkController *)controller;

@end
