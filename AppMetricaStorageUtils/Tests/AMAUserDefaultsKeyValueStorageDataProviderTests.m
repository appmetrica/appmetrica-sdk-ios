
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAUserDefaultsKeyValueStorageDataProviderTests)

describe(@"AMAUserDefaultsKeyValueStorageDataProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    NSString *__block suiteName = nil;
    NSUserDefaults *__block defaults = nil;
    AMAUserDefaultsKVSDataProvider *__block provider = nil;

    beforeEach(^{
        suiteName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        provider = [[AMAUserDefaultsKVSDataProvider alloc] initWithUserDefaults:defaults];
    });

    afterEach(^{
        [defaults removeSuiteNamed:suiteName];
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
    it(@"Should not return key for the first time", ^{
        [[[provider allKeysWithError:nil] shouldNot] contain: key];
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
    it(@"Should allow removing when storing values for keys", ^{
        [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
        [provider saveObjectsDictionary:@{ @"a": @"AA", @"c": [NSNull null], @"d": @"D" } error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"AA", @"d": @"D" }];
    });

    context(@"Existing data", ^{
        beforeEach(^{
            [defaults setObject:value forKey:key];
        });
        it(@"Should return existing value", ^{
            [[[provider objectForKey:key error:nil] should] equal:value];
        });
        context(@"Append new value", ^{
            NSString *const newKey = @"NEW_KEY";
            NSString *const newValue = @"NEW_VALUE";
            beforeEach(^{
                [provider saveObject:newValue forKey:newKey error:NULL];
            });
            it(@"Should return previous value", ^{
                [[[provider objectForKey:key error:NULL] should] equal:value];
            });
            it(@"Should return new value", ^{
                [[[provider objectForKey:newKey error:NULL] should] equal:newValue];
            });
            it(@"Should write defaults", ^{
                NSDictionary *currentValue =
                    [AMACollectionUtilities filteredDictionary:defaults.dictionaryRepresentation
                                                      withKeys:[NSSet setWithObjects:key, newKey, nil]];
                [[currentValue should] equal:@{ key: value, newKey: newValue }];
            });
        });
        context(@"Remove value", ^{
            beforeEach(^{
                [provider removeKey:key error:NULL];
            });
            it(@"Should not return value", ^{
                [[[provider objectForKey:key error:NULL] should] beNil];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider objectForKey:key error:&error];
                [[error should] beNil];
            });
            it(@"Should write defaults", ^{
                [[defaults.dictionaryRepresentation.allKeys shouldNot] contain:key];
            });
        });
    });
    
});

SPEC_END
