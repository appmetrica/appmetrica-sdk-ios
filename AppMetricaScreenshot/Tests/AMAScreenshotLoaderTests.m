
#import <XCTest/XCTest.h>
#import <AppMetricaScreenshot/AppMetricaScreenshot.h>
#import "AMAScreenshotLoader.h"
#import "AMAScreenshotWatcher.h"
#import "AMAKeyValueStorageProvidingStub.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAStartupStorageMockProvider.h"
#import "AMACachingStorageMockProvider.h"
#import "AMAScreenshotConfiguration.h"

@interface AMAScreenshotLoader (Unprivate)

@property (atomic, strong, nullable) AMAScreenshotWatcher *screenshotWatcher;
@property (nonatomic, strong, nullable) AMAScreenshotConfiguration *screenshotConfiguration;

@property (nonatomic, strong, nullable) id<AMAStartupStorageProviding> storageProvider;
@property (nonatomic, strong, nullable) id<AMACachingStorageProviding> cachingStorageProvider;

@end


@interface AMAScreenshotLoaderTests : XCTestCase

@property (nonatomic, strong) AMAScreenshotLoader *loader;
@property (nonatomic, strong) AMAStartupStorageMockProvider *startupProvider;
@property (nonatomic, strong) AMACachingStorageMockProvider *cachedProvider;

@property (nonatomic, strong) AMAKeyValueStorageMock *kvStorageMock;
@property (nonatomic, strong) AMAKeyValueStorageProvidingStub *kvStorageProvidingMock;

@end

@implementation AMAScreenshotLoaderTests

- (NSString *)randomApiKey
{
    return [[NSUUID UUID] UUIDString];
}

- (void)setUp
{
    self.loader = [AMAScreenshotLoader new];
    
    self.startupProvider = [AMAStartupStorageMockProvider new];
    self.cachedProvider = [AMACachingStorageMockProvider new];
    self.kvStorageMock = [AMAKeyValueStorageMock new];
    
    self.startupProvider.mockedStartupStorage = self.kvStorageMock;
    self.kvStorageProvidingMock = [AMAKeyValueStorageProvidingStub new];
}

- (void)testSetupNonMainReporter
{
    [self.loader setupWithReporterStorage:self.kvStorageProvidingMock main:NO forAPIKey:[self randomApiKey]];
    XCTAssertNil(self.loader.screenshotWatcher);
}

- (void)testStartupParameters
{
    NSDictionary *expected = @{
        @"request": @{
            @"features": @"scr",
            @"scr": @"1",
        },
    };
    XCTAssertEqualObjects([self.loader startupParameters], expected);
}

- (void)testSetupCachingParameters
{
    self.startupProvider.mockedStartupStorage = self.kvStorageMock;
    self.startupProvider.startupStorageExpectation = [self expectationWithDescription:@"startup expectation"];
    
    [self.loader setupStartupProvider:self.startupProvider
               cachingStorageProvider:self.cachedProvider];
    
    
    [self waitForExpectations:@[self.startupProvider.startupStorageExpectation] timeout:1];
    
    XCTAssertNotNil(self.loader.screenshotConfiguration);
    XCTAssertNotNil(self.loader.cachingStorageProvider);
    XCTAssertNotNil(self.loader.storageProvider);
    XCTAssertNil(self.loader.screenshotWatcher);
}

- (void)testSetupCachingParametersWithExisitingData
{
    self.kvStorageMock.storage = @{
        @"screenshot.enabled": @(NO),
        @"api_captor_config.enabled": @(NO),
    };
    
    self.startupProvider.mockedStartupStorage = self.kvStorageMock;
    self.startupProvider.startupStorageExpectation = [self expectationWithDescription:@"startup expectation"];
    
    [self.loader setupStartupProvider:self.startupProvider
               cachingStorageProvider:self.cachedProvider];
    
    [self waitForExpectations:@[self.startupProvider.startupStorageExpectation] timeout:1];
    
    XCTAssertNotNil(self.loader.screenshotConfiguration);
    XCTAssertNotNil(self.loader.cachingStorageProvider);
    XCTAssertNotNil(self.loader.storageProvider);
    XCTAssertNil(self.loader.screenshotWatcher);
}

- (void)testSetupCachingParametersWithEnabled
{
    self.kvStorageMock.storage = @{
        @"screenshot.enabled": @(YES),
        @"api_captor_config.enabled": @(YES),
    };
    
    self.startupProvider.mockedStartupStorage = self.kvStorageMock;
    self.startupProvider.startupStorageExpectation = [self expectationWithDescription:@"startup expectation"];
    
    [self.loader setupStartupProvider:self.startupProvider
               cachingStorageProvider:self.cachedProvider];
    
    [self waitForExpectations:@[self.startupProvider.startupStorageExpectation] timeout:1];
    
    XCTAssertNotNil(self.loader.screenshotConfiguration);
    XCTAssertNotNil(self.loader.cachingStorageProvider);
    XCTAssertNotNil(self.loader.storageProvider);
    XCTAssertNotNil(self.loader.screenshotWatcher);
    XCTAssertTrue(self.loader.screenshotWatcher.isStarted);
}

- (void)testUpdateStartupParameters
{
    self.kvStorageMock.storage = @{
        @"screenshot.enabled": @(NO),
        @"api_captor_config.enabled": @(NO),
    };
    
    NSDictionary *startupParameters = @{
        @"features": @{
            @"list": @{
                @"screenshot": @{
                    @"enabled": @(YES),
                },
            },
        },
        @"screenshot": @{
            @"api_captor_config": @{
                @"enabled": @(YES),
            },
        },
    };
    
    self.startupProvider.mockedStartupStorage = self.kvStorageMock;
    
    [self.loader setupStartupProvider:self.startupProvider
               cachingStorageProvider:self.cachedProvider];
    
    [self.loader startupUpdatedWithParameters:startupParameters];
    
    XCTAssertNotNil(self.loader.screenshotConfiguration);
    XCTAssertNotNil(self.loader.cachingStorageProvider);
    XCTAssertNotNil(self.loader.storageProvider);
    XCTAssertNotNil(self.loader.screenshotWatcher);
    XCTAssertTrue(self.loader.screenshotWatcher.isStarted);
}

@end
