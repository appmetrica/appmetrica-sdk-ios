
#import <UIKit/UIKit.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAExtensionHostStateProvider.h"

SPEC_BEGIN(AMAExtensionHostStateProviderTests)

describe(@"AMAExtensionHostStateProvider", ^{

    __block NSNotificationCenter *center = nil;
    __block AMAExtensionHostStateProvider *provider = nil;
    __block id hostStateProviderObserver = nil;

    beforeEach(^{
        center = [NSNotificationCenter new];
        provider = [[AMAExtensionHostStateProvider alloc] init];
        hostStateProviderObserver = [KWMock nullMockForProtocol:@protocol(AMAHostStateProviderObserver)];
        [provider addAMAObserver:hostStateProviderObserver];
    });
    
    it(@"should inherit publisher", ^{
        [[theValue([provider isKindOfClass:[AMAHostStatePublisher class]]) should] beYes];
    });

    it(@"should return foreground state by default", ^{
        [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateBackground)];
    });

    it(@"should remain background state on host app become active", ^{
        if (NSExtensionHostDidBecomeActiveNotification != nil) {
            [center postNotificationName:NSExtensionHostDidBecomeActiveNotification object:nil];
            [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateBackground)];
        }
    });

    it(@"should change state to foreground on force update to foreground", ^{
        if (NSExtensionHostDidBecomeActiveNotification != nil) {
            [provider forceUpdateToForeground];
            [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateForeground)];
        }
    });

    it(@"should remain background state on host app resign active", ^{
        if (NSExtensionHostWillResignActiveNotification != nil) {
            [center postNotificationName:NSExtensionHostWillResignActiveNotification object:nil];
            [[theValue([provider hostState]) should] equal:theValue(AMAHostAppStateBackground)];
        }
    });

    context(@"with delegate", ^{

        it(@"should notify delegate on force update to foreground", ^{
            if (NSExtensionHostDidBecomeActiveNotification != nil) {
                [[hostStateProviderObserver should] receive:@selector(hostStateProviderDidChangeHostState)];
                [provider forceUpdateToForeground];
            }
        });

        it(@"should not notify delegate on force update to foreground if it already foreground", ^{
            if (NSExtensionHostDidBecomeActiveNotification != nil) {
                [provider forceUpdateToForeground];
                [[hostStateProviderObserver shouldNot] receive:@selector(hostStateProviderDidChangeHostState)];
                [provider forceUpdateToForeground];
            }
        });

    });
    
    it(@"Should comform to AMAHostStateControlling", ^{
        [[provider should] conformToProtocol:@protocol(AMAHostStateControlling)];
    });
});

SPEC_END
