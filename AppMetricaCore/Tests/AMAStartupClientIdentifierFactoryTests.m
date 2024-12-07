
#import <Kiwi/Kiwi.h>
#import <UIKit/UIKit.h>
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAStartupClientIdentifier.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
@import AppMetricaIdentifiers;

SPEC_BEGIN(AMAStartupClientIdentifierFactoryTests)

describe(@"AMAStartupClientIdentifierFactory", ^{
    
    __block AMAMetricaConfiguration *configuration = nil;
    __block AMAMetricaPersistentConfiguration *persistent = nil;
    __block NSObject<AMAIdentifierProviding> *mockIdentifierProvider = nil;
    
    NSString *const testDeviceID = @"test-device-id";
    NSString *const testDeviceIDHash = @"test-device-id-hash";
    NSString *const testUUID = @"test-uuid";
    __block NSUUID *testIFVUUID = nil;
    __block NSString *testIFVString = nil;
    __block UIDevice *mockDevice = nil;
    
    beforeAll(^{
        testIFVString = @"11111111-1111-1111-1111-111111111111";
        testIFVUUID = [[NSUUID alloc] initWithUUIDString:testIFVString];
    });
    
    beforeEach(^{
        configuration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
        
        persistent = [AMAMetricaPersistentConfiguration nullMock];
        [configuration stub:@selector(persistent) andReturn:persistent];
        
        [persistent stub:@selector(deviceID) andReturn:testDeviceID];
        [persistent stub:@selector(deviceIDHash) andReturn:testDeviceIDHash];
        
        mockIdentifierProvider = [KWMock mockForProtocol:@protocol(AMAIdentifierProviding)];
        [mockIdentifierProvider stub:@selector(appMetricaUUID) andReturn:testUUID];
        [configuration stub:@selector(identifierProvider) andReturn:mockIdentifierProvider];
        
        mockDevice = [KWMock mockForClass:[UIDevice class]];
        [UIDevice stub:@selector(currentDevice) andReturn:mockDevice];
        [mockDevice stub:@selector(identifierForVendor) andReturn:testIFVUUID];
    });
    
    context(@"When all identifiers are available", ^{
        it(@"Should return a startupClientIdentifier with correct fields", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [[identifier.deviceID should] equal:testDeviceID];
            [[identifier.deviceIDHash should] equal:testDeviceIDHash];
            [[identifier.UUID should] equal:testUUID];
            [[identifier.IFV should] equal:testIFVString];
        });
    });
    
    context(@"When deviceID is nil", ^{
        beforeEach(^{
            [persistent stub:@selector(deviceID) andReturn:nil];
        });
        it(@"Should return a startupClientIdentifier with nil deviceID", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [identifier.deviceID shouldBeNil];
            [[identifier.deviceIDHash should] equal:testDeviceIDHash];
            [[identifier.UUID should] equal:testUUID];
            [[identifier.IFV should] equal:testIFVString];
        });
    });
    
    context(@"When deviceIDHash is nil", ^{
        beforeEach(^{
            [persistent stub:@selector(deviceIDHash) andReturn:nil];
        });
        it(@"Should return a startupClientIdentifier with nil deviceIDHash", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [[identifier.deviceID should] equal:testDeviceID];
            [identifier.deviceIDHash shouldBeNil];
            [[identifier.UUID should] equal:testUUID];
            [[identifier.IFV should] equal:testIFVString];
        });
    });
    
    context(@"When UUID is nil", ^{
        beforeEach(^{
            [mockIdentifierProvider stub:@selector(appMetricaUUID) andReturn:nil];
        });
        it(@"Should return a startupClientIdentifier with nil UUID", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [[identifier.deviceID should] equal:testDeviceID];
            [[identifier.deviceIDHash should] equal:testDeviceIDHash];
            [identifier.UUID shouldBeNil];
            [[identifier.IFV should] equal:testIFVString];
        });
    });
    
    context(@"When IFV is nil", ^{
        beforeEach(^{
            [mockDevice stub:@selector(identifierForVendor) andReturn:nil];
        });
        it(@"Should return a startupClientIdentifier with nil IFV", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [[identifier.deviceID should] equal:testDeviceID];
            [[identifier.deviceIDHash should] equal:testDeviceIDHash];
            [[identifier.UUID should] equal:testUUID];
            [identifier.IFV shouldBeNil];
        });
    });
    
    context(@"With all nil values", ^{
        beforeEach(^{
            [persistent stub:@selector(deviceID) andReturn:nil];
            [persistent stub:@selector(deviceIDHash) andReturn:nil];
            [mockIdentifierProvider stub:@selector(appMetricaUUID) andReturn:nil];
            [mockDevice stub:@selector(identifierForVendor) andReturn:nil];
        });
        it(@"Should return a startupClientIdentifier with all fields nil", ^{
            AMAStartupClientIdentifier *identifier = [AMAStartupClientIdentifierFactory startupClientIdentifier];
            [identifier.deviceID shouldBeNil];
            [identifier.deviceIDHash shouldBeNil];
            [identifier.UUID shouldBeNil];
            [identifier.IFV shouldBeNil];
        });
    });
});

SPEC_END
