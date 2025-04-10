#import "AMAAdProvidingMock.h"

@implementation AMAAdProvidingMock

- (nullable NSUUID *)advertisingIdentifier { 
    return nil;
}

- (BOOL)isAdvertisingTrackingEnabled { 
    return NO;
}

- (AMATrackingManagerAuthorizationStatus)ATTStatus API_AVAILABLE(ios(14.0), tvos(14.0))
{
    return AMATrackingManagerAuthorizationStatusNotDetermined;
}

@end
