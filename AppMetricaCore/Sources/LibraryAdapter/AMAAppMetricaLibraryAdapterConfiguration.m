
#import <Foundation/Foundation.h>
#import "AMACore.h"
#import "AMAAppMetricaLibraryAdapterConfiguration+Internal.h"

@interface AMAAppMetricaLibraryAdapterConfiguration ()

@property (nonatomic, strong, nullable, readwrite) NSNumber *advertisingIdentifierTrackingEnabledValue;
@property (nonatomic, strong, nullable, readwrite) NSNumber *locationTrackingEnabledValue;

@end

@implementation AMAAppMetricaLibraryAdapterConfiguration

- (BOOL)advertisingIdentifierTrackingEnabled
{
    return [self.advertisingIdentifierTrackingEnabledValue boolValue] ?: YES;
}

- (void)setAdvertisingIdentifierTrackingEnabled:(BOOL)advertisingIdentifierTrackingEnabled
{
    self.advertisingIdentifierTrackingEnabledValue = @(advertisingIdentifierTrackingEnabled);
}

- (BOOL)locationTrackingEnabled
{
    return [self.locationTrackingEnabledValue boolValue] ?: YES;
}

- (void)setLocationTrackingEnabled:(BOOL)locationTrackingEnabled
{
    self.locationTrackingEnabledValue = @(locationTrackingEnabled);
}

@end
