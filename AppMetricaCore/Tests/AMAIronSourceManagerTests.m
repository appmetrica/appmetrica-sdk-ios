
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAIronSourceManager.h"
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceTestSDKStubs.h"
#import "AMAAppMetricaMock.h"

// Expose private impressionDelegate for assertions
@interface AMAIronSourceManager (Testing)
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *impressionDelegate;
@end

// MARK: - Fake impression data

@interface AMAFakeManagerImpressionData : NSObject
@property (nonatomic, strong) NSNumber *revenue;
@property (nonatomic, copy)   NSString *adFormat;
@property (nonatomic, copy)   NSString *adNetwork;
@property (nonatomic, copy)   NSString *placement;
@property (nonatomic, copy)   NSString *precision;
@property (nonatomic, copy)   NSString *mediationAdUnitId;
@property (nonatomic, copy)   NSString *mediationAdUnitName;
@end
@implementation AMAFakeManagerImpressionData
@end

// MARK: - Tests

@interface AMAIronSourceManagerTests : XCTestCase
@property (nonatomic, strong) AMAIronSourceManager *manager;
@end

@implementation AMAIronSourceManagerTests

- (void)setUp
{
    AMAIronSourceTestSDKStubsReset();
    [AMAAppMetricaMock resetCaptures];
    [AMAAppMetrica stub:@selector(reportAdRevenue:isAutocollected:onFailure:)
             withBlock:^id(NSArray *params) {
        [AMAAppMetricaMock.capturedAdRevenues addObject:params[0]];
        [AMAAppMetricaMock.capturedIsAutocollected addObject:params[1]];
        return nil;
    }];
    self.manager = [[AMAIronSourceManager alloc] init];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

// MARK: - Setup

- (void)testSetupCreatesImpressionDelegate
{
    [self.manager setupWithMajorVersion:8];
    XCTAssertNotNil(self.manager.impressionDelegate);
    [self.manager setupWithMajorVersion:9];
    XCTAssertNotNil(self.manager.impressionDelegate);
}

- (void)testSetupV8_registersOnlyWithIronSource
{
    gIronSourceSDKVersion = @"8.0.0";
    [self.manager setupWithMajorVersion:8];
    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 1u);
    XCTAssertEqual(gIronSourceRegisteredDelegates.firstObject, self.manager.impressionDelegate);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 0u);
}

- (void)testSetupV9_registersOnlyWithLevelPlay
{
    gLevelPlaySDKVersion = @"9.0.0";
    [self.manager setupWithMajorVersion:9];
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 1u);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.firstObject, self.manager.impressionDelegate);
    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 0u);
}

// MARK: - didActivateWithConfiguration

- (void)testDidActivate_flushesQueuedImpressions
{
    [[AMAIronSourceManager sharedInstance] setupWithMajorVersion:9];

    AMAFakeManagerImpressionData *data = [AMAFakeManagerImpressionData new];
    data.revenue = @2.0;
    [[AMAIronSourceManager sharedInstance].impressionDelegate impressionDataDidSucceed:data];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u, @"must not report before didActivate");

    [AMAIronSourceManager didActivateWithConfiguration:nil];

    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 1u);
}

- (void)testWillActivate_doesNotFlushImpressions
{
    [[AMAIronSourceManager sharedInstance] setupWithMajorVersion:9];
    AMAFakeManagerImpressionData *d = [AMAFakeManagerImpressionData new];
    d.revenue = @1.0;
    [[AMAIronSourceManager sharedInstance].impressionDelegate impressionDataDidSucceed:d];

    [AMAIronSourceManager willActivateWithConfiguration:nil];

    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

@end
