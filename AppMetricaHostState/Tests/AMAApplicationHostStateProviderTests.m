
#import <UIKit/UIKit.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAApplicationHostStateProvider.h"
#import "AMAHostStatePublisher.h"

SPEC_BEGIN(AMAApplicationHostStateProviderTests)

describe(@"AMAApplicationHostStateProvider", ^{
    
    __block NSNotificationCenter *center = nil;
    __block AMAApplicationHostStateProvider *provider = nil;
    __block id hostStateProviderObserver = nil;
    
    beforeEach(^{
        center = [NSNotificationCenter new];
        provider = [[AMAApplicationHostStateProvider alloc] initWithNotificationCenter:center];
        hostStateProviderObserver = [KWMock nullMockForProtocol:@protocol(AMAHostStateProviderObserver)];
        [provider addAMAObserver:hostStateProviderObserver];
    });
    
    it(@"should inherit publisher", ^{
        [[theValue([provider isKindOfClass:[AMAHostStatePublisher class]]) should] beYes];
    });
    
    it(@"should return background state by default", ^{
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateBackground)];
    });
    
    it(@"should change state to foreground on app become active", ^{
        [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateForeground)];
    });
    
    it(@"should change state to foreground on force update to foreground", ^{
        [provider forceUpdateToForeground];
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateForeground)];
    });
    
    it(@"should change state to background on app resign active", ^{
        [center postNotificationName:UIApplicationWillResignActiveNotification object:nil];
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateBackground)];
    });
    
    it(@"should change state to foreground on app terminate", ^{
        [center postNotificationName:UIApplicationWillTerminateNotification object:nil];
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateTerminated)];
    });
    
    context(@"with delegate", ^{
        
        it(@"should notify delegate on app become active", ^{
            [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
        });
        
        it(@"should not notify delegate on app become active if it is already foreground", ^{
            [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
            [[hostStateProviderObserver shouldNot] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
        });
        
        it(@"should notify delegate on force update to foreground", ^{
            [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
            [provider forceUpdateToForeground];
        });
        
        it(@"should not notify delegate on force update to foreground if it al already foreground", ^{
            [provider forceUpdateToForeground];
            [[hostStateProviderObserver shouldNot] receive:@selector(hostStateProviderDidChangeHostState)];
            [provider forceUpdateToForeground];
        });
        
        it(@"should notify delegate on app resign active", ^{
            [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationWillResignActiveNotification object:nil];
        });
        
        it(@"should not notify delegate on app resign active if it is already background", ^{
            [center postNotificationName:UIApplicationWillResignActiveNotification object:nil];
            [[hostStateProviderObserver shouldNot] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationWillResignActiveNotification object:nil];
        });
        
        it(@"should notify delegate on app will terminated", ^{
            [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationWillTerminateNotification object:nil];
        });
        
        it(@"should not notify delegate on app will terminated if it al already terminated", ^{
            [center postNotificationName:UIApplicationWillTerminateNotification object:nil];
            [[hostStateProviderObserver shouldNot] receive:@selector(hostStateProviderDidChangeHostState)];
            [center postNotificationName:UIApplicationWillTerminateNotification object:nil];
        });
    });
    
    it(@"Should comform to AMAHostStateControlling", ^{
        [[provider should] conformToProtocol:@protocol(AMAHostStateControlling)];
    });
});

SPEC_END
