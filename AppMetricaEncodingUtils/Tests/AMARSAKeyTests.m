
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

SPEC_BEGIN(AMARSAKeyTests)

describe(@"AMARSAKey", ^{

    NSData *const data = [@"KEY_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    AMARSAKeyType const keyType = AMARSAKeyTypePublic;
    NSString *const tag = @"UNIQUE_TAG";

    AMARSAKey *__block key = nil;

    beforeEach(^{
        key = [[AMARSAKey alloc] initWithData:data keyType:keyType uniqueTag:tag];
    });

    it(@"Should have valid data", ^{
        [[key.data should] equal:data];
    });
    it(@"Should have valid type", ^{
        [[theValue(key.keyType) should] equal:theValue(keyType)];
    });
    it(@"Should have valid tag", ^{
        [[key.uniqueTag should] equal:tag];
    });
    it(@"Should return self as copy", ^{
        [[key.copy should] equal:key];
    });
    context(@"Equals", ^{
        AMARSAKey *__block otherKey = nil;
        context(@"Same pointer", ^{
            beforeEach(^{
                otherKey = key;
            });
            it(@"Should equals", ^{
                [[key should] equal:otherKey];
            });
            it(@"Should have same hash", ^{
                [[theValue(key.hash) should] equal:theValue(otherKey.hash)];
            });
        });
        context(@"Same fields", ^{
            beforeEach(^{
                otherKey = [[AMARSAKey alloc] initWithData:data keyType:keyType uniqueTag:tag];
            });
            it(@"Should equals", ^{
                [[key should] equal:otherKey];
            });
            it(@"Should have same hash", ^{
                [[theValue(key.hash) should] equal:theValue(otherKey.hash)];
            });
        });
        context(@"Different data", ^{
            beforeEach(^{
                otherKey = [[AMARSAKey alloc] initWithData:[@"OTHER" dataUsingEncoding:NSUTF8StringEncoding]
                                                   keyType:keyType
                                                 uniqueTag:tag];
            });
            it(@"Should not equals", ^{
                [[key shouldNot] equal:otherKey];
            });
        });
        context(@"Different type", ^{
            beforeEach(^{
                otherKey = [[AMARSAKey alloc] initWithData:data
                                                   keyType:AMARSAKeyTypePrivate
                                                 uniqueTag:tag];
            });
            it(@"Should not equals", ^{
                [[key shouldNot] equal:otherKey];
            });
        });
        context(@"Different tag", ^{
            beforeEach(^{
                otherKey = [[AMARSAKey alloc] initWithData:data
                                                   keyType:keyType
                                                 uniqueTag:@"OTHER"];
            });
            it(@"Should not equals", ^{
                [[key shouldNot] equal:otherKey];
            });
        });
        context(@"Different class", ^{
            it(@"Should not equals", ^{
                [[key shouldNot] equal:[NSObject new]];
            });
        });
    });
    
    it(@"Should comform to NSCopying", ^{
        [[key should] conformToProtocol:@protocol(NSCopying)];
    });
});

SPEC_END

