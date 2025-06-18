
#import <XCTest/XCTest.h>
#import "AMACachingStorageProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseFactory.h"
#import <AppMetricaKeychain/AppMetricaKeychain.h>

@interface AMACachingStorageProviderTests : XCTestCase

@end

@implementation AMACachingStorageProviderTests

- (void)testCachingStorageProviding
{
    id<AMADatabaseProtocol> database = AMADatabaseFactory.configurationDatabase;
    __auto_type *configuration = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:[AMAKeychainBridge new]
                                                                                database:database
                                                              appGroupIdentifierProvider:nil];
    
    AMACachingStorageProvider *provider = [[AMACachingStorageProvider alloc] initWithConfiguration:configuration];
    id<AMAKeyValueStoring> expectedStorage = database.storageProvider.cachingStorage;
    XCTAssertEqualObjects([provider cachingStorage], expectedStorage, @"Should return actual caching storage");
}

- (void)testConformanceProtocol
{
    AMACachingStorageProvider *provider = [[AMACachingStorageProvider alloc] init];
    XCTAssertTrue([provider conformsToProtocol:@protocol(AMACachingStorageProviding)],
                  @"Should conform to AMACachingStorageProviding");
}

@end
