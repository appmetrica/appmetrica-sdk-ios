
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAPermissiveTruncatorTests)

describe(@"AMAPermissiveTruncator", ^{

    AMAPermissiveTruncator *__block truncator = nil;

    beforeEach(^{
        truncator = [[AMAPermissiveTruncator alloc] init];
    });

    context(@"String", ^{
        NSString *const string = @"STRING";

        it(@"Should return same string", ^{
            [[[truncator truncatedString:string onTruncation:nil] should] equal:string];
        });
        it(@"Should not call onTruncation block", ^{
            BOOL __block called = NO;
            [truncator truncatedString:string onTruncation:^(NSUInteger bytesTruncated) {
                called = YES;
            }];
            [[theValue(called) should] beNo];
        });
    });
    context(@"Data", ^{
        NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];

        it(@"Should return same string", ^{
            [[[truncator truncatedData:data onTruncation:nil] should] equal:data];
        });
        it(@"Should not call onTruncation block", ^{
            BOOL __block called = NO;
            [truncator truncatedData:data onTruncation:^(NSUInteger bytesTruncated) {
                called = YES;
            }];
            [[theValue(called) should] beNo];
        });
    });

});

SPEC_END
