#import <XCTest/XCTest.h>
#import "NSMutableDictionary+AdRevenueHelper.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface NSDictionaryAdRevenueHelperTests : XCTestCase

@property (nonatomic, strong) NSMutableDictionary *dictionary;

@property (nonatomic, strong, readonly) NSArray *pluginSources;
@property (nonatomic, strong, readonly) NSArray *nativeSources;

@property (nonatomic, strong, readonly) NSString *pluginSourcesValue;
@property (nonatomic, strong, readonly) NSString *nativeSourcesValue;

@property (nonatomic, strong, readonly) NSDictionary *expectedDictionary;

@end

@implementation NSDictionaryAdRevenueHelperTests

- (void)setUp
{
    _pluginSources = @[ @"plugin1", @"yetanotherplugin" ];
    _pluginSourcesValue = [AMAJSONSerialization stringWithJSONObject:_pluginSources error:nil];
    
    _nativeSources = @[ @"native2", @"somethingnative" ];
    _nativeSourcesValue = [AMAJSONSerialization stringWithJSONObject:_nativeSources error:nil];
    
    _expectedDictionary = @{
        @"plugin_supported_sources": _pluginSourcesValue,
        @"native_supported_sources": _nativeSourcesValue,
    };
    
    self.dictionary = [NSMutableDictionary dictionary];
}

- (void)testUpdateEmptyDictionary
{
    [self.dictionary updatePluginSupportedSources:self.pluginSources
                           nativeSupportedSources:self.nativeSources];
    
    XCTAssertEqualObjects(self.dictionary, _expectedDictionary);
}

- (void)testUpdateFilledDictionary
{
    NSDictionary *predefiedDict = @{
        @"key1": @"value1",
        @"key2": @(123),
    };
    [self.dictionary addEntriesFromDictionary:predefiedDict];
    
    [self.dictionary updatePluginSupportedSources:self.pluginSources
                           nativeSupportedSources:self.nativeSources];
    
    NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithDictionary:self.expectedDictionary];
    [expected addEntriesFromDictionary:predefiedDict];
    XCTAssertEqualObjects(self.dictionary, expected);
}

- (void)testOverrideDictionary
{
    NSDictionary *predefiedDict = @{
        @"key1": @"value1",
        @"key2": @(123),
    };
    [self.dictionary addEntriesFromDictionary:predefiedDict];
    self.dictionary[@"plugin_supported_sources"] = @"plugin value";
    self.dictionary[@"native_supported_sources"] = @"native value";
    
    [self.dictionary updatePluginSupportedSources:self.pluginSources
                           nativeSupportedSources:self.nativeSources];
    
    NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithDictionary:self.expectedDictionary];
    [expected addEntriesFromDictionary:predefiedDict];
    XCTAssertEqualObjects(self.dictionary, expected);
}


@end
