
#import <Foundation/Foundation.h>
#import "AMAReporter.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAReporter (TestUtilities)

- (instancetype)initWithApiKey:(NSString *)apiKey
                          main:(BOOL)main
               reporterStorage:(AMAReporterStorage *)reporterStorage
                  eventBuilder:(AMAEventBuilder *)eventBuilder
              internalReporter:(AMAInternalEventsReporter *)internalReporter
      attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor
                  privacyTimer:(AMAPrivacyTimer *)privacyTimer;

@end

NS_ASSUME_NONNULL_END
