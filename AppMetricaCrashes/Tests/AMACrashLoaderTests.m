#import <Kiwi/Kiwi.h>

#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <KSCrashReport.h>

#import "AMACrashLoader.h"

#import "AMACrashReportDecoder.h"
#import "AMACrashSafeTransactor.h"
#import "AMAAppMetricaCrashes.h"
#import "AMADecodedCrash.h"
#import "AMAUnhandledCrashDetector.h"

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
    [[KSCrash sharedInstance] setUserInfo:nil];
}

@end

SPEC_BEGIN(AMACrashLoaderTests)

describe(@"AMACrashLoader", ^{
    
    __block AMACrashSafeTransactor *transactor = nil;
    
    beforeEach(^{
        transactor = [AMACrashSafeTransactor mock];
        
        [transactor stub:@selector(processTransactionWithID:name:transaction:)
               withBlock:^id(NSArray *params) {
            dispatch_block_t block = params[2];
            block();
            return nil;
        }];
        
        [transactor stub:@selector(processTransactionWithID:name:transaction:rollback:)
               withBlock:^id(NSArray *params) {
            dispatch_block_t block = params[2];
            block();
            return nil;
        }];
        
        [transactor stub:@selector(processTransactionWithID:name:rollbackContext:transaction:rollback:)
               withBlock:^id(NSArray *params) {
            dispatch_block_t block = params[3];
            block();
            return nil;
        }];
    });
    
    context(@"Crash context", ^{
        __block KSCrash *mockKSCrash;

        beforeEach(^{
            mockKSCrash = [KSCrash mock];
            [KSCrash stub:@selector(sharedInstance) andReturn:mockKSCrash];
        });

        NSDictionary *context = @{ @"a" : @"b" };

        it(@"Should set context", ^{
            [mockKSCrash stub:@selector(userInfo)];
            [[mockKSCrash should] receive:@selector(setUserInfo:) withArguments:context];
            [AMACrashLoader addCrashContext:context];

            [mockKSCrash stub:@selector(userInfo) andReturn:context];
            NSDictionary *crashContext = [AMACrashLoader crashContext];
            [[crashContext should] equal:context];
        });

        it(@"Should set context to KSCrash userInfo", ^{
            [mockKSCrash stub:@selector(userInfo)];
            [mockKSCrash stub:@selector(setUserInfo:)];
            [[mockKSCrash should] receive:@selector(setUserInfo:) withArguments:context];
            [AMACrashLoader addCrashContext:context];
        });

        it(@"Should return KSCrash userInfo as crash context", ^{
            [mockKSCrash stub:@selector(userInfo) andReturn:context];
            [[[AMACrashLoader crashContext] should] equal:context];
        });

        it(@"Should not overwrite userInfo, but append context data", ^{
            NSDictionary *userInfo = @{ @"a" : @"b" };
            NSDictionary *crashContext = @{ @"c" : @"d" };
            [mockKSCrash stub:@selector(userInfo) andReturn:userInfo];

            NSMutableDictionary *resultDictionary = [userInfo mutableCopy];
            [resultDictionary addEntriesFromDictionary:crashContext];

            [[mockKSCrash should] receive:@selector(setUserInfo:) withArguments:resultDictionary];

            [AMACrashLoader addCrashContext:crashContext];
        });

        it(@"Should not modify context if nil is passed", ^{
            [[mockKSCrash shouldNot] receive:@selector(setUserInfo:)];
            [AMACrashLoader addCrashContext:nil];
        });

        it(@"Should overwrite with new values", ^{
            NSDictionary *userInfo = @{ @"a" : @"b", @"c" : @"d" };
            NSDictionary *crashContext = @{ @"c" : @"g" };
            [mockKSCrash stub:@selector(userInfo) andReturn:userInfo];

            NSDictionary *resultDictionary = @{ @"a" : @"b", @"c" : @"g" };

            [[mockKSCrash should] receive:@selector(setUserInfo:) withArguments:resultDictionary];

            [AMACrashLoader addCrashContext:crashContext];
        });
    });
    context(@"Synchronous Load Crash Reports", ^{
        let(unhandledCrashDetector, ^{ return [AMAUnhandledCrashDetector nullMock]; });
        let(crashLoaderDelegate, ^{ return [KWMock nullMockForProtocol:@protocol(AMACrashLoaderDelegate)]; });
        let(crashReports, ^{ return @[ [AMADecodedCrash nullMock], [AMADecodedCrash nullMock] ]; });
        let(reportStore, ^{ return [KSCrashReportStore nullMock]; });
        let(ksCrash, ^{
            KSCrash *mock = [KSCrash nullMock];
            [mock stub:@selector(reportStore) andReturn:reportStore];
            [KSCrash stub:@selector(sharedInstance) andReturn:mock];

            return mock;
        });
        let(crashLoader, ^{
            AMACrashLoader *loader = [[AMACrashLoader alloc] initWithUnhandledCrashDetector:unhandledCrashDetector
                                                                                 transactor:transactor];
            loader.delegate = crashLoaderDelegate;
            return loader;
        });
        
        NSNumber *const crashID = @23;
        NSArray *const crashIDs = @[crashID];
      
        it(@"Should return decoded crash reports", ^{
            [reportStore stub:@selector(reportIDs) andReturn:crashIDs];
            AMACrashReportDecoder *decoder = [AMACrashReportDecoder nullMock];
            [AMACrashReportDecoder stub:@selector(alloc) andReturn:decoder];
            [decoder stub:@selector(initWithCrashID:) andReturn:decoder];
            [decoder stub:@selector(decode:) withBlock:^id(NSArray *params) {
                for (AMADecodedCrash *crash in crashReports) {
                    [crashLoader crashReportDecoder:decoder didDecodeCrash:crash withError:nil];
                }
                return nil;
            }];
            
            NSArray *result = [crashLoader syncLoadCrashReports];
            
            [[result should] equal:crashReports];
        });

        it(@"Should handle decoding errors gracefully", ^{
            [ksCrash stub:@selector(reportIDs) andReturn:crashIDs];
            AMACrashReportDecoder *decoder = [AMACrashReportDecoder nullMock];
            [AMACrashReportDecoder stub:@selector(alloc) andReturn:decoder];
            [decoder stub:@selector(initWithCrashID:) andReturn:decoder];
            
            NSError *error = [NSError errorWithDomain:@"TestDomain" code:400 userInfo:nil];
            [decoder stub:@selector(decode:) withBlock:^id(NSArray *params) {
                [crashLoader crashReportDecoder:decoder didDecodeCrash:nil withError:error];
                return nil;
            }];
            
            NSArray *result = [crashLoader syncLoadCrashReports];
            
            [[result should] beEmpty];
        });
        
        it(@"Should return an empty array if no reports are available", ^{
            [ksCrash stub:@selector(reportIDs) andReturn:@[]];
            
            NSArray *result = [crashLoader syncLoadCrashReports];
            
            [[result should] beEmpty];
        });
        
        it(@"Should purge successfully processed reports", ^{
            [reportStore stub:@selector(reportIDs)andReturn:crashIDs times:@1 afterThatReturn:@[]]; // Simulating deletion
            [[reportStore should] receive:@selector(deleteReportWithID:)
                            withArguments:theValue(crashID.integerValue)];

            [crashLoader syncLoadCrashReports];
        });
    });
    context(@"Load crash reports", ^{
        KSCrash __block *ksCrash;
        KSCrashReportStore __block *reportStore;
        AMAUnhandledCrashDetector __block *unhandledCrashDetector;
        AMACrashLoader __block *crashLoader;
        id __block crashLoaderDelegate;
        NSNumber *crashID = @23;
        
        beforeEach(^{
            reportStore = [KSCrashReportStore nullMock];
            ksCrash = [KSCrash nullMock];
            [KSCrash stub:@selector(sharedInstance) andReturn:ksCrash];
            [ksCrash stub:@selector(reportStore) andReturn:reportStore];
            unhandledCrashDetector = [AMAUnhandledCrashDetector nullMock];
            crashLoader = [[AMACrashLoader alloc] initWithUnhandledCrashDetector:unhandledCrashDetector
                                                                      transactor:transactor];
            crashLoaderDelegate = [KWMock nullMockForProtocol:@protocol(AMACrashLoaderDelegate)];
            crashLoader.delegate = crashLoaderDelegate;
            crashLoader.isUnhandledCrashDetectingEnabled = YES;
        });


        it(@"Should set correct required monitoring in KSCrash", ^{
            KWCaptureSpy *configSpy = [ksCrash captureArgument:@selector(installWithConfiguration:error:) atIndex:0];

            [ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(YES)];

            [[ksCrash should] receive:@selector(installWithConfiguration:error:)];
            
            [crashLoader enableRequiredMonitoring];

            KSCrashConfiguration *capturedConfig = configSpy.argument;
            [[theValue(capturedConfig.monitors) should] equal:theValue(KSCrashMonitorTypeRequired)];

            [[theValue(capturedConfig.enableMemoryIntrospection) should] equal:theValue(NO)];
            [[theValue(capturedConfig.enableQueueNameSearch) should] equal:theValue(NO)];
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
                [reportStore stub:@selector(reportIDs) andReturn:@[ expectedCrashID ]];
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
                    [[reportStore should] receive:@selector(deleteReportWithID:)
                                    withArguments:theValue(crashID.integerValue)];
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
                [[reportStore should] receive:@selector(deleteReportWithID:)
                                withArguments:theValue(crashID.integerValue)];
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
                [reportStore stub:@selector(deleteReportWithID:) withArguments:crashID];
                [reportStore stub:@selector(reportIDs) andReturn:@[ crashID ]];
                [reportStore stub:@selector(reportForID:) andReturn:nil];
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
                [[reportStore should] receive:@selector(deleteReportWithID:)
                                withArguments:theValue(crashID.integerValue)];
                [crashLoader loadCrashReports];
            });
        });

        context(@"Crash safety", ^{

            __block dispatch_block_t transaction;
            __block AMACrashSafeTransactorRollbackBlock rollback;

            beforeEach(^{
                transaction = nil;
                rollback = nil;

                [transactor stub:@selector(processTransactionWithID:name:rollbackContext:transaction:rollback:)
                       withBlock:^id(NSArray *params) {
                    transaction = params[3];
                    rollback = params[4];

                    return nil;
                }];
                [transactor stub:@selector(processTransactionWithID:name:transaction:rollback:)
                       withBlock:^id(NSArray *params) {
                    transaction = params[2];
                    rollback = params[3];
                    
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
                    [[reportStore should] receive:@selector(reportIDs)];
                    transaction();
                });

                it(@"Should remove crashes within rollback", ^{
                    [crashLoader loadCrashReports];
                    [[reportStore should] receive:@selector(deleteAllReports)];
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
                    [ksCrash stub:@selector(reportForID:)];
                    [ksCrash stub:@selector(deleteReportWithID:)];
                });

                it(@"Should remove last crash within rollback", ^{
                    [crashLoader handleCrashReports:reportIDs];
                    [[reportStore should] receive:@selector(deleteReportWithID:) withArguments:theValue(crashID.integerValue)];
                    rollback(@"context");
                });

                it(@"Should not call crash loading outside of transaction", ^{
                    [[ksCrash shouldNot] receive:@selector(reportForID:)];
                    [crashLoader handleCrashReports:reportIDs];
                });
            });

            context(@"Crash report IDs loading", ^{
                NSArray *const reportIDs = @[ crashID ];
                
                beforeEach(^{
                    [ksCrash stub:@selector(reportIDs)];
                    [ksCrash stub:@selector(deleteAllReports)];
                });
                
                it(@"Should receive report transaction name with report ID", ^{
                    NSString *const transactionName = [NSString stringWithFormat:@"ReportWithID_%lld", crashID.longLongValue];
                    
                    [[transactor should] receive:@selector(processTransactionWithID:name:transaction:rollback:)
                                   withArguments:kw_any(), transactionName, kw_any(), kw_any()];
                    
                    [crashLoader handleCrashReports:reportIDs];
                });
                
                it(@"Should receive decode transaction name with report ID", ^{
                    NSString *const transactionName = [NSString stringWithFormat:@"DecodeReport_%lld",
                                                       crashID.longLongValue];
                    
                    [[transactor should] receive:@selector(processTransactionWithID:name:rollbackContext:transaction:rollback:)
                                   withArguments:kw_any(), transactionName, kw_any(), kw_any(), kw_any()];
                    
                    [crashLoader handleCrashReports:reportIDs];
                });
            });
            
        });
    });
});

SPEC_END
