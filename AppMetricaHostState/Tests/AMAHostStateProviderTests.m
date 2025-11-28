
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAHostStateControllerFactory.h"
#import "AMAHostStateControlling.h"
#import "AMAApplicationHostStateProvider.h"

@interface AMAHostStateProvider () <AMAHostStateProviderObserver>

@property (nonatomic, nullable, weak) id<AMAHostStateControlling> hostStateController;

@end

SPEC_BEGIN(AMAHostStateProviderTests)

describe(@"AMAHostStateProvider", ^{
    
    AMAHostStateControllerFactory *__block factory = nil;
    __block AMAHostStateProvider *provider = nil;
    __block id hostStateController = nil;
    
    beforeEach(^{
        provider = [[AMAHostStateProvider alloc] init];
        hostStateController = provider.hostStateController ?: [AMAApplicationHostStateProvider stubbedNullMockForDefaultInit];
        
        factory = [AMAHostStateControllerFactory stubbedNullMockForDefaultInit];
        
        [factory stub:@selector(hostStateController) andReturn:hostStateController];
 
    });
    afterEach(^{
        [AMAApplicationHostStateProvider clearStubs];
        [AMAHostStateControllerFactory clearStubs];
    });
    
    it(@"Should call state provider factory on load", ^{
        [[factory should] receive:@selector(hostStateController)];
        
        [AMAHostStateProvider load];
    });
    
    it(@"Should add controller observer on init", ^{
        [[hostStateController should] receive:@selector(addAMAObserver:)];
        
        provider = [[AMAHostStateProvider alloc] init];
    });
    
    it(@"Should call state from host state controller", ^{
        [[hostStateController should] receive:@selector(hostState)];
        
        [provider hostState];
    });
    
    it(@"Should return host state value from host state provider", ^{
        [hostStateController stub:@selector(hostState) andReturn:theValue(AMAHostAppStateTerminated)];
        
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateTerminated)];
    });
    
    it(@"Should proxy force update to foreground", ^{
        [[hostStateController should] receive:@selector(forceUpdateToForeground)];
        
        [provider forceUpdateToForeground];
    });
    
    it(@"Should notify delegate on notifying from provider", ^{
        id hostStateProviderDelegate = [KWMock mockForProtocol:@protocol(AMAHostStateProviderDelegate)];
        provider.delegate = hostStateProviderDelegate;
        [hostStateController stub:@selector(hostState) andReturn:theValue(AMAHostAppStateTerminated)];
        
        [[hostStateProviderDelegate should] receive:@selector(hostStateDidChange:) withArguments:theValue(AMAHostAppStateTerminated)];
        [provider hostStateProviderDidChangeHostState];
    });
    
    it(@"Should comform to AMAHostStateProviding", ^{
        [[provider should] conformToProtocol:@protocol(AMAHostStateProviding)];
    });
    it(@"Should comform to AMAHostStateProviderObserver", ^{
        [[provider should] conformToProtocol:@protocol(AMAHostStateProviderObserver)];
    });
});

SPEC_END
