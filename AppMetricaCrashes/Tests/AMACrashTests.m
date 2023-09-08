#import <Kiwi/Kiwi.h>
#import "AMACrash+Extended.h"

SPEC_BEGIN(AMACrashTests)

    describe(@"AMACrash", ^{
        context(@"AMACrash initialization", ^{

            AMACrash __block *crash;
            NSData *stackTrace = [@"test stack trace" dataUsingEncoding:NSUTF8StringEncoding];
            NSDate *date = [NSDate date];
            NSDictionary *errorEnvironment = { @{ @"test error environment key" : @"test error evironment value" } };

            context(@"AMACrash initialization via public api", ^{
                beforeEach(^{
                    crash = [AMACrash crashWithRawData:stackTrace
                                                  date:date
                                      errorEnvironment:errorEnvironment];
                });
                it(@"Should return stack trace from initialization", ^{
                    [[crash.rawData should] equal:stackTrace];
                });
                it(@"Should return date from initialization", ^{
                    [[crash.date should] equal:date];
                });
                it(@"Should return error environment from initialization", ^{
                    [[crash.errorEnvironment should] equal:errorEnvironment];
                });
                it(@"Should return nil app environment", ^{
                    [[crash.appEnvironment should] beNil];
                });
            });
            context(@"AMACrash initalization via extended api", ^{
                NSDictionary *appEnvironment = { @{ @"test environment key" : @"test environment value" } };
                beforeEach(^{
                    crash = [AMACrash crashWithRawData:stackTrace
                                                  date:date
                                      errorEnvironment:errorEnvironment
                                        appEnvironment:appEnvironment];
                });
                it(@"Should return stack trace", ^{
                    [[crash.rawData should] equal:stackTrace];
                });
                it(@"Should return date from initialization", ^{
                    [[crash.date should] equal:date];
                });
                it(@"Should return error environment from initialization", ^{
                    [[crash.errorEnvironment should] equal:errorEnvironment];
                });
                it(@"Should return app environment from initialization", ^{
                    [[crash.appEnvironment should] equal:appEnvironment];
                });
            });
        });
    });

SPEC_END
