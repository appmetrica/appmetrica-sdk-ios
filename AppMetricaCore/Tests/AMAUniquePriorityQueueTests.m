
#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import "AMAUniquePriorityQueue.h"

SPEC_BEGIN(AMAUniquePriorityQueueTest)

describe(@"AMAUniquePriorityQueue", ^{
         
    AMAUniquePriorityQueue *__block testQueue = nil;

    beforeEach(^{
        testQueue = [[AMAUniquePriorityQueue alloc] init];
    });

    context(@"Pushing object", ^{
       
        KWMock *const testObject = [KWMock mock];
        const BOOL testPrioritization = NO;
    
        beforeEach(^{
            [testQueue push:testObject prioritized:testPrioritization];
        });
        
        it(@"Should pop object", ^{
            NSObject *object = [testQueue popPrioritized:NULL];
            [[object should] equal:testObject];
        });
        it(@"Should peek object", ^{
            NSObject *object = [testQueue peekPrioritized:NULL];
            [[object should] equal:testObject];
        });
        it(@"Should pop object with right prioritization", ^{
            BOOL isPrioritized = YES;
            [testQueue popPrioritized:&isPrioritized];
            [[theValue(isPrioritized) should] equal:theValue(testPrioritization)];
        });
        it(@"Should have the correct quantity of objects", ^{
            [[theValue(testQueue.count) should] equal:theValue(1)];
        });
        it(@"Should not change the number of objects if the existing object was pushed", ^{
            NSUInteger expectedCount = testQueue.count;
            [testQueue push:testObject prioritized:testPrioritization];
            [[theValue(testQueue.count) should] equal:theValue(expectedCount)];
        });
        it(@"Should not change the number of objects if the existing object was pushed with another prioritization", ^{
            NSUInteger expectedCount = testQueue.count;
            [testQueue push:testObject prioritized:!testPrioritization];
            [[theValue(testQueue.count) should] equal:theValue(expectedCount)];
        });
        it(@"Should change prioritization to high if the existing object was pushed with high prioritization", ^{
            [testQueue push:testObject prioritized:YES];
            BOOL isPrioritized = NO;
            [testQueue popPrioritized:&isPrioritized];
            [[theValue(isPrioritized) should] equal:theValue(YES)];
        });
        it(@"Should pop highly prioritized object first", ^{
            KWMock *expectedObject = [KWMock mock];
            [testQueue push:[KWMock mock] prioritized:NO];
            [testQueue push:expectedObject prioritized:YES];
            
            NSObject *object = [testQueue popPrioritized:NULL];
            [[object should] equal:expectedObject];
        });
    });
});

SPEC_END
