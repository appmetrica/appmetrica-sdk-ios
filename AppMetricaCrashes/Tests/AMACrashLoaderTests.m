
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
@import KSCrash_Recording;
#import "AMAKSCrash.h"
#import "AMACrashLoader.h"
#import "AMAUnhandledCrashDetector.h"
#import "AMACrashReporter.h"
#import "AMACrashReportDecoder.h"
#import "AMADecodedCrash.h"
#import "AMACrashSafeTransactor.h"

@interface AMACrashLoader ()

- (void)handleCrashReports:(NSArray *)reportIDs;
- (void)decodeCrashReport:(id)crashReport withDecoder:(id)crashDecoder;

@end

@interface AMACrashLoader (Tests)

@property (nonatomic, strong) AMAUnhandledCrashDetector *unhandledCrashDetector;
@property (nonatomic, strong) NSMutableDictionary *decoders;

@property (nonatomic, assign) BOOL enabled;

+ (void)resetCrashContext;

@end

@implementation AMACrashLoader (Tests)

@dynamic unhandledCrashDetector;
@dynamic decoders;
@dynamic enabled;

+ (void)resetCrashContext
{
    [[AMAKSCrash sharedInstance] setUserInfo:nil];
}

@end

SPEC_BEGIN(AMACrashLoaderTests)

