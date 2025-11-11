#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

#import "AMAUnhandledCrashDetector.h"

@interface AMAUnhandledCrashDetector ()

@property (nonatomic, copy) NSString *previousBundleVersion;
@property (nonatomic, copy) NSString *previousOSVersion;
@property (nonatomic, assign) BOOL appWasTerminated;
@property (nonatomic, assign) BOOL appWasInBackground;

- (void)hostStateDidChange:(AMAHostAppState)hostState;

+ (NSString *)currentBundleVersion;
+ (NSString *)currentOSVersion;

@end

SPEC_BEGIN(AMAUnhandledCrashDetectorTests)

describe(@"AMAUnhandledCrashDetector", ^{
    let(storage, ^{ return [AMAUserDefaultsStorage nullMock]; });
    let(hostAppStateProvider, ^{ return [KWMock nullMockForProtocol:@protocol(AMAHostStateProviding)]; });
    let(executor, ^{ return [[AMAManualCurrentQueueExecutor alloc] init]; });
    let(crashDetector, ^{
        return [[AMAUnhandledCrashDetector alloc] initWithStorage:storage
                                                 hostStateProvider:hostAppStateProvider
                                                          executor:executor];
    });

    context(@"Should initialize correctly", ^{

        context(@"Should load initial state from storage", ^{

            context(@"Should not do anything if the executor is not working", ^{

                it(@"Should not load anything from the storage", ^{
                    [[storage shouldNot] receive:@selector(stringForKey:)];
                    [[storage shouldNot] receive:@selector(boolForKey:)];
                    [crashDetector startDetecting];
                });

                it(@"Should not write anything to the storage", ^{
                    [[storage shouldNot] receive:@selector(setObject:forKey:)];
                    [[storage shouldNot] receive:@selector(setBool:forKey:)];
                    [[storage shouldNot] receive:@selector(synchronize)];
                    [crashDetector startDetecting];
                });

                it(@"Should not add observer to the hostAppStateProvider", ^{
                    [crashDetector startDetecting];
                    [[hostAppStateProvider should] receive:@selector(setDelegate:) withArguments:crashDetector];
                    [executor execute];
                });
            });

            context(@"Should start detecting if the executor is working", ^{

                it(@"Should load from the storage", ^{
                    [[storage should] receive:@selector(stringForKey:) withCountAtLeast:1];
                    [[storage should] receive:@selector(boolForKey:) withCountAtLeast:1];
                    [crashDetector startDetecting];
                    [executor execute];
                });

                it(@"Should write to the storage", ^{
                    [[storage should] receive:@selector(setObject:forKey:) withCountAtLeast:1];
                    [[storage should] receive:@selector(setBool:forKey:) withCountAtLeast:1];
                    [[storage should] receive:@selector(synchronize) withCountAtLeast:1];
                    [crashDetector startDetecting];
                    [executor execute];
                });

                it(@"Should add observer to the hostAppStateProvider", ^{
                    [[hostAppStateProvider should] receive:@selector(setDelegate:)
                                          withCountAtLeast:1
                                                 arguments:crashDetector];
                    [crashDetector startDetecting];
                    [executor execute];
                });
            });

            it(@"Should load stored value for previous bundle version from storage", ^{
                NSString *previousBundleVersion = @"0.0.0";
                [storage stub:@selector(stringForKey:) andReturn:previousBundleVersion
                withArguments:kAMAUserDefaultsStringKeyPreviousBundleVersion];
                [crashDetector startDetecting];
                [executor execute];
                [[crashDetector.previousBundleVersion should] equal:previousBundleVersion];
            });

            it(@"Should load stored value for previous os version storage", ^{
                NSString *previousOSVersion = @"0.0.0";
                [storage stub:@selector(stringForKey:) andReturn:previousOSVersion
                withArguments:kAMAUserDefaultsStringKeyPreviousOSVersion];
                [crashDetector startDetecting];
                [executor execute];
                [[crashDetector.previousOSVersion should] equal:previousOSVersion];
            });

            context(@"Should load stored value for app termination info", ^{
                void (^verify)(BOOL boolValue) = ^(BOOL boolValue) {
                    [storage stub:@selector(boolForKey:) andReturn:theValue(boolValue)
                    withArguments:kAMAUserDefaultsStringKeyAppWasTerminated];
                    [crashDetector startDetecting];
                    [executor execute];
                    [[theValue(crashDetector.appWasTerminated) should] equal:theValue(boolValue)];
                };

                it(@"Should load NO", ^{
                    verify(NO);
                });

                it(@"Should load YES", ^{
                    verify(YES);
                });
            });

            context(@"Should load stored value for background status", ^{
                void(^verify)(BOOL boolValue) = ^(BOOL boolValue) {
                    [storage stub:@selector(boolForKey:) andReturn:theValue(boolValue)
                    withArguments:kAMAUserDefaultsStringKeyAppWasInBackground];
                    [crashDetector startDetecting];
                    [executor execute];
                    [[theValue(crashDetector.appWasInBackground) should] equal:theValue(boolValue)];
                };

                it(@"Should load NO", ^{
                    verify(NO);
                });

                it(@"Should load YES", ^{
                    verify(YES);
                });
            });
        });

        context(@"Should store state snapshot", ^{

            it(@"Should store current bundle version", ^{
                [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:@"0"];
                [AMAPlatformDescription stub:@selector(appVersionName) andReturn:@"0"];
                [[storage should] receive:@selector(setObject:forKey:)
                            withArguments:@"0.0", kAMAUserDefaultsStringKeyPreviousBundleVersion];
                [crashDetector startDetecting];
                [executor execute];
            });

            it(@"Should store current os version", ^{
                NSString *operatingSystemVersionString = @"0.0";
                [AMAPlatformDescription stub:@selector(OSVersion) andReturn:operatingSystemVersionString];
                [[storage should] receive:@selector(setObject:forKey:)
                            withArguments:operatingSystemVersionString,
                                  kAMAUserDefaultsStringKeyPreviousOSVersion];
                [crashDetector startDetecting];
                [executor execute];

            });

            it(@"Should store app termination info from app state", ^{
                [hostAppStateProvider stub:@selector(hostState) andReturn:theValue(AMAHostAppStateTerminated)];
                [[storage should] receive:@selector(setBool:forKey:)
                            withArguments:theValue(YES), kAMAUserDefaultsStringKeyAppWasTerminated];
                [crashDetector startDetecting];
                [executor execute];
            });

            it(@"Should store app background status from app state", ^{
                [[hostAppStateProvider stub] hostState];
                [hostAppStateProvider stub:@selector(hostState) andReturn:theValue(AMAHostAppStateBackground)];
                [[storage should] receive:@selector(setBool:forKey:)
                            withArguments:theValue(YES), kAMAUserDefaultsStringKeyAppWasInBackground];
                [crashDetector startDetecting];
                [executor execute];
            });
        });

        it(@"Should register to observe app state", ^{
            [[hostAppStateProvider should] receive:@selector(setDelegate:) withArguments:crashDetector];
            [crashDetector startDetecting];
            [executor execute];
        });
    });
    context(@"Should store values to storage on outer notifications", ^{

        it(@"Should save YES to AMAStorageStringKeyAppWasTerminated on receiving AMAHostAppStateTerminated", ^{
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(YES), kAMAUserDefaultsStringKeyAppWasTerminated];
            [crashDetector hostStateDidChange:AMAHostAppStateTerminated];
        });

        it(@"Should save NO to AMAStorageStringKeyAppWasTerminated on receiving AMAHostAppStateForeground", ^{
            [hostAppStateProvider stub:@selector(hostState) andReturn: theValue(AMAHostAppStateForeground)];
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(NO), kAMAUserDefaultsStringKeyAppWasTerminated];
            [crashDetector hostStateDidChange:hostAppStateProvider];
        });

        it(@"Should save NO to AMAStorageStringKeyAppWasTerminated on receiving AMAHostAppStateBackground", ^{
            [hostAppStateProvider stub:@selector(hostState) andReturn:theValue(AMAHostAppStateBackground)];
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(NO), kAMAUserDefaultsStringKeyAppWasTerminated];
            [crashDetector hostStateDidChange:hostAppStateProvider];
        });

        it(@"Should save YES to AMAStorageStringKeyAppWasInBackground on receiving AMAHostAppStateTerminated", ^{
            [hostAppStateProvider stub:@selector(hostState) andReturn:theValue(AMAHostAppStateTerminated)];
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(YES), kAMAUserDefaultsStringKeyAppWasInBackground];
            [crashDetector hostStateDidChange:hostAppStateProvider];
        });

        it(@"Should save YES to AMAStorageStringKeyAppWasInBackground on receiving AMAHostAppStateBackground", ^{
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(YES), kAMAUserDefaultsStringKeyAppWasInBackground];
            [crashDetector hostStateDidChange:AMAHostAppStateBackground];
        });

        it(@"Should save NO to AMAStorageStringKeyAppWasInBackground on receiving AMAHostAppStateForeground", ^{
            [[storage should] receive:@selector(setBool:forKey:)
                        withArguments:theValue(NO), kAMAUserDefaultsStringKeyAppWasInBackground];
            [crashDetector hostStateDidChange:AMAHostAppStateForeground];
        });
    });
    context(@"CheckUnhandedCrash", ^{
        static NSString *const previousBundleVersion = @"0.0";
        static NSString *const previousOSVersion = @"1.1";
        AMAUnhandledCrashType __block unhandledCrashType;
        AMAUnhandledCrashCallback crashCallback = ^(AMAUnhandledCrashType crashType) {
            unhandledCrashType = crashType;
        };

        AMAUnhandledCrashType (^checkUnhandledCrashType)(void) = ^{
            [crashDetector checkUnhandledCrash:crashCallback];
            return unhandledCrashType;
        };

        context(@"Should send AMAUnhandledCrashUnknown to callback", ^{
            beforeEach(^{
                crashDetector.previousBundleVersion = previousBundleVersion;
                crashDetector.previousOSVersion = previousOSVersion;
                crashDetector.appWasTerminated = NO;
                crashDetector.appWasInBackground = NO;
            });
            
            it(@"If previous bundle version is null", ^{
                crashDetector.previousBundleVersion = nil;
                AMAUnhandledCrashType actualValue = checkUnhandledCrashType();
                [[theValue(actualValue) should] equal:theValue(AMAUnhandledCrashUnknown)];
            });

            it(@"If previous os version os null", ^{
                crashDetector.previousOSVersion = nil;
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashUnknown)];
            });

            it(@"If app was terminated", ^{
                crashDetector.appWasTerminated = YES;
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashUnknown)];
            });

            it(@"If current bundle version is different", ^{
                [AMAUnhandledCrashDetector stub:@selector(currentBundleVersion) andReturn:@"1.1"];
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashUnknown)];
            });

            it(@"If current OS version is different", ^{
                [AMAUnhandledCrashDetector stub:@selector(currentOSVersion) andReturn:@"0.1"];
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashUnknown)];
            });
        });
        context(@"Should notify callback with unhandled crash", ^{
            beforeEach(^{
                [AMAUnhandledCrashDetector stub:@selector(currentBundleVersion) andReturn:previousBundleVersion];
                [AMAUnhandledCrashDetector stub:@selector(currentOSVersion) andReturn:previousOSVersion];
                
                crashDetector.previousBundleVersion = previousBundleVersion;
                crashDetector.previousOSVersion = previousOSVersion;
                crashDetector.appWasTerminated = NO;
                crashDetector.appWasInBackground = NO;
            });

            it(@"Should be background crash if app was in background state", ^{
                crashDetector.appWasInBackground = YES;
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashBackground)];
            });

            it(@"Should be foreground crash if app was not in background state", ^{
                crashDetector.appWasInBackground = NO;
                [[theValue(checkUnhandledCrashType()) should] equal:theValue(AMAUnhandledCrashForeground)];
            });
        });
    });
});

SPEC_END
