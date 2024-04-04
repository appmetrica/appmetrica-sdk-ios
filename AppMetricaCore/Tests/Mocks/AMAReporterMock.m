#import "AMAReporterMock.h"

@implementation AMAReporterMock

- (instancetype)init
{
    self = [super initWithApiKey:nil
                            main:YES
                 reporterStorage:nil
                    eventBuilder:nil
                internalReporter:nil
                        executor:nil
        attributionCheckExecutor:nil
             eCommerceSerializer:nil
              eCommerceTruncator:nil
                      adServices:nil
   externalAttributionSerializer:nil
        sessionExpirationHandler:nil
                      adProvider:nil 
                    privacyTimer:nil];

    if (self != nil) {
        
    }
    
    return self;
}



- (void)reportExternalAttribution:(NSDictionary *)attribution
                           source:(AMAAttributionSource)source
                        onFailure:(nullable void (^)(NSError *error))onFailure 
{
    self.reportExternalAttributionCalled = YES;
    
    self.lastAttribution = attribution;
    self.lastSource = source;
    self.lastOnFailure = onFailure;
}

@end