describe(@"AMACrashLoader", ^{
    context(@"Crash context", ^{
        beforeEach(^{
            [AMACrashLoader resetCrashContext];
        });
        NSDictionary *context = @{ @"a" : @"b" };
        it(@"Should set context", ^{
            [AMACrashLoader addCrashContext:context];
            NSDictionary *crashContext = [AMACrashLoader crashContext];
            [[crashContext should] equal:context];
        });
        it(@"Should set context to KSCrash userInfo", ^{
            [AMACrashLoader addCrashContext:context];
            [[[[AMAKSCrash sharedInstance] userInfo] should] equal:context];
        });
        it(@"Should return KSCrash userInfo as crash context", ^{
            [[AMAKSCrash sharedInstance] setUserInfo:context];
            [[[AMACrashLoader crashContext] should] equal:context];
        });
        it(@"Should not overwrite userInfo, but append context data", ^{
            NSDictionary *userInfo = @{ @"a" : @"b" };
            NSDictionary *crashContext = @{ @"c" : @"d" };
            [[AMAKSCrash sharedInstance] setUserInfo:userInfo];
            [AMACrashLoader addCrashContext:crashContext];
            NSMutableDictionary *resultDictionary = [userInfo mutableCopy];
            [resultDictionary addEntriesFromDictionary:crashContext];
            [[[[AMAKSCrash sharedInstance] userInfo] should] equal:resultDictionary];
        });
        it(@"Should not modify context if nil is passed", ^{
            NSDictionary *userInfo = @{ @"a" : @"b" };
            [[AMAKSCrash sharedInstance] setUserInfo:userInfo];
            [AMACrashLoader addCrashContext:nil];
            [[[[AMAKSCrash sharedInstance] userInfo] should] equal:userInfo];
        });
        it(@"Should overwrite with new values", ^{
            NSDictionary *userInfo = @{ @"a" : @"b", @"c" : @"d" };
            NSDictionary *crashContext = @{ @"c" : @"g" };
            [[AMAKSCrash sharedInstance] setUserInfo:userInfo];
            [AMACrashLoader addCrashContext:crashContext];
            NSDictionary *resultDictionary = @{ @"a" : @"b", @"c" : @"g" };
            [[[[AMAKSCrash sharedInstance] userInfo] should] equal:resultDictionary];
        });
    });
    context(@"Load crash reports", ^{
        KSCrash __block *ksCrash;
        AMAUnhandledCrashDetector __block *unhandledCrashDetector;
        AMACrashLoader __block *crashLoader;
        id __block crashLoaderDelegate;
        NSNumber *crashID = @23;

        beforeEach(^{
            ksCrash = [KSCrash nullMock];
            [AMAKSCrash stub:@selector(sharedInstance) andReturn:ksCrash];
            unhandledCrashDetector = [AMAUnhandledCrashDetector nullMock];
            crashLoader = [[AMACrashLoader alloc] initWithUnhandledCrashDetector:unhandledCrashDetector];
            crashLoaderDelegate = [KWMock nullMockForProtocol:@protocol(AMACrashLoaderDelegate)];
            crashLoader.delegate = crashLoaderDelegate;
            crashLoader.isUnhandledCrashDetectingEnabled = YES;
        });

        it(@"Should not use KSCrash sharedInstance", ^{
            [[KSCrash shouldNot] receive:@selector(sharedInstance)];
            [crashLoader loadCrashReports];
        });
    
        it(@"Should enable cxa_throw swap", ^{
            [[ksCrash should] receive:@selector(enableSwapOfCxaThrow)];
            [crashLoader enableSwapOfCxaThrow];
        });
    
        context(@"Crashed last launch", ^{
            context(@"Disabled", ^{
                beforeEach(^{
                    crashLoader.enabled = NO;
                });
                it(@"Should not call KSCrash", ^{
                    [[ksCrash shouldNot] receive:@selector(crashedLastLaunch)];
                    [crashLoader crashedLastLaunch];
                });
                it(@"Should return nil", ^{
                    [[crashLoader.crashedLastLaunch should] beNil];
                });
            });
            context(@"Enabled", ^{
                beforeEach(^{
                    crashLoader.enabled = YES;
                });
                it(@"Should return YES", ^{
                    [ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(YES)];
                    [[crashLoader.crashedLastLaunch should] equal:@YES];
                });
                it(@"Should return NO", ^{
                    [ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(NO)];
                    [[crashLoader.crashedLastLaunch should] equal:@NO];
                });
            });
        });
        
        context(@"ANR reporting", ^{
            
            it(@"Should call KSCrash", ^{
                [[ksCrash should] receive:@selector(reportUserException:
                                                    reason:
                                                    language:
                                                    lineOfCode:
                                                    stackTrace:
                                                    logAllThreads:
                                                    terminateProgram:)];
                [crashLoader reportANR];
            });
            
            it(@"Should decode ANR crash report", ^{
                NSNumber *expectedCrashID = @123;
                [ksCrash stub:@selector(reportIDs) andReturn:@[ expectedCrashID ]];
                AMACrashReportDecoder *decoder = [AMACrashReportDecoder nullMock];
                [AMACrashReportDecoder stub:@selector(alloc) andReturn:decoder];
                [[decoder should] receive:@selector(initWithCrashID:) withArguments:expectedCrashID];
                
                [crashLoader reportANR];
                
                [AMACrashReportDecoder clearStubs];
            });
            
            context(@"Should process decoded ANR", ^{
                __block AMADecodedCrash *crash = nil;
                AMACrashReportDecoder __block *decoder;

                beforeEach(^{
                    crash = [AMADecodedCrash nullMock];
                    decoder = [AMACrashReportDecoder nullMock];
                    [AMACrashReportDecoder stub:@selector(alloc) andReturn:decoder];
                });

                it(@"Should send to delegate", ^{
                    [decoder stub:@selector(crashID) andReturn:crashID];
                    [[crashLoaderDelegate should] receive:@selector(crashLoader:didLoadANR:withError:)];
                    [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                          didDecodeANR:crash
                                                                             withError:nil];
                });
                
                it(@"Should send to delegate if crashID is nil", ^{
                    [decoder stub:@selector(crashID) andReturn:nil];
                    [[crashLoaderDelegate should] receive:@selector(crashLoader:didLoadANR:withError:)];
                    [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                          didDecodeANR:crash
                                                                             withError:nil];
                });
                
                it(@"Should purge crash report", ^{
                    [decoder stub:@selector(crashID) andReturn:crashID];
                    [[ksCrash should] receive:@selector(deleteReportWithID:) withArguments:crashID];
                    [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                          didDecodeANR:crash
                                                                             withError:nil];
                });
            });
        });
        
        context(@"Should detect unhandled crashes", ^{

            AMAUnhandledCrashCallback (^getUnhandledCrashCallback)(void) = ^{
                KWCaptureSpy *spy =
                    [unhandledCrashDetector captureArgument:@selector(checkUnhandledCrash:) atIndex:0];
                [crashLoader loadCrashReports];
                AMAUnhandledCrashCallback callback = spy.argument;
                return callback;
            };

            beforeEach(^{
                [ksCrash stub:@selector(reportIDs) andReturn:[NSArray array]];
                [ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(NO)];
            });

            it(@"Should start detecting unhandled crashes on enable crash loading", ^{
                [[unhandledCrashDetector should] receive:@selector(startDetecting)];
                [crashLoader enableCrashLoader];
            });

            it(@"Should check unhandled crashes if not exists crashes for previous launch and probably "
                   "unhandled crash detecting enabled", ^{
                [[unhandledCrashDetector should] receive:@selector(checkUnhandledCrash:)];
                [crashLoader loadCrashReports];
            });

            it(@"Should not check unhandled crashes if exists crashes for previous launch", ^{
                [ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(YES)];
                [[unhandledCrashDetector shouldNot] receive:@selector(checkUnhandledCrash:)];
                [crashLoader loadCrashReports];
            });

            it(@"Should not check unhandled crashes if probably unhandled crash detecting is disabled", ^{
                crashLoader.isUnhandledCrashDetectingEnabled = NO;
                [[unhandledCrashDetector shouldNot] receive:@selector(checkUnhandledCrash:)];
                [crashLoader loadCrashReports];
            });

            it(@"Should dispatch unhandled crashes info to delegate", ^{
                [[crashLoaderDelegate should] receive:@selector(crashLoader:didDetectProbableUnhandledCrash:)];
                AMAUnhandledCrashCallback callback = getUnhandledCrashCallback();
                callback(AMAUnhandledCrashBackground);
            });

            context(@"Should dispatch to delegate unhandled crash type", ^{
                KWCaptureSpy __block *blockArgumentSpy;
                AMAUnhandledCrashCallback __block callback;

                beforeEach(^{
                    blockArgumentSpy =
                        [crashLoaderDelegate captureArgument:@selector(crashLoader:didDetectProbableUnhandledCrash:)
                                                     atIndex:1];
                    callback = getUnhandledCrashCallback();
                });

                it(@"If foreground", ^{
                    callback(AMAUnhandledCrashForeground);
                    [[blockArgumentSpy.argument should] equal:theValue(AMAUnhandledCrashForeground)];
                });

                it(@"If background", ^{
                    callback(AMAUnhandledCrashBackground);
                    [[blockArgumentSpy.argument should] equal:theValue(AMAUnhandledCrashBackground)];
                });

                it(@"If unknown", ^{
                    callback(AMAUnhandledCrashUnknown);
                    [[blockArgumentSpy.argument should] equal:theValue(AMAUnhandledCrashUnknown)];
                });
            });
        });
        context(@"Should process decoded crash", ^{
            __block AMADecodedCrash *crash = nil;
            AMACrashReportDecoder __block *decoder;

            beforeEach(^{
                crash = [AMADecodedCrash nullMock];
                decoder = [AMACrashReportDecoder nullMock];
                [AMACrashReportDecoder stub:@selector(alloc) andReturn:decoder];
            });

            it(@"Should send to delegate", ^{
                [decoder stub:@selector(crashID) andReturn:crashID];
                [[crashLoaderDelegate should] receive:@selector(crashLoader:didLoadCrash:withError:)];
                [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                    didDecodeCrash:crash
                                                                         withError:nil];
            });

            it(@"Should send to delegate if crashID is nil", ^{
                [decoder stub:@selector(crashID) andReturn:nil];
                [[crashLoaderDelegate should] receive:@selector(crashLoader:didLoadCrash:withError:)];
                [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                    didDecodeCrash:crash
                                                                         withError:nil];
            });

            it(@"Should purge crash report", ^{
                [decoder stub:@selector(crashID) andReturn:crashID];
                [[ksCrash should] receive:@selector(deleteReportWithID:) withArguments:crashID];
                [(id<AMACrashReportDecoderDelegate>)crashLoader crashReportDecoder:decoder
                                                                    didDecodeCrash:crash
                                                                         withError:nil];
            });
        });

        context(@"Should handle crash if crash report not found", ^{
            __block AMATestAssertionHandler *handler = nil;

            beforeEach(^{
                handler = [AMATestAssertionHandler new];
                [handler beginAssertIgnoring];

                [ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(YES)];
                [ksCrash stub:@selector(deleteReportWithID:) withArguments:crashID];
                [ksCrash stub:@selector(reportIDs) andReturn:@[ crashID ]];
                [ksCrash stub:@selector(reportWithID:) andReturn:nil];
            });

            afterEach(^{
                [handler endAssertIgnoring];
            });

            it(@"Should remove report decoder", ^{
                [crashLoader loadCrashReports];
                [[crashLoader.decoders should] beEmpty];
            });

            it(@"Should send to delegate", ^{
                [[crashLoaderDelegate should] receive:@selector(crashLoader:didLoadCrash:withError:)];
                [crashLoader loadCrashReports];
            });

            it(@"Should purge crash report", ^{
                [[ksCrash should] receive:@selector(deleteReportWithID:) withArguments:crashID];
                [crashLoader loadCrashReports];
            });
        });

        context(@"Crash safety", ^{

            dispatch_block_t __block transaction;
            AMACrashSafeTransactorRollbackBlock __block rollback;

            beforeEach(^{
                transaction = nil;
                rollback = nil;

                SEL selector = @selector(processTransactionWithID:name:rollbackContext:transaction:rollback:);
                [AMACrashSafeTransactor stub:selector withBlock:^id(NSArray *params) {
                    transaction = params[3];
                    rollback = params[4];

                    return nil;
                }];
            });

            context(@"Crash report IDs loading", ^{

                beforeEach(^{
                    [ksCrash stub:@selector(reportIDs)];
                    [ksCrash stub:@selector(deleteAllReports)];
                });

                it(@"Should load crash IDs within transaction", ^{
                    [crashLoader loadCrashReports];
                    [[ksCrash should] receive:@selector(reportIDs)];
                    transaction();
                });

                it(@"Should remove crashes within rollback", ^{
                    [crashLoader loadCrashReports];
                    [[ksCrash should] receive:@selector(deleteAllReports)];
                    rollback(@"context");
                });

                it(@"Should not call crash IDs loading outside of transaction", ^{
                    [[ksCrash shouldNot] receive:@selector(reportIDs)];
                    [crashLoader loadCrashReports];
                });
            });

            context(@"Crash report loading", ^{

                NSArray *const reportIDs = @[ crashID ];

                beforeEach(^{
                    [ksCrash stub:@selector(reportWithID:)];
                    [ksCrash stub:@selector(deleteReportWithID:)];
                });

                it(@"Should load crash within transaction", ^{
                    [crashLoader handleCrashReports:reportIDs];
                    [[crashLoader should] receive:@selector(decodeCrashReport:withDecoder:)];
                    transaction();
                });

                it(@"Should remove crashes within rollback", ^{
                    [crashLoader handleCrashReports:reportIDs];
                    [[ksCrash should] receive:@selector(deleteAllReports)];
                    rollback(@"context");
                });

                it(@"Should not call crash loading outside of transaction", ^{
                    [[ksCrash shouldNot] receive:@selector(reportWithID:)];
                    [crashLoader handleCrashReports:reportIDs];
                });
            });
            
        });
    });
});

SPEC_END
