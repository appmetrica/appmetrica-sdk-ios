#import "AMAAdProvidingMock.h"

@implementation AMAAdProvidingMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _advertisingTrackingEnabled = NO;
        _advertisingIdentifier = nil;
        if (@available(iOS 14.0, tvOS 14.0, *)) {
            _ATTStatus = AMATrackingManagerAuthorizationStatusNotDetermined;
        }
    }
    return self;
}

@end
