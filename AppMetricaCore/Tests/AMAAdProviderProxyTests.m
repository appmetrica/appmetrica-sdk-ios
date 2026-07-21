
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAAdProviderProxy.h"

SPEC_BEGIN(AMAAdProviderProxyTests)

describe(@"AMAAdProviderProxy", ^{
    
    let(backingProvider, ^{ return [KWMock nullMockForProtocol:@protocol(AMAAdProviding)]; });
    AMAAdProviderProxy *__block adProviderProxy;
    
    beforeEach(^{
        adProviderProxy = [AMAAdProviderProxy new];
    });
    
    context(@"Default values", ^{
        
        it(@"Should return false on isAdvertisingTrackingEnabled", ^{
            [[theValue([adProviderProxy isAdvertisingTrackingEnabled]) should] beNo];
        });
        
        it(@"Should return nil on advertisingIdentifier", ^{
            [[[adProviderProxy advertisingIdentifier] should] beNil];
        });
        
        it(@"Should return AuthorizationStatusNotDetermined on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                [[theValue([adProviderProxy ATTStatus]) should]
                 equal:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
            }
        });
    });
    
    context(@"Disabled", ^{
        
        beforeEach(^{
            adProviderProxy.enabled = NO;
        });
        
        it(@"Should return false on isAdvertisingTrackingEnabled", ^{
            [[theValue([adProviderProxy isAdvertisingTrackingEnabled]) should] beNo];
        });
        
        it(@"Should return nil on advertisingIdentifier", ^{
            [[[adProviderProxy advertisingIdentifier] should] beNil];
        });
        
        it(@"Should return AuthorizationStatusNotDetermined on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                [[theValue([adProviderProxy ATTStatus]) should]
                 equal:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
            }
        });
    });
    
    context(@"Backing provider", ^{
        beforeEach(^{
            [adProviderProxy setBackingProvider:backingProvider];
        });
        
        it(@"Should call backing provider on isAdvertisingTrackingEnabled", ^{
            [backingProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
            
            [[theValue([adProviderProxy isAdvertisingTrackingEnabled]) should] beYes];
        });
        
        it(@"Should call backing provider on advertisingIdentifier", ^{
            NSUUID *uuid = [NSUUID nullMock];
            [backingProvider stub:@selector(advertisingIdentifier) andReturn:uuid];
            
            [[[adProviderProxy advertisingIdentifier] should] equal:uuid];
        });
        
        it(@"Should call backing provider on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                NSUInteger statusValue = arc4random_uniform(4);
                [backingProvider stub:@selector(ATTStatus) andReturn:theValue(statusValue)];
                
                [[theValue([adProviderProxy ATTStatus]) should] equal:theValue(statusValue)];
            }
        });
    });
});

SPEC_END
