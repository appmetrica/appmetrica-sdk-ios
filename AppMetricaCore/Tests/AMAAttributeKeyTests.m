
#import <Kiwi/Kiwi.h>
#import "AMAAttributeKey.h"

SPEC_BEGIN(AMAAttributeKeyTests)

describe(@"AMAAttributeKey", ^{

    NSString *const name = @"NAME";
    AMAAttributeType const type = AMAAttributeTypeCounter;

    AMAAttributeKey *__block key = nil;
    AMAAttributeKey *__block otherKey = nil;

    beforeEach(^{
        key = [[AMAAttributeKey alloc] initWithName:name type:type];
    });

    it(@"Should store name", ^{
        [[key.name should] equal:name];
    });
    it(@"Should store type", ^{
        [[theValue(key.type) should] equal:theValue(type)];
    });
    context(@"Same instances", ^{
        beforeEach(^{
            otherKey = key;
        });
        it(@"Should have same hash", ^{
            [[theValue(key.hash) should] equal:theValue(otherKey.hash)];
        });
        it(@"Should equal", ^{
            [[key should] equal:otherKey];
        });
    });
    context(@"Equal instances", ^{
        beforeEach(^{
            otherKey = [[AMAAttributeKey alloc] initWithName:name type:type];
        });
        it(@"Should have same hash", ^{
            [[theValue(key.hash) should] equal:theValue(otherKey.hash)];
        });
        it(@"Should equal", ^{
            [[key should] equal:otherKey];
        });
    });
    context(@"Different names", ^{
        beforeEach(^{
            otherKey = [[AMAAttributeKey alloc] initWithName:@"OTHER NAME" type:type];
        });
        it(@"Should have different hashes", ^{
            [[theValue(key.hash) shouldNot] equal:theValue(otherKey.hash)];
        });
        it(@"Should not equal", ^{
            [[key shouldNot] equal:otherKey];
        });
    });
    context(@"Different types", ^{
        beforeEach(^{
            otherKey = [[AMAAttributeKey alloc] initWithName:name type:AMAAttributeTypeString];
        });
        it(@"Should have different hashes", ^{
            [[theValue(key.hash) shouldNot] equal:theValue(otherKey.hash)];
        });
        it(@"Should not equal", ^{
            [[key shouldNot] equal:otherKey];
        });
    });
    context(@"Different classes", ^{
        it(@"Should not equal", ^{
            [[key shouldNot] equal:@"STRING"];
        });
    });

});

SPEC_END

