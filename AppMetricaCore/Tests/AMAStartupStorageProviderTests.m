
#import <XCTest/XCTest.h>
#import "AMAStartupStorageProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseFactory.h"
#import <AppMetricaKeychain/AppMetricaKeychain.h>

@interface AMAStartupStorageProviderTests : XCTestCase

@end

@implementation AMAStartupStorageProviderTests

- (void)testStartupStorageProviding
{
    id<AMADatabaseProtocol> database = AMADatabaseFactory.configurationDatabase;
    __auto_type *configuration = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:[AMAKeychainBridge new]
                                                                                database:database
                                                              appGroupIdentifierProvider:nil];
    
    AMAStartupStorageProvider *provider = [[AMAStartupStorageProvider alloc] initWithConfiguration:configuration];
    NSString *key = @"foo";
    NSString *value = @"bar";
    
    id<AMAKeyValueStoring> storage = [database.storageProvider nonPersistentStorageForKeys:@[key] error:nil];
    [storage saveString:value forKey:key error:nil];
    [database.storageProvider saveStorage:storage error:nil];
    
    id<AMAKeyValueStoring> providerStorage = [provider startupStorageForKeys:@[key]];
    
    XCTAssertEqualObjects([providerStorage stringForKey:key error:nil], value, @"Should return actual startup storage");
    
    NSString *newValue = @"baz";
    [providerStorage saveString:newValue forKey:key error:nil];
    [provider saveStorage:providerStorage];
    
    storage = [database.storageProvider nonPersistentStorageForKeys:@[key] error:nil];
    
    XCTAssertEqualObjects([storage stringForKey:key error:nil], newValue, @"Should save startup storage");
}

- (void)testConformanceProtocol
{
    AMAStartupStorageProvider *provider = [[AMAStartupStorageProvider alloc] init];
    XCTAssertTrue([provider conformsToProtocol:@protocol(AMAStartupStorageProviding)],
                  @"Should conform to AMAStartupStorageProviding");
}

@end
