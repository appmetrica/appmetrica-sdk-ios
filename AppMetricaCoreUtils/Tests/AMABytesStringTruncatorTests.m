
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMABytesStringTruncatorTests)

describe(@"AMABytesStringTruncator", ^{

    /* UTF-8 characters:
     *  ¢ - 2 bytes
     *  € - 3 bytes
     *  Я - 2 bytes
     */

    NSUInteger const maxLength = 7;

    NSString *__block string = nil;
    AMABytesStringTruncator *__block truncator = nil;

    beforeEach(^{
        truncator = [[AMABytesStringTruncator alloc] initWithMaxBytesLength:maxLength];
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
                string = @"12¢€";
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
                string = @"1234¢€";
            });
            it(@"Should return same string", ^{
                [[truncatedString() should] equal:@"1234¢"];
            });
            it(@"Should not call onTruncation block", ^{
                [[bytesTruncated() should] equal:@3];
            });
        });
        context(@"Character truncation", ^{
            /* Input: @"12345678\u042F\u042F\u042F" == @"12345678ЯЯЯ"
             *   \u042F is Unicode escape for Cyrillic "Я" (2 bytes in UTF-8: 0xD0 0xAF)
             *
             * Byte layout:
             *   "12345678"  ->  8 bytes
             *   "Я"         ->  2 bytes  (fits completely)
             *   "Я"         ->  2 bytes  (only 0xD0 would fit into limit 11, so it is dropped)
             *   "Я"         ->  not included
             *
             * We verify that AMABytesStringTruncator does not split "Я" in the middle:
             * result must be @"12345678Я" (10 bytes), not a broken UTF-8 sequence.
             */
            beforeEach(^{
                truncator = [[AMABytesStringTruncator alloc] initWithMaxBytesLength:11];
                string = @"12345678\u042F\u042F\u042F";
            });
            it(@"Should truncate on whole character boundary", ^{
                [[truncatedString() should] equal:@"12345678\u042F"];
                [[bytesTruncated() should] equal:@4];
            });
        });
    });
    
    it(@"Should comform to AMAStringTruncating", ^{
        [[truncator should] conformToProtocol:@protocol(AMAStringTruncating)];
    });
});

SPEC_END
