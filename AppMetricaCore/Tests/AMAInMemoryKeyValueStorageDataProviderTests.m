
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAInMemoryKeyValueStorageDataProvider.h"

SPEC_BEGIN(AMAInMemoryKeyValueStorageDataProviderTests)

describe(@"AMAInMemoryKeyValueStorageDataProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    NSMutableDictionary *__block dictionary = nil;
    AMAInMemoryKeyValueStorageDataProvider *__block provider = nil;

    beforeEach(^{
        dictionary = [NSMutableDictionary dictionary];
        provider = [[AMAInMemoryKeyValueStorageDataProvider alloc] initWithDictionary:dictionary];
    });

    it(@"Should store value", ^{
        [provider saveObject:value forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] equal:value];
    });
    it(@"Should store nil", ^{
        [provider saveObject:nil forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should overwrite with value", ^{
        [provider saveObject:nil forKey:key error:nil];
        [provider saveObject:value forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] equal:value];
    });
    it(@"Should overwrite with nil", ^{
        [provider saveObject:@"SOME" forKey:key error:nil];
        [provider saveObject:nil forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should return nil if no value", ^{
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should return empty array if no keys", ^{
        [[[provider allKeysWithError:nil] should] beEmpty];
    });
    it(@"Should return all keys", ^{
        [provider saveObject:@"A" forKey:@"a" error:nil];
        [provider saveObject:@"B" forKey:@"b" error:nil];
        [provider saveObject:@"C" forKey:@"c" error:nil];
        [[[provider allKeysWithError:nil] should] containObjectsInArray:@[ @"a", @"b", @"c" ]];
    });
    it(@"Should return values for keys", ^{
        [provider saveObject:@"A" forKey:@"a" error:nil];
        [provider saveObject:@"B" forKey:@"b" error:nil];
        [provider saveObject:@"C" forKey:@"c" error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
    });
    it(@"Should store values for keys", ^{
        [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
    });
    it(@"Should remove key", ^{
        [provider saveObject:@"A" forKey:@"a" error:nil];
        [provider saveObject:@"B" forKey:@"b" error:nil];
        [provider removeKey:@"a" error:nil];
        [[[provider objectsForKeys:@[ @"a", @"b" ] error:nil] should] equal:@{ @"a": [NSNull null], @"b": @"B" }];
    });
    it(@"Should allow removing when storing values for keys", ^{
        [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
        [provider saveObjectsDictionary:@{ @"a": @"AA", @"c": [NSNull null], @"d": @"D" } error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"AA", @"c": [NSNull null], @"d": @"D" }];
    });

    context(@"Existing data", ^{
        it(@"Should return existing value", ^{
            dictionary[key] = value;
            [[[provider objectForKey:key error:nil] should] equal:value];
        });
        it(@"Should return existing nil", ^{
            dictionary[key] = [NSNull null];
            [[[provider objectForKey:key error:nil] should] beNil];
        });
    });

});

SPEC_END

