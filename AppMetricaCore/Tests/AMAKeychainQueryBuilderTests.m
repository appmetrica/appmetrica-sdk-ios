
#import <Kiwi/Kiwi.h>
#import "AMAKeychainQueryBuilder.h"

static BOOL isDictionarySubsetOfDictionary(NSDictionary *subset, NSDictionary *set);
static BOOL isDictionarySubsetOfDictionary(NSDictionary *subset, NSDictionary *set)
{
    if (subset.count == 0 || set.count == 0) {
        return NO;
    }

    __block BOOL result = YES;
    [subset enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([set[key] isEqual:obj] == NO) {
            *stop = YES;
            result = NO;
        }
    }];

    return result;
}

SPEC_BEGIN(AMAKeychainQueryBuilderTests)

describe(@"AMAKeychainQueryBuilder", ^{
    context(@"with query parameters", ^{
        NSDictionary *parameters = @{
                @"foo" : @"bar"
        };

        let(builder, ^{
            return [[AMAKeychainQueryBuilder alloc] initWithQueryParameters:@{
                    @"foo" : @"bar"
            }];
        });

        it(@"Should compose queries with parameters", ^{
            [[theValue(isDictionarySubsetOfDictionary(
                    parameters,
                    [builder entriesQuery])) should] beTrue];

            [[theValue(isDictionarySubsetOfDictionary(
                    parameters,
                    [builder dataQueryForKey:@"foo"])) should] beTrue];

            [[theValue(isDictionarySubsetOfDictionary(
                    parameters,
                    [builder entryQueryForKey:@"foo"])) should] beTrue];

            [[theValue(isDictionarySubsetOfDictionary(
                    parameters,
                    [builder addEntryQueryWithData:[NSData data] forKey:@"foo"])) should] beTrue];
        });
    });

    context(@"with empty settings", ^{
        let(builder, ^{
            return [[AMAKeychainQueryBuilder alloc] initWithQueryParameters:@{}];
        });

        it(@"Should restrict data query limit to one", ^{
            [[[builder dataQueryForKey:@"foo"][(__bridge id) kSecMatchLimit]
                    should] equal:(__bridge id) kSecMatchLimitOne];
        });

        it(@"Should request data property of entry in data query", ^{
            [[[builder dataQueryForKey:@"foo"][(__bridge id) kSecReturnData]
                    should] equal:(__bridge id) kCFBooleanTrue];
        });
    });
});

SPEC_END
