#import <Kiwi/Kiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAApplicationStateManager.h"
#import "AMAAppStateManagerTestHelper.h"

SPEC_BEGIN(AMAApplicationStateManagerTests)

describe(@"AMAApplicationStateManager", ^{
    
    AMAAppStateManagerTestHelper *__block testHelper;
    
    beforeEach(^{
        testHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [testHelper stubApplicationState];
    });

    context(@"when creating an application state", ^{
        it(@"should return a non-nil application state", ^{
            AMAApplicationState *state = [AMAApplicationStateManager applicationState];
            [[state shouldNot] beNil];
        });
        
        it(@"should return an application state with correct values", ^{
            AMAApplicationState *state = [AMAApplicationStateManager applicationState];
            
            [[state.appVersionName should] equal:testHelper.appVersionName];
            [[state.kitVersionName should] equal:testHelper.kitVersionName];
            [[theValue(state.kitBuildNumber) should] equal:theValue(testHelper.kitBuildNumber)];
            [[state.kitBuildType should] equal:testHelper.kitBuildType];
            [[state.OSVersion should] equal:testHelper.OSVersion];
            [[theValue(state.OSAPILevel) should] equal:theValue(testHelper.OSAPILevel)];
            [[state.locale should] equal:testHelper.locale];
            [[theValue(state.isRooted) should] equal:theValue(testHelper.isRooted)];
            [[state.UUID should] equal:testHelper.UUID];
            [[state.deviceID should] equal:testHelper.deviceID];
            [[state.IFV should] equal:testHelper.IFV];
            [[state.IFA should] equal:testHelper.IFA];
            [[theValue(state.LAT) should] equal:theValue(testHelper.LAT)];
            [[state.appBuildNumber should] equal:@(testHelper.appBuildNumber).stringValue];
            [[theValue(state.appDebuggable) should] equal:theValue(testHelper.appDebuggable)];
        });
    });

    context(@"when creating a quick application state", ^{
        it(@"should return a non-nil quick application state", ^{
            AMAApplicationState *quickState = [AMAApplicationStateManager quickApplicationState];
            [[quickState shouldNot] beNil];
        });
        
        it(@"should return a quick application state with correct values", ^{
            AMAApplicationState *quickState = [AMAApplicationStateManager quickApplicationState];
            
            [[quickState.appVersionName should] equal:testHelper.appVersionName];
            [[quickState.kitVersionName should] equal:testHelper.kitVersionName];
            [[theValue(quickState.kitBuildNumber) should] equal:theValue(testHelper.kitBuildNumber)];
            [[quickState.kitBuildType should] equal:testHelper.kitBuildType];
            [[quickState.OSVersion should] equal:testHelper.OSVersion];
            [[theValue(quickState.OSAPILevel) should] equal:theValue(testHelper.OSAPILevel)];
            [[quickState.locale should] equal:testHelper.locale];
            [[theValue(quickState.isRooted) should] equal:theValue(testHelper.isRooted)];
            [[quickState.appBuildNumber should] equal:@(testHelper.appBuildNumber).stringValue];
            [[theValue(quickState.appDebuggable) should] equal:theValue(testHelper.appDebuggable)];
            [[theValue(quickState.LAT) should] equal:theValue(testHelper.LAT)];
        });
    });

    context(@"when filling empty values", ^{
        it(@"should return an application state with empty values filled", ^{
            AMAMutableApplicationState *emptyState = [AMAMutableApplicationState new];
            emptyState.appVersionName = @"";
            emptyState.kitVersionName = @"";
            emptyState.locale = @"";
            AMAApplicationState *filledState = [AMAApplicationStateManager stateWithFilledEmptyValues:emptyState];
            
            [[filledState.appVersionName should] equal:testHelper.appVersionName];
            [[filledState.kitVersionName should] equal:testHelper.kitVersionName];
            [[filledState.locale should] equal:testHelper.locale];
        });
        
        it(@"should not change non-empty values", ^{
            AMAMutableApplicationState *nonEmptyState = [AMAMutableApplicationState new];
            nonEmptyState.appVersionName = @"2.00";
            nonEmptyState.kitVersionName = @"2.0.0";
            nonEmptyState.locale = @"en_GB";
            
            testHelper.appVersionName = @"1.00";
            testHelper.kitVersionName = @"1.0.0";
            testHelper.locale = @"en_US";
            [testHelper stubApplicationState];
            
            AMAApplicationState *filledState = [AMAApplicationStateManager stateWithFilledEmptyValues:nonEmptyState];
            
            [[filledState.appVersionName should] equal:@"2.00"];
            [[filledState.kitVersionName should] equal:@"2.0.0"];
            [[filledState.locale should] equal:@"en_GB"];
        });
        
        it(@"quick state MUST contain LAT", ^{
            testHelper.LAT = YES;
            [testHelper stubApplicationState];
            
            AMAApplicationState *quickState = AMAApplicationStateManager.quickApplicationState;
            
            AMAApplicationState *filledState = [AMAApplicationStateManager stateWithFilledEmptyValues:quickState];
            
            [[theValue(filledState.LAT) should] beYes];
        });
    });
});

SPEC_END
