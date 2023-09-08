
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAFullDataTruncatorTests)

describe(@"AMAFullDataTruncator", ^{

    NSUInteger maxLength = 7;

    NSData *__block data = nil;
    AMAFullDataTruncator *__block truncator = nil;

    beforeEach(^{
        truncator = [[AMAFullDataTruncator alloc] initWithMaxLength:maxLength];
    });

    NSData *(^dataForString)(NSString *) = ^(NSString *string) {
        return [string dataUsingEncoding:NSUTF8StringEncoding];
    };
    NSData *(^truncatedData)(void) = ^{
        return [truncator truncatedData:data onTruncation:nil];
    };
    NSNumber *(^bytesTruncated)(void) = ^{
        NSNumber *__block count = nil;
        [truncator truncatedData:data onTruncation:^(NSUInteger bytesTruncated) {
            count = @(bytesTruncated);
        }];
        return count;
    };

    context(@"Nil", ^{
        beforeEach(^{
            data = nil;
        });
        it(@"Should return nil", ^{
            [[truncatedData() should] beNil];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] beNil];
        });
    });
    context(@"Empty data", ^{
        beforeEach(^{
            data = [NSData data];
        });
        it(@"Should return same data", ^{
            [[truncatedData() should] equal:data];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] beNil];
        });
    });
    context(@"Short data", ^{
        beforeEach(^{
            data = dataForString(@"1234567");
        });
        it(@"Should return same data", ^{
            [[truncatedData() should] equal:data];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] beNil];
        });
    });
    context(@"Long data", ^{
        beforeEach(^{
            data = dataForString(@"123456789");
        });
        it(@"Should return same data", ^{
            [[truncatedData() should] beNil];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] equal:@(data.length)];
        });
    });

});

SPEC_END

