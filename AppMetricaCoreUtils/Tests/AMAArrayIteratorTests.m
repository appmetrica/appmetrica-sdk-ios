
#import <AppMetricaKiwi/AppMetricaKiwi.h>
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
    
    it(@"Reset iterator", ^{
        BOOL result = NO;
        iterator = [[AMAArrayIterator alloc] initWithArray:items1];
        
        [iterator next];
        [[iterator.current should] equal: @"2"];
        
        [iterator reset];
        [[iterator.current should] equal: @"1"];
    });

    it(@"Out of bounds check", ^{
        iterator = [[AMAArrayIterator alloc] initWithArray:items1];

        for (NSUInteger i = 0; i < items1.count + 5; i ++) {
            [iterator next];
        }

        id result = [iterator next];
        [[result should] beNil];
    });
    
    it(@"Should comform to AMAIterable", ^{
        [[iterator should] conformToProtocol:@protocol(AMAIterable)];
    });
    
    it(@"Should comform to AMAResettableIterable", ^{
        [[iterator should] conformToProtocol:@protocol(AMAResettableIterable)];
    });
});

SPEC_END
