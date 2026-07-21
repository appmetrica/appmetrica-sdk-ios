#import <Foundation/Foundation.h>
#import "AMAAdProviding.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProvidingMock : NSObject <AMAAdProviding>

@property (nonatomic, assign, getter=isAdvertisingTrackingEnabled) BOOL advertisingTrackingEnabled;
@property (nonatomic, strong, nullable) NSUUID *advertisingIdentifier;
@property (nonatomic, assign) AMATrackingManagerAuthorizationStatus ATTStatus
    API_AVAILABLE(ios(14.0), tvos(14.0));

@end

NS_ASSUME_NONNULL_END
