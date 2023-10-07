#import <Kiwi/Kiwi.h>
#import "AMAEventTypeResolver.h"

SPEC_BEGIN(AMAEventTypeResolverTests)

describe(@"AMAEventTypeResolver", ^{
    context(@"Reserved", ^{
        it(@"Should return YES if event type is 1", ^{
            BOOL result = [AMAEventTypeResolver isEventTypeReserved:1];
            [[theValue(result) should] beYes];
        });
        it(@"Should return YES if event type is 13", ^{
            BOOL result = [AMAEventTypeResolver isEventTypeReserved:13];
            [[theValue(result) should] beYes];
        });
    });
    context(@"Allowed", ^{
        it(@"Should return NO if event type between 2 and 12", ^{
            NSUInteger between2_12Type = arc4random_uniform((uint32_t)11) + 2;
            
            BOOL result = [AMAEventTypeResolver isEventTypeReserved:between2_12Type];
            [[theValue(result) should] beNo];
        });
        it(@"Should return NO if event type above 13", ^{
            NSUInteger above13Type = arc4random_uniform((uint32_t)999) + 14;
            
            BOOL result = [AMAEventTypeResolver isEventTypeReserved:above13Type];
            [[theValue(result) should] beNo];
        });
    });
});

SPEC_END

