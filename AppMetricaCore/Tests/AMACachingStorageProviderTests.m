
#import <XCTest/XCTest.h>
#import "AMACachingStorageProvider.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseProtocol.h"

@interface AMACachingStorageProviderTests : XCTestCase

@end

@implementation AMACachingStorageProviderTests

- (void)testCachingStorageProviding
{
    id<AMADatabaseProtocol> database = AMADatabaseFactory.configurationDatabase;
    AMACachingStorageProvider *provider = [[AMACachingStorageProvider alloc] initWithDatabase:database];
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
