
#import <Kiwi/Kiwi.h>
#import "AMAStartupPermissionController.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAStartupPermission.h"
#import "AMAStartupPermissionSerializer.h"

static NSString *const kAMALocationPermissionKey = @"NSLocationDescription";

SPEC_BEGIN(StartupPermissionControllerTests)

describe(@"StartupPermissionController", ^{

    AMAStartupPermissionController *__block permissionController = nil;
    
    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];

        permissionController = [[AMAStartupPermissionController alloc] init];
    });

    NSString *(^locationPermissionsString)(BOOL) = ^(BOOL enabled) {
        AMAStartupPermission *permission = [[AMAStartupPermission alloc] initWithName:kAMALocationPermissionKey
                                                                              enabled:enabled];
        return [AMAStartupPermissionSerializer JSONStringWithPermissions:@{ kAMALocationPermissionKey : permission }];
    };
    
    it(@"Should return YES if locationCollectingPermission is enabled", ^{
        [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(permissionsString)
                                                     andReturn:locationPermissionsString(YES)];
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(hadFirstStartup)
                                                        andReturn:theValue(YES)];
        [[theValue(permissionController.isLocationCollectingGranted) should] beYes];
    });
    
    it(@"Should return NO if locationCollectingPermission is not in the configuration list", ^{
        [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(permissionsString)
                                                     andReturn:@"[]"];
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(hadFirstStartup)
                                                        andReturn:theValue(YES)];
        [[theValue(permissionController.isLocationCollectingGranted) should] beNo];
    });

    it(@"Should return NO if locationCollectingPermission is in the configuration list but startup was not reached", ^{
        [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(permissionsString)
                                                     andReturn:locationPermissionsString(YES)];
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(hadFirstStartup)
                                                        andReturn:theValue(NO)];
        [[theValue(permissionController.isLocationCollectingGranted) should] beNo];
    });

    it(@"Should return NO if locationCollectingPermission is disabled", ^{
        [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(permissionsString)
                                                     andReturn:locationPermissionsString(NO)];
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(hadFirstStartup)
                                                        andReturn:theValue(YES)];
        [[theValue(permissionController.isLocationCollectingGranted) should] beNo];
    });
});

SPEC_END

