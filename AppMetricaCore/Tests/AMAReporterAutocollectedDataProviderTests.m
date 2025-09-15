
@import XCTest;
#import "AMAReporterAutocollectedDataProvider.h"
#import "AMAMetricaPersistentConfigurationMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAReporterAutocollectedDataProviderTests : XCTestCase

@property (nonatomic, strong) AMAReporterAutocollectedDataProvider *provider;
@property (nonatomic, strong) AMAMetricaPersistentConfigurationMock *persistentMock;
@property (nonatomic, strong) AMADateProviderMock *dateProvider;

@end

@implementation AMAReporterAutocollectedDataProviderTests

- (void)setUp
{
    [super setUp];
    self.persistentMock = [[AMAMetricaPersistentConfigurationMock alloc] init];
    self.dateProvider = [[AMADateProviderMock alloc] init];
    self.provider = [[AMAReporterAutocollectedDataProvider alloc] initWithPersistentConfiguration:self.persistentMock
                                                                                     dateProvider:self.dateProvider];
}

- (void)tearDown
{
    self.provider = nil;
    self.persistentMock = nil;
    [super tearDown];
}

#pragma mark - addAutocollectedData:

- (void)testAddAutocollectedDataSavesTimestampForKey
{
    NSString *key = @"A";
    NSTimeInterval before = [NSDate date].timeIntervalSince1970;

    [self.provider addAutocollectedData:key];

    NSNumber *tsNum = self.persistentMock.autocollectedData[key];
    XCTAssertNotNil(tsNum);
    NSTimeInterval after = [NSDate date].timeIntervalSince1970;
    XCTAssertGreaterThanOrEqual(tsNum.doubleValue, before);
    XCTAssertLessThanOrEqual(tsNum.doubleValue, after);
}

- (void)testAddAutocollectedDataUpdatesExistingTimestampForSameKey
{
    NSString *key = @"A";
    self.persistentMock.autocollectedData = @{ key : @((NSTimeInterval)12345) };

    [self.provider addAutocollectedData:key];

    NSNumber *tsNum = self.persistentMock.autocollectedData[key];
    XCTAssertNotNil(tsNum);
    XCTAssertGreaterThan(tsNum.doubleValue, 12345.0);
}

- (void)testAddAutocollectedDataIgnoresEmptyKey
{
    self.persistentMock.autocollectedData = @{};
    [self.provider addAutocollectedData:@""];
    XCTAssertEqual(self.persistentMock.autocollectedData.count, 0);
}

#pragma mark - additionalAPIKeys

- (void)testAdditionalAPIKeysReturnsOnlyKeysYoungerThan7Days
{
    NSTimeInterval now = [self.dateProvider freeze].timeIntervalSince1970;
    NSTimeInterval day = 24 * 60 * 60;
    NSDictionary *seed = @{
        @"A": @(now - 6 * day),
        @"B": @(now - 8 * day),
        @"C": @(now - 7 * day)
    };
    self.persistentMock.autocollectedData = seed;

    NSArray<NSString *> *result = [self.provider additionalAPIKeys];
    NSSet *set = [NSSet setWithArray:result];

    XCTAssertTrue([set containsObject:@"A"]);
    XCTAssertTrue([set containsObject:@"C"]);
    XCTAssertFalse([set containsObject:@"B"]);
}

- (void)testAdditionalAPIKeysEmptyWhenNoData
{
    self.persistentMock.autocollectedData = @{};
    NSArray<NSString *> *result = [self.provider additionalAPIKeys];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 0);
}

- (void)testAdditionalAPIKeysIgnoresEmptyStringKey
{
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    self.persistentMock.autocollectedData = @{
        @"": @(now),
        @"A": @(now)
    };
    NSArray<NSString *> *result = [self.provider additionalAPIKeys];
    NSSet *set = [NSSet setWithArray:result];
    XCTAssertTrue([set containsObject:@"A"]);
    XCTAssertFalse([set containsObject:@""]);
}

@end
