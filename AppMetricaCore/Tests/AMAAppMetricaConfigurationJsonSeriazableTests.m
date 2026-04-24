#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "AMAAppMetricaConfiguration+JSONSerializable.h"

static NSString *const defaultApiKey = @"C8BC97F1-C0B9-4053-A106-27043B1D8F9D";

@interface AMAAppMetricaConfigurationJsonSeriazableTests : XCTestCase
@end

@implementation AMAAppMetricaConfigurationJsonSeriazableTests

- (void)testNotCrashIfNull
{
    NSMutableDictionary *jsonDict = [[self newConfigurationDictionary] mutableCopy];
    
    jsonDict[kAMACustomLocation] = [NSNull null];
    jsonDict[kAMAAppVersion] = [NSNull null];
    jsonDict[kAMAPreloadInfo] = [NSNull null];
    jsonDict[kAMAUserProfileID] = [NSNull null];
    jsonDict[kAMAAppBuildNumber] = [NSNull null];
    jsonDict[kAMACustomHosts] = [NSNull null];
    jsonDict[kAMAAppEnvironment] = [NSNull null];
    
    XCTAssertNoThrow([[AMAAppMetricaConfiguration alloc] initWithJSON:jsonDict]);
}


- (NSDictionary *)newConfigurationDictionary
{
    return @{
        kAMAAPIKey: defaultApiKey,
    };
}

@end
