
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

#define ONE_BYTE_SYMBOL "$"
#define TWO_BYTES_SYMBOL "¢"
#define THREE_BYTES_SYMBOL "€"

SPEC_BEGIN(AMALengthStringTruncatorTests)

describe(@"AMALengthStringTruncator", ^{

    /* UTF-8 characters:
     *  ¢ - 2 bytes
     *  € - 3 bytes
     */

    NSUInteger const maxLength = 7;

    NSString *__block string = nil;
    AMALengthStringTruncator *__block truncator = nil;

    beforeEach(^{
        truncator = [[AMALengthStringTruncator alloc] initWithMaxLength:maxLength];
    });

    NSString *(^truncatedString)(void) = ^{
        return [truncator truncatedString:string onTruncation:nil];
    };
    NSNumber *(^bytesTruncated)(void) = ^{
        NSNumber *__block count = nil;
        [truncator truncatedString:string onTruncation:^(NSUInteger bytesTruncated) {
            count = @(bytesTruncated);
        }];
        return count;
    };

    context(@"Nil", ^{
        beforeEach(^{
            string = nil;
        });
        it(@"Should return nil", ^{
            [[truncatedString() should] beNil];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] beNil];
        });
    });
    context(@"Empty string", ^{
        beforeEach(^{
            string = @"";
        });
        it(@"Should return same string", ^{
            [[truncatedString() should] equal:string];
        });
        it(@"Should not call onTruncation block", ^{
            [[bytesTruncated() should] beNil];
        });
    });
    context(@"Short string", ^{
        context(@"Simple", ^{
            beforeEach(^{
                string = @"1234567";
            });
            it(@"Should return same string", ^{
                [[truncatedString() should] equal:string];
            });
            it(@"Should not call onTruncation block", ^{
                [[bytesTruncated() should] beNil];
            });
        });
        context(@"Unicode", ^{
            beforeEach(^{
                string = @"123456€";
            });
            it(@"Should return same string", ^{
                [[truncatedString() should] equal:string];
            });
            it(@"Should not call onTruncation block", ^{
                [[bytesTruncated() should] beNil];
            });
        });
    });
    context(@"Long string", ^{
        context(@"Simple", ^{
            beforeEach(^{
                string = @"123456789";
            });
            it(@"Should return same string", ^{
                [[truncatedString() should] equal:@"1234567"];
            });
            it(@"Should not call onTruncation block", ^{
                [[bytesTruncated() should] equal:@2];
            });
        });
        context(@"Unicode", ^{
            beforeEach(^{
                string = @"1234567€¢";
            });
            it(@"Should return same string", ^{
                [[truncatedString() should] equal:@"1234567"];
            });
            it(@"Should not call onTruncation block", ^{
                [[bytesTruncated() should] equal:@5];
            });
        });
    });
    
    it(@"Should comform to AMAStringTruncating", ^{
        [[truncator should] conformToProtocol:@protocol(AMAStringTruncating)];
    });
});

SPEC_END

