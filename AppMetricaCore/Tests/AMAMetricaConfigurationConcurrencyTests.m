#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"

@interface AMAMetricaConfigurationConcurrencyTests : XCTestCase
@end

@implementation AMAMetricaConfigurationConcurrencyTests

- (AMAMetricaConfiguration *)configuration
{
    return [[AMAMetricaConfiguration alloc] initWithKeychainBridge:nil
                                                        database:nil
                                      appGroupIdentifierProvider:nil
                                   appMetricaConfigurationStorage:nil];
}

- (AMAStartupParametersConfiguration *)startupWithPermissions:(NSString *)permissions
{
    AMAKeyValueStorageMock *storage = [[AMAKeyValueStorageMock alloc] init];
    AMAStartupParametersConfiguration *startup = [[AMAStartupParametersConfiguration alloc] initWithStorage:storage];
    startup.permissionsString = permissions;
    startup.locationCollectingEnabled = YES;
    return startup;
}

- (void)testConcurrentStartupReadsAndReplacements
{
    AMAMetricaConfiguration *configuration = [self configuration];
    [configuration updateStartupConfiguration:[self startupWithPermissions:@"permissions"]];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
    dispatch_semaphore_t start = dispatch_semaphore_create(0);

    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_wait(start, DISPATCH_TIME_FOREVER);
        for (NSUInteger i = 0; i < 20000; ++i) {
            @autoreleasepool {
                // Each replacement owns its storage; old objects must be allowed to deallocate.
                [configuration updateStartupConfiguration:[self startupWithPermissions:@"permissions"]];
            }
        }
    });
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_wait(start, DISPATCH_TIME_FOREVER);
        for (NSUInteger i = 0; i < 20000; ++i) {
            @autoreleasepool {
                AMAStartupParametersConfiguration *startup = configuration.startup;
                XCTAssertEqualObjects(startup.permissionsString, @"permissions");
                XCTAssertTrue(startup.locationCollectingEnabled);
            }
        }
    });
    dispatch_semaphore_signal(start);
    dispatch_semaphore_signal(start);
    XCTAssertEqual(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC)), 0);
}

- (void)testReturnedStartupSurvivesReplacement
{
    AMAMetricaConfiguration *configuration = [self configuration];
    [configuration updateStartupConfiguration:[self startupWithPermissions:@"old"]];
    AMAStartupParametersConfiguration *snapshot = configuration.startup;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        @autoreleasepool {
            [configuration updateStartupConfiguration:[self startupWithPermissions:@"new"]];
        }
    });
    XCTAssertEqual(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);
    XCTAssertEqualObjects(snapshot.permissionsString, @"old");
    XCTAssertTrue(snapshot.locationCollectingEnabled);
    XCTAssertEqualObjects(configuration.startup.permissionsString, @"new");
}

@end
