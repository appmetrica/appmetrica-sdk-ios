
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAArrayIteratorTests)

describe(@"AMAArrayIterator", ^{
    NSArray * __block items1 = nil;
    AMAArrayIterator * __block iterator = nil;

    beforeAll(^{
        items1 = @[@"1", @"2", @"3"];
    });

    it(@"Initial iteration cycle check", ^{
        BOOL result = NO;

        iterator = [[AMAArrayIterator alloc] initWithArray:items1];
        result = [[iterator current] isEqualToString:@"1"];
        result = result && [[iterator next] isEqualToString:@"2"];
        result = result && [[iterator next] isEqualToString:@"3"];
        result = result && [iterator next] == nil;

        [[theValue(result) should] beYes];
    });

    it(@"Out of bounds check", ^{
        iterator = [[AMAArrayIterator alloc] initWithArray:items1];

        for (NSUInteger i = 0; i < items1.count + 5; i ++) {
            [iterator next];
        }

        id result = [iterator next];
        [[result should] beNil];
    });
});

SPEC_END
