#import <XCTest/XCTest.h>
#import "AMAAdRevenueSourceContainer.h"
#import "AMABundleInfoMock.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAAdRevenueSourceContainer (Unprivate)
- (instancetype)initWithPluginSourceBundle:(NSBundle*)pluginSourceBundle;
@end


@interface AMAAdRevenueSourceContainerTests : XCTestCase

@property (nonatomic, strong) AMABundleInfoMock *bundleMock;
@property (nonatomic, strong) AMAAdRevenueSourceContainer *sourceContainer;

@end

@implementation AMAAdRevenueSourceContainerTests

- (void)setUp
{
    self.bundleMock = [AMABundleInfoMock new];
    self.sourceContainer = [[AMAAdRevenueSourceContainer alloc] initWithPluginSourceBundle:self.bundleMock];
}


- (void)testDefaultSources
{
    XCTAssertEqualObjects(self.sourceContainer.nativeSupportedSources, @[@"yandex"]);
    XCTAssertEqualObjects(self.sourceContainer.pluginSupportedSources, @[]);
}

- (void)testDefaultPluginSources
{
    NSArray *plugins = @[@"plugin1", @"yetanotherplugin", @"somethingelse"];
    self.bundleMock.mockedInfo = @{
        @"io.appmetrica.analytics.plugin_supported_ad_revenue_sources": [AMAJSONSerialization stringWithJSONObject:plugins error:nil]
    };
    XCTAssertEqualObjects(self.sourceContainer.pluginSupportedSources, plugins);
}

- (void)testAddNativeSource
{
    [self.sourceContainer addNativeSupportedSource:@"yetanothernativesource"];
    
    NSArray *expected = @[@"yandex", @"yetanothernativesource"];
    XCTAssertEqualObjects(self.sourceContainer.nativeSupportedSources, expected);
    
    [self.sourceContainer addNativeSupportedSource:@"additionalnativesource"];
    
    expected = @[@"yandex", @"yetanothernativesource", @"additionalnativesource"];
    XCTAssertEqualObjects(self.sourceContainer.nativeSupportedSources, expected);
}

@end
