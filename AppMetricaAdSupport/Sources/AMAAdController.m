
#import <AppMetricaAdSupport/AppMetricaAdSupport.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import "AMAATTStatusProvider.h"
#import "AMAIDFAProvider.h"

@interface AMAAdController ()

@property (nonatomic, strong) AMAIDFAProvider *idfaProvider;
@property (nonatomic, strong) AMAATTStatusProvider *attStatusProvider;

@end

@implementation AMAAdController

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _idfaProvider = [[AMAIDFAProvider alloc] init];
        _attStatusProvider = [[AMAATTStatusProvider alloc] init];
    }
    return self;
}

- (NSUUID *)advertisingIdentifier
{
    return [self.idfaProvider advertisingIdentifier];
}

- (BOOL)isAdvertisingTrackingEnabled
{
    return [self.attStatusProvider isAdvertisingTrackingEnabled];
}

- (AMATrackingManagerAuthorizationStatus)ATTStatus
{
    return [self.attStatusProvider ATTStatus];
}

@end
