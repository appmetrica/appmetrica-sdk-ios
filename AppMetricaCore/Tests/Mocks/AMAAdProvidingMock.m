#import "AMAAdProvidingMock.h"

@implementation AMAAdProvidingMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _advertisingTrackingEnabled = NO;
        _advertisingIdentifier = nil;
        _ATTStatus = AMATrackingManagerAuthorizationStatusNotDetermined;
    }
    return self;
}

@end
