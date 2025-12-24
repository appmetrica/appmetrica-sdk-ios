#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

#import "AMAExternalAttributionConfiguration.h"
#import "AMAExternalAttributionController.h"
#import "AMAMetricaPersistentConfigurationMock.h"
#import "AMAReporterMock.h"
#import "AMAStartupParametersConfigurationMock.h"

@interface AMAExternalAttributionControllerTests : XCTestCase

@property (nonatomic, strong) AMAExternalAttributionController *controller;
@property (nonatomic, strong) AMAMetricaPersistentConfigurationMock *persistentMock;
@property (nonatomic, strong) AMAStartupParametersConfigurationMock *startupMock;
@property (nonatomic, strong) AMAReporterMock *reporterMock;
@property (nonatomic, strong) AMADateProviderMock *dateProviderMock;

@end

@implementation AMAExternalAttributionControllerTests

static NSTimeInterval const kTestInterval = 300;
static NSString *const kExpectedHash = @"e43abcf3375244839c012f9633f95862d232a95b00d5bc7348b3098b9fed7f32"; // SHA256 of {"key":"value"}
static NSDictionary *kExpectedAttributionData = nil;
static NSString *const kUpdatedHash = @"e974441f15a6356c5b3fd9d1631a54876e7f37efa3eecfc3957ce642b0b762ac"; // SHA256 of {"key":"newValue"}
static NSDictionary *kUpdatedAttributionData = nil;

+ (void)setUp
{
    kExpectedAttributionData = @{@"key": @"value"};
    kUpdatedAttributionData = @{@"key": @"newValue"};
}

- (void)setUp
{
    [super setUp];
    
    self.dateProviderMock = [[AMADateProviderMock alloc] init];
    self.persistentMock = [[AMAMetricaPersistentConfigurationMock alloc] init];
    
    self.startupMock = [[AMAStartupParametersConfigurationMock alloc] init];
    self.startupMock.externalAttributionCollectingInterval = @(kTestInterval);
    
    self.reporterMock = [[AMAReporterMock alloc] init];
    
    self.controller = [[AMAExternalAttributionController alloc] initWithStartupConfiguration:self.startupMock
                                                                     persistentConfiguration:self.persistentMock
                                                                                dateProvider:self.dateProviderMock
                                                                                    reporter:self.reporterMock];
}

#pragma mark - With empty storage

- (void)testSendingAttributionDataSendsToServerWithEmptyStorage
{
    [self.controller processAttributionData:kExpectedAttributionData source:kAMAAttributionSourceAdjust onFailure:nil];
    
    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertEqualObjects(self.reporterMock.lastSource, kAMAAttributionSourceAdjust);
    XCTAssertEqualObjects(self.reporterMock.lastAttribution, kExpectedAttributionData);
}

- (void)testSavingAttributionDataInEmptyStorage
{
    NSDate *expectedDate = [self.dateProviderMock freeze];
    [self.controller processAttributionData:kExpectedAttributionData source:kAMAAttributionSourceAdjust onFailure:nil];
    
    __auto_type expectedConfig = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                   timestamp:expectedDate
                                                                                contentsHash:kExpectedHash];
    
    XCTAssertEqualObjects(self.persistentMock.externalAttributionConfigurations, @{kAMAAttributionSourceAdjust: expectedConfig});
}

#pragma mark - Within the interval

- (AMAExternalAttributionConfigurationMap *)setUpIntervalEndApproachingEnvironment
{
    [self simulateDateByAddingTimeInterval:kTestInterval - 1];
    return [self saveAttribtuionInStorageWithDate:self.dateProviderMock.currentDate];
}

- (void)testIgnoreRepeatedDataFromTheSameSourceWithinTheInterval
{
    AMAExternalAttributionConfigurationMap *exprectedConfig = [self setUpIntervalEndApproachingEnvironment];
    
    [self.controller processAttributionData:kExpectedAttributionData source:kAMAAttributionSourceAdjust onFailure:nil];
    
    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertEqualObjects(self.persistentMock.externalAttributionConfigurations, exprectedConfig);
}

