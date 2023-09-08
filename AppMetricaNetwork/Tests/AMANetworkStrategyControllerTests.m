
#import <XCTest/XCTest.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import "AMAHTTPSessionProviderMock.h"

@interface AMANetworkStrategyControllerTests : XCTestCase

@property (nonatomic, strong) AMAHTTPSessionProviderMock *sessionProviderMock;

@end

@implementation AMANetworkStrategyControllerTests

- (void)setUp
{
    _sessionProviderMock = [[AMAHTTPSessionProviderMock alloc] init];
}

- (void)testSessionProvider
{
    id<AMANetworkSessionProviding> sesionProvider = [AMANetworkStrategyController sharedInstance].sessionProvider;
    
    XCTAssertEqual(sesionProvider.class, AMAHTTPSessionProvider.class, @"Should return default session provider");
    
    
    [[AMANetworkStrategyController sharedInstance] registerSessionProvider:self.sessionProviderMock];
    sesionProvider = [AMANetworkStrategyController sharedInstance].sessionProvider;
    
    XCTAssertEqual(sesionProvider.class, AMAHTTPSessionProviderMock.class, @"Should return registered session provider");
}

@end
