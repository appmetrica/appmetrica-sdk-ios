
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAAdProvider.h"

SPEC_BEGIN(AMAAdProviderTests)

describe(@"AMAAdProvider", ^{
    
    let(externalProvider, ^{ return [KWMock nullMockForProtocol:@protocol(AMAAdProviding)]; });
    AMAAdProvider *__block adProvider;
    
    beforeEach(^{
        adProvider = [AMAAdProvider new];
    });
    
    context(@"Default values", ^{
        
        it(@"Should return false on isAdvertisingTrackingEnabled", ^{
            [[theValue([adProvider isAdvertisingTrackingEnabled]) should] beNo];
        });
        
        it(@"Should return nil on advertisingIdentifier", ^{
            [[[adProvider advertisingIdentifier] should] beNil];
        });
        
        it(@"Should return AuthorizationStatusNotDetermined on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                [[theValue([adProvider ATTStatus]) should]
                 equal:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
            }
        });
    });
    
    context(@"Disabled", ^{
        
        beforeEach(^{
            adProvider.isEnabled = NO;
        });
        
        it(@"Should return false on isAdvertisingTrackingEnabled", ^{
            [[theValue([adProvider isAdvertisingTrackingEnabled]) should] beNo];
        });
        
        it(@"Should return nil on advertisingIdentifier", ^{
            [[[adProvider advertisingIdentifier] should] beNil];
        });
        
        it(@"Should return AuthorizationStatusNotDetermined on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                [[theValue([adProvider ATTStatus]) should]
                 equal:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
            }
        });
    });
    
    context(@"ExternalProvider", ^{
        beforeEach(^{
            [adProvider setupAdProvider:externalProvider];
        });
        
        it(@"Should call AMAAdController on isAdvertisingTrackingEnabled", ^{
            [externalProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
            
            [[theValue([adProvider isAdvertisingTrackingEnabled]) should] beYes];
        });
        
        it(@"Should call AMAAdController on advertisingIdentifier", ^{
            NSUUID *uuid = [NSUUID nullMock];
            [externalProvider stub:@selector(advertisingIdentifier) andReturn:uuid];
            
            [[[adProvider advertisingIdentifier] should] equal:uuid];
        });
        
        it(@"Should call AMAAdController on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                NSUInteger statusValue = arc4random_uniform(4);
                [externalProvider stub:@selector(ATTStatus) andReturn:theValue(statusValue)];
                
                [[theValue([adProvider ATTStatus]) should] equal:theValue(statusValue)];
            }
        });
    });
});

SPEC_END