- (void)testShouldUpdateAndSendChangedAttributionDataFromTheSameSourceWithinTheInterval
{
    [self setUpIntervalEndApproachingEnvironment];
    
    AMAExternalAttributionConfiguration *updatedExpectedConfig =
        [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                          timestamp:self.dateProviderMock.currentDate
                                                       contentsHash:kUpdatedHash];
    
    AMAExternalAttributionConfigurationMap *updatedPersistenceConfig = @{kAMAAttributionSourceAdjust: updatedExpectedConfig};
    
    [self.controller processAttributionData:kUpdatedAttributionData source:kAMAAttributionSourceAdjust onFailure:nil];
    
    XCTAssertEqualObjects(self.persistentMock.externalAttributionConfigurations, updatedPersistenceConfig);
    
    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertEqualObjects(self.reporterMock.lastSource, kAMAAttributionSourceAdjust);
    XCTAssertEqualObjects(self.reporterMock.lastAttribution, kUpdatedAttributionData);
}

#pragma mark - When the interval has passed

- (AMAExternalAttributionConfigurationMap *)setUpIntervalPassedEnvironment 
{
    [self simulateDateByAddingTimeInterval:kTestInterval + 1];
    return [self saveAttribtuionInStorageWithDate:self.dateProviderMock.currentDate];
}

- (void)testShouldIgnoreAttributionDataFromTheSameSourceAfterIntervalHasPassed
{
    AMAExternalAttributionConfigurationMap *expectedConfig = [self setUpIntervalPassedEnvironment];

    AMAAttributionSource source = kAMAAttributionSourceAdjust;

    [self.controller processAttributionData:kExpectedAttributionData source:source onFailure:nil];

    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertEqualObjects(self.persistentMock.externalAttributionConfigurations, expectedConfig);
}

- (void)testShouldSendAndSaveAttributionDataFromAnotherSourceAfterIntervalHasPassed
{
    AMAExternalAttributionConfigurationMap *expectedConfig = [self setUpIntervalPassedEnvironment];

    AMAAttributionSource newSource = kAMAAttributionSourceAppsflyer;

    AMAExternalAttributionConfiguration *expectedNewConfig =
        [[AMAExternalAttributionConfiguration alloc] initWithSource:newSource
                                                          timestamp:self.dateProviderMock.currentDate
                                                       contentsHash:kUpdatedHash];

    NSMutableDictionary *expectedNewPersistenceConfig = [expectedConfig mutableCopy];
    [expectedNewPersistenceConfig addEntriesFromDictionary:@{newSource: expectedNewConfig}];

    [self.controller processAttributionData:kUpdatedAttributionData source:newSource onFailure:nil];

    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertEqualObjects(self.reporterMock.lastSource, newSource);
    XCTAssertEqualObjects(self.reporterMock.lastAttribution, kUpdatedAttributionData);
    
    XCTAssertEqualObjects(self.persistentMock.externalAttributionConfigurations, expectedNewPersistenceConfig.copy);
}

static NSTimeInterval const kDefaultInterval = 864000;

#pragma mark - When externalAttributionConfigurations is nil

- (void)testShouldSendAttributionDataIfProcessedOneSecondBeforeDefaultIntervalExpires
{
    self.startupMock.externalAttributionCollectingInterval = nil;
    NSDate *expectedDate = [self.dateProviderMock freeze];
    [self saveAttribtuionInStorageWithDate:expectedDate];
    
    [self simulateDateByAddingTimeInterval:kDefaultInterval - 1];
    
    NSDictionary *attributionData = @{@"new": @"data"};
    AMAAttributionSource source = kAMAAttributionSourceAdjust;

    [self.controller processAttributionData:attributionData source:source onFailure:nil];

    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled);
}

- (void)testShouldNotSendAttributionDataIfProcessedOneSecondAfterDefaultIntervalExpires
{
    self.startupMock.externalAttributionCollectingInterval = nil;
    NSDate *expectedDate = [self.dateProviderMock freeze];
    [self saveAttribtuionInStorageWithDate:expectedDate];
    
    [self simulateDateByAddingTimeInterval:kDefaultInterval + 1];
    
    NSDictionary *attributionData = @{@"new": @"data"};
    AMAAttributionSource source = kAMAAttributionSourceAdjust;

    [self.controller processAttributionData:attributionData source:source onFailure:nil];

    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled);
}

#pragma mark - Using Configuration Set by Protocol

static NSTimeInterval const kUpdatedInterval = 500;

