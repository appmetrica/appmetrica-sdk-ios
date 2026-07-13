
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStartupClientIdentifier.h"
#import <UIKit/UIKit.h>
@import AppMetricaIdentifiers;

@implementation AMAStartupClientIdentifierFactory

+ (AMAStartupClientIdentifier *)startupClientIdentifier
{
    AMAStartupClientIdentifier *identifier = [[AMAStartupClientIdentifier alloc] init];
    identifier.deviceID = [AMAMetricaConfiguration sharedInstance].deviceID;
    identifier.deviceIDHash = [AMAMetricaConfiguration sharedInstance].deviceIDHash;
    identifier.UUID = [AMAMetricaConfiguration sharedInstance].appMetricaUUID;
    identifier.IFV = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return identifier;
}

@end
