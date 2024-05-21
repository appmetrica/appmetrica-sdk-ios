
#import "AMAReporter+TestUtilities.h"
#import "AMAAdServicesDataProvider.h"
#import "AMASessionExpirationHandler.h"
#import "AMAMetricaConfiguration.h"
#import "AMAAdProvider.h"
#import "AMAECommerceSerializer.h"
#import "AMAECommerceTruncator.h"
#import "AMAExternalAttributionSerializer.h"

@implementation AMAReporter (TestUtilities)

- (instancetype)initWithApiKey:(NSString *)apiKey
                          main:(BOOL)main
               reporterStorage:(AMAReporterStorage *)reporterStorage
                  eventBuilder:(AMAEventBuilder *)eventBuilder
              internalReporter:(AMAInternalEventsReporter *)internalReporter
      attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor
                  privacyTimer:(AMAPrivacyTimer *)privacyTimer
{
    AMACancelableDelayedExecutor *executor = [[AMACancelableDelayedExecutor alloc] initWithIdentifier:self];

    AMAAdServicesDataProvider *adServicesDataProvider = nil;
    if (@available(iOS 14.3, *)) {
        adServicesDataProvider = [[AMAAdServicesDataProvider alloc] init];
    }
    
    AMASessionExpirationHandler *sessionExpirationHandler =
        [[AMASessionExpirationHandler alloc] initWithConfiguration:[AMAMetricaConfiguration sharedInstance]
                                                            APIKey:apiKey];
    
    AMAAdProvider *adProvider = [AMAAdProvider sharedInstance];
    
    return [self initWithApiKey:apiKey
                           main:main
                reporterStorage:reporterStorage
                   eventBuilder:eventBuilder
               internalReporter:internalReporter
                       executor:executor
       attributionCheckExecutor:attributionCheckExecutor
            eCommerceSerializer:[[AMAECommerceSerializer alloc] init]
             eCommerceTruncator:[[AMAECommerceTruncator alloc] init]
                     adServices:adServicesDataProvider
  externalAttributionSerializer:[[AMAExternalAttributionSerializer alloc] init]
       sessionExpirationHandler:sessionExpirationHandler
                     adProvider:adProvider
                   privacyTimer:privacyTimer];
}

@end
