
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaAdSupport/AppMetricaAdSupport.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import "AMAATTStatusProvider.h"
#import "AMAIDFAProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAAdControllerTests)

describe(@"AMAAdController", ^{
    
    AMAATTStatusProvider *__block attProvider = nil;
    AMAIDFAProvider *__block idfaProvider = nil;
    AMAAdController *__block adController = nil;
    AMAAdController *__block allocedAdController = nil;
    
    beforeEach(^{
        attProvider = [AMAATTStatusProvider stubbedNullMockForDefaultInit];
        idfaProvider = [AMAIDFAProvider stubbedNullMockForDefaultInit];
        
        adController = [[AMAAdController alloc] init];
        allocedAdController = [AMAAdController nullMock];
        
        [AMAAdController stub:@selector(alloc) andReturn:allocedAdController];
        [allocedAdController stub:@selector(init) andReturn:adController];
    });
    afterEach(^{
        [AMAAdController clearStubs];
        [AMAATTStatusProvider clearStubs];
        [AMAIDFAProvider clearStubs];
    });
    
    context(@"AMAAdController", ^{
        it(@"Should register on load", ^{
            [[AMAAppMetrica should] receive:@selector(registerAdProvider:) withArguments:adController];
            
            [AMAAdController load];
        });
        
        it(@"Should call AMAIDFAProvider on advertisingIdentifier", ^{
            NSUUID *advertisingIdentifier = [NSUUID nullMock];
            [idfaProvider stub:@selector(advertisingIdentifier) andReturn:advertisingIdentifier];
            
            [[[adController advertisingIdentifier] should] equal:advertisingIdentifier];
        });
        
        
        it(@"Should call AMAATTStatusProvider on isAdvertisingTrackingEnabled", ^{
            [attProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
            
            [[theValue([adController isAdvertisingTrackingEnabled]) should] beYes];
        });
        
        it(@"Should call AMAATTStatusProvider on ATTStatus", ^{
            if (@available(iOS 14.0, tvOS 14.0, *)) {
                NSUInteger statusValue = arc4random_uniform(3);
                [attProvider stub:@selector(ATTStatus) andReturn:theValue((AMATrackingManagerAuthorizationStatus)statusValue)];
                
                [[theValue([adController ATTStatus]) should] equal:theValue(statusValue)];
            }
        });
    });
    it(@"Should comform to AMAAdProviding", ^{
        [[adController should] conformToProtocol:@protocol(AMAAdProviding)];
    });
});

SPEC_END
