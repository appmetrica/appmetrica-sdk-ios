
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAAdProvider.h"

SPEC_BEGIN(AMAAdProviderTests)

describe(@"AMAAdProvider", ^{
    
    let(externalProvider, ^{ return [KWMock nullMockForProtocol:@protocol(AMAAdProviding)]; });
    
    context(@"Default values", ^{
        
        it(@"Should return false on isAdvertisingTrackingEnabled", ^{
            [[theValue([[AMAAdProvider sharedInstance] isAdvertisingTrackingEnabled]) should] beNo];
        });
        
        it(@"Should return nil on advertisingIdentifier", ^{
            [[[[AMAAdProvider sharedInstance] advertisingIdentifier] should] beNil];
        });
        
        it(@"Should return AuthorizationStatusNotDetermined on ATTStatus", ^{
            if (@available(iOS 14.0, *)) {
                [[theValue([[AMAAdProvider sharedInstance] ATTStatus]) should]
                 equal:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
            }
        });
    });
    
    context(@"ExternalProvider", ^{
        beforeEach(^{
            [[AMAAdProvider sharedInstance] setupAdProvider:externalProvider];
        });
        
        it(@"Should call AMAAdController on isAdvertisingTrackingEnabled", ^{
            [externalProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
            
            [[theValue([[AMAAdProvider sharedInstance] isAdvertisingTrackingEnabled]) should] beYes];
        });
        
        it(@"Should call AMAAdController on advertisingIdentifier", ^{
            NSUUID *uuid = [NSUUID nullMock];
            [externalProvider stub:@selector(advertisingIdentifier) andReturn:uuid];
            
            [[[[AMAAdProvider sharedInstance] advertisingIdentifier] should] equal:uuid];
        });
        
        it(@"Should call AMAAdController on ATTStatus", ^{
            if (@available(iOS 14.0, *)) {
                NSUInteger statusValue = arc4random_uniform(4);
                [externalProvider stub:@selector(ATTStatus) andReturn:theValue(statusValue)];
                
                [[theValue([[AMAAdProvider sharedInstance] ATTStatus]) should] equal:theValue(statusValue)];
            }
        });
    });
});

SPEC_END
