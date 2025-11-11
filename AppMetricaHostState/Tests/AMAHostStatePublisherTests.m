
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAHostStatePublisher.h"
#import "AMAHostStateControlling.h"

SPEC_BEGIN(AMAHostStatePublisherTests)

describe(@"AMAHostStatePublisher", ^{

    AMAHostStatePublisher *__block hostStatePublisher = nil;
    __block id hostStateProviderObserver = nil;

    beforeEach(^{
        hostStatePublisher = [[AMAHostStatePublisher alloc] init];
        hostStateProviderObserver = [KWMock nullMockForProtocol:@protocol(AMAHostStateProviderObserver)];
    });

    it(@"Broadcasting", ^{
        [hostStatePublisher addAMAObserver:hostStateProviderObserver];
        
        [[[hostStatePublisher observers] should] contain:hostStateProviderObserver];
        
        [hostStatePublisher removeAMAObserver:hostStateProviderObserver];
        
        [[[hostStatePublisher observers] should] equal:@[]];
    });
    
    it(@"hostStateDidChange", ^{
        [hostStatePublisher addAMAObserver:hostStateProviderObserver];
        
        [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
        
        [hostStatePublisher hostStateDidChange];
    });
    
    it(@"Should comform to AMABroadcasting", ^{
        [[hostStatePublisher should] conformToProtocol:@protocol(AMABroadcasting)];
    });
});

SPEC_END