- (void)testAttributionDataProcessedUsingUpdatedIntervalBeforeExpires
{
    AMAStartupParametersConfigurationMock *updatedConfig = [[AMAStartupParametersConfigurationMock alloc] init];
    updatedConfig.externalAttributionCollectingInterval = @(kUpdatedInterval);
    [self.controller startupUpdateCompletedWithConfiguration:updatedConfig];
    
    NSDate *expectedDate = [self.dateProviderMock freeze];
    [self saveAttribtuionInStorageWithDate:expectedDate];
    [self simulateDateByAddingTimeInterval:kUpdatedInterval - 1];
    
    NSDictionary *attributionData = @{@"new": @"data"};
    AMAAttributionSource source = kAMAAttributionSourceAdjust;

    [self.controller processAttributionData:attributionData source:source onFailure:nil];

    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled,
                  @"Attribution data should be processed using the updated interval before it expires.");
}

- (void)testAttributionDataNotProcessedUsingUpdatedIntervalAfterExpires 
{
    AMAStartupParametersConfigurationMock *updatedConfig = [[AMAStartupParametersConfigurationMock alloc] init];
    updatedConfig.externalAttributionCollectingInterval = @(kUpdatedInterval);
    [self.controller startupUpdateCompletedWithConfiguration:updatedConfig];
    
    NSDate *expectedDate = [self.dateProviderMock freeze];
    [self saveAttribtuionInStorageWithDate:expectedDate];
    [self simulateDateByAddingTimeInterval:kUpdatedInterval + 1];
    
    NSDictionary *attributionData = @{@"new": @"data"};
    AMAAttributionSource source = kAMAAttributionSourceAdjust;

    [self.controller processAttributionData:attributionData source:source onFailure:nil];

    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled, 
                   @"Attribution data processed after the updated interval expires should not be sent.");
}

- (void)testIdenticalDataWithDifferentKeyOrderShouldNotTriggerDuplicateEvents
{
    NSDictionary *attributionData1 = @{@"a": @"b",@"c": @"d",@"e": @"f"};
    NSDictionary *attributionData2 = @{@"e": @"f",@"a": @"b",@"c": @"d"};

    XCTAssertEqualObjects(attributionData1, attributionData2);
    
    [self.controller processAttributionData:attributionData1
                                     source:kAMAAttributionSourceAdjust
                                  onFailure:nil];
    
    XCTAssertTrue(self.reporterMock.reportExternalAttributionCalled,
                  @"First attribution event should be sent");
    
    self.reporterMock.reportExternalAttributionCalled = NO;
    
    [self.controller processAttributionData:attributionData2
                                     source:kAMAAttributionSourceAdjust
                                  onFailure:nil];
    
    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled,
                   @"Second attribution event with same hash should not be sent");
    
    XCTAssertEqual(self.persistentMock.externalAttributionConfigurations.count, 1);
}

#pragma mark - Test Errors

- (void)testHashErrorsHandling
{
    __block BOOL isFailureCalled = NO;
    __block NSError *testError = nil;
    
    [self.controller processAttributionData:@{@1 : @1} source:kAMAAttributionSourceAdjust onFailure:^(NSError *error) {
        isFailureCalled = YES;
        testError = error;
    }];
    
    XCTAssertTrue(isFailureCalled, @"It should call error block");
    XCTAssertNotNil(testError);
    XCTAssertEqualObjects(testError.domain, kAMAAppMetricaErrorDomain);
    XCTAssertEqual(testError.code, AMAAppMetricaEventErrorCodeInvalidExternalAttributionContents);
}

- (void)testStorageOnError
{
    [self.controller processAttributionData:@{@1 : @1} source:kAMAAttributionSourceAdjust onFailure:nil];
    XCTAssertFalse(self.reporterMock.reportExternalAttributionCalled);
    XCTAssertNil(self.persistentMock.externalAttributionConfigurations);
}

# pragma mark - Setup Helpers

- (void)simulateDateByAddingTimeInterval:(NSTimeInterval)timeInterval
{
    NSDate *newDate = [self.dateProviderMock.currentDate dateByAddingTimeInterval:timeInterval];
    [self.dateProviderMock freezeWithDate:newDate];
}

- (AMAExternalAttributionConfigurationMap *)saveAttribtuionInStorageWithDate:(NSDate *)expectedDate
{
    __auto_type exprectedConfig = [[AMAExternalAttributionConfiguration alloc] initWithSource:kAMAAttributionSourceAdjust
                                                                                    timestamp:expectedDate
                                                                                 contentsHash:kExpectedHash];
    AMAExternalAttributionConfigurationMap *config = @{kAMAAttributionSourceAdjust: exprectedConfig};
    self.persistentMock.externalAttributionConfigurations = config;
    return config;
}

@end
