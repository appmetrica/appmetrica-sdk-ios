
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMABytesStringTruncatorTests)

describe(@"AMABytesStringTruncator", ^{

    /* UTF-8 characters:
     *  ¢ - 2 bytes
     *  € - 3 bytes
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
    });
    
    it(@"Should comform to AMAStringTruncating", ^{
        [[truncator should] conformToProtocol:@protocol(AMAStringTruncating)];
    });
});

SPEC_END
