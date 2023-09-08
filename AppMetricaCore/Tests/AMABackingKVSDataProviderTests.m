
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMABackingKVSDataProvider.h"
#import "AMAInMemoryKeyValueStorageDataProvider.h"

SPEC_BEGIN(AMABackingKVSDataProviderTests)

describe(@"AMABackingKVSDataProvider", ^{
    
    static NSString *const kAMAKey1 = @"test_key_1";
    static NSString *const kAMAValue1 = @"test_value_1";
    static NSString *const kAMAKey2 = @"test_key_2";
    static NSString *const kAMAValue2 = @"test_value_2";
    
    static NSString *const kAMAAnotherKey1 = @"another_key_1";
    static NSString *const kAMAAnotherKey2 = @"another_key_2";
    static NSString *const kAMAExpectedValue = @"expected";
    static NSString *const kAMAUnexpectedValue = @"unexpected";
    
    AMAInMemoryKeyValueStorageDataProvider *__block mainProvider = nil;
    AMAInMemoryKeyValueStorageDataProvider *__block reserveProvider = nil;
    
    NSMutableDictionary *__block mainProviderDict = nil;
    NSMutableDictionary *__block reserveProviderDict = nil;
    
    AMABackingKVSDataProvider *__block backingDataProvider = nil;
    
    beforeEach(^{
        mainProviderDict = [NSMutableDictionary dictionary];
        reserveProviderDict = [NSMutableDictionary dictionary];
        
        mainProvider = [[AMAInMemoryKeyValueStorageDataProvider alloc] initWithDictionary:mainProviderDict];
        reserveProvider = [[AMAInMemoryKeyValueStorageDataProvider alloc] initWithDictionary:reserveProviderDict];
        
        __auto_type source = ^(AMAKVSWithProviderBlock block) {
            block(mainProvider);
        };
        
        __auto_type backing = ^(AMAKVSWithProviderBlock block) {
            block(reserveProvider);
        };
        
        backingDataProvider = [[AMABackingKVSDataProvider alloc] initWithProviderSource:source
                                                                  backingProviderSource:backing
                                                                            backingKeys:@[ kAMAKey1, kAMAKey2 ]];
    });
    
    it(@"Should return all keys in original and backup keys from backing providers", ^{
        
        mainProviderDict[kAMAKey1] = kAMAValue1;
        mainProviderDict[kAMAAnotherKey1] = @"value";
        reserveProviderDict[kAMAKey2] = kAMAValue2;
        reserveProviderDict[kAMAAnotherKey2] = @"value";
        
        [[[backingDataProvider allKeysWithError:NULL] should] containObjectsInArray:@[ kAMAAnotherKey1,
                                                                                       kAMAKey1,
                                                                                       kAMAKey2, ]];
    });
    
    context(@"Object for key", ^{
        
        it(@"Should provide value from origninal provider if available", ^{
            
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAAnotherKey1] = kAMAUnexpectedValue;
            
            [[[backingDataProvider objectForKey:kAMAAnotherKey1 error:NULL] should] equal:kAMAExpectedValue];
        });
        
        it(@"Should not update value for non-backup key", ^{
            
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAAnotherKey1] = kAMAUnexpectedValue;
            
            [backingDataProvider objectForKey:kAMAAnotherKey1 error:NULL];
            
            [[[reserveProvider objectForKey:kAMAAnotherKey1 error:NULL] should] equal:kAMAUnexpectedValue];
        });
        
        it(@"Should return nothing if there is no value in original provider for non-backup key", ^{
            
            reserveProviderDict[kAMAAnotherKey1] = kAMAUnexpectedValue;
            
            [[[backingDataProvider objectForKey:kAMAAnotherKey1 error:NULL] should] beNil];
        });
        
        it(@"Should return value if there is no value in original provider for backup key", ^{
            
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            
            [[[backingDataProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should sync original provider with backing", ^{
            
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAKey1] = nil;
            
            [backingDataProvider objectForKey:kAMAKey1 error:NULL];
            
            [[[mainProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should sync backing provider with original", ^{
            
            reserveProviderDict[kAMAKey1] = nil;
            mainProviderDict[kAMAKey1] = kAMAValue1;
            
            [backingDataProvider objectForKey:kAMAKey1 error:NULL];
            
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should use value in main provider if value exists in both providers", ^{
            
            mainProviderDict[kAMAKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey1] = kAMAUnexpectedValue;
            
            [[[backingDataProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAExpectedValue];
        });
        
        it(@"Should update value in backing provider if value exists in both providers", ^{
            
            mainProviderDict[kAMAKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey1] = kAMAUnexpectedValue;
            
            [backingDataProvider objectForKey:kAMAKey1 error:NULL];
            
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAExpectedValue];
        });
        
        it(@"Should provide value if providers' values are equal", ^{
            
            mainProviderDict[kAMAKey1] = kAMAValue1;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            
            [[[backingDataProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should return only required value", ^{
            mainProviderDict[kAMAKey1] = nil;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            
            [[[backingDataProvider objectForKey:kAMAAnotherKey1 error:NULL] should] beNil];
        });
    });
    
    context(@"Objects for key", ^{
        
        it(@"Should return values from backing and original providers", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            reserveProviderDict[kAMAAnotherKey2] = kAMAUnexpectedValue;
            
            NSDictionary *result = [backingDataProvider objectsForKeys:@[ kAMAKey1,
                                                                          kAMAKey2,
                                                                          kAMAAnotherKey1,
                                                                          kAMAAnotherKey2 ] error:NULL];
            
            [[result should] equal:@{
                kAMAKey1 : kAMAValue1,
                kAMAAnotherKey1 : kAMAExpectedValue,
                kAMAKey2 : kAMAValue2,
            }];
        });
        
        it(@"Should not update value for non-backup keys", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            reserveProviderDict[kAMAAnotherKey1] = nil;
            
            [backingDataProvider objectsForKeys:@[ kAMAKey1, kAMAKey2, kAMAAnotherKey1, kAMAAnotherKey2 ] error:NULL];
            
            [[[reserveProvider objectForKey:kAMAAnotherKey1 error:NULL] should] beNil];
        });
        
        it(@"Should update value for backup keys", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey1] = nil;
            
            [backingDataProvider objectsForKeys:@[ kAMAKey1, kAMAKey2, kAMAAnotherKey1, kAMAAnotherKey2 ] error:NULL];
            
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should use value in main provider if value exists in both providers", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            reserveProviderDict[kAMAKey1] = kAMAUnexpectedValue;
            reserveProviderDict[kAMAAnotherKey1] = kAMAUnexpectedValue;
            
            NSDictionary *result = [backingDataProvider objectsForKeys:@[ kAMAKey1,
                                                                          kAMAKey2,
                                                                          kAMAAnotherKey1,
                                                                          kAMAAnotherKey2, ] error:NULL];
            
            [[result should] equal:@{
                kAMAKey1 : kAMAValue1,
                kAMAAnotherKey1 : kAMAExpectedValue,
            }];
        });
        
        it(@"Should sync values for backup keys", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAKey2] = nil;
            reserveProviderDict[kAMAKey1] = nil;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            
            [backingDataProvider objectsForKeys:@[ kAMAKey1, kAMAKey2 ] error:NULL];
            
            [[[mainProvider objectForKey:kAMAKey2 error:NULL] should] equal:kAMAValue2];
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
        });
        
        it(@"Should provide value if providers' values are equal", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            mainProviderDict[kAMAKey2] = kAMAValue2;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            
            NSDictionary *result = [backingDataProvider objectsForKeys:@[ kAMAKey1, kAMAKey2 ] error:NULL];
            
            [[result should] equal:@{
                kAMAKey1 : kAMAValue1,
                kAMAKey2 : kAMAValue2,
            }];
        });
        
        it(@"Should return only required values", ^{
            mainProviderDict[kAMAKey1] = nil;
            mainProviderDict[kAMAKey2] = nil;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            
            [[[backingDataProvider objectsForKeys:@[ kAMAAnotherKey1, kAMAAnotherKey2 ] error:NULL] should] beEmpty];
        });
        
        it(@"Should not delete value in backing provider if there is no value in the main one", ^{
            mainProviderDict[kAMAKey1] = nil;
            mainProviderDict[kAMAKey2] = nil;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            reserveProviderDict[kAMAKey2] = kAMAValue2;
            
            [backingDataProvider objectsForKeys:@[ kAMAAnotherKey1, kAMAAnotherKey2 ] error:NULL];
            
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAValue1];
            [[[reserveProvider objectForKey:kAMAKey2 error:NULL] should] equal:kAMAValue2];
        });
        
        it(@"Should return and store correct values", ^{
            
            __auto_type source = ^(AMAKVSWithProviderBlock block) {
                block(mainProvider);
            };
            
            __auto_type backing = ^(AMAKVSWithProviderBlock block) {
                block(reserveProvider);
            };
            
            NSArray *const kKeys = @[ @"A", @"B", @"C", @"D" ];
            
            backingDataProvider = [[AMABackingKVSDataProvider alloc] initWithProviderSource:source
                                                                      backingProviderSource:backing
                                                                                backingKeys:kKeys];
            
            mainProviderDict[@"A"] = @"a";
            mainProviderDict[@"B"] = @"b";
            mainProviderDict[@"C"] = @"c";
            
            reserveProviderDict[@"A"] = @"x";
            reserveProviderDict[@"B"] = @"b";
            reserveProviderDict[@"C"] = @"x";
            reserveProviderDict[@"D"] = @"d";
            
            [[[backingDataProvider objectsForKeys:@[ @"A", @"B" ] error:NULL] should] equal:@{@"A" : @"a",
                                                                                              @"B" : @"b"}];
            
            [[[mainProvider objectsForKeys:kKeys error:NULL] should] equal:@{
                @"A" : @"a",
                @"B" : @"b",
                @"C" : @"c",
            }];
            
            [[[reserveProvider objectsForKeys:kKeys error:NULL] should] equal:@{
                @"A" : @"a",
                @"B" : @"b",
                @"C" : @"x",
                @"D" : @"d",
            }];
        });
    });
    
    context(@"Remove key", ^{
        
        it(@"Should remove value from original and backing providers", ^{
            mainProviderDict[kAMAKey1] = kAMAValue1;
            reserveProviderDict[kAMAKey1] = kAMAValue1;
            
            [backingDataProvider removeKey:kAMAKey1 error:NULL];
            
            [[[mainProvider objectForKey:kAMAKey1 error:NULL] should] beNil];
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] beNil];
        });
        
        it(@"Should not delete values for non-backup keys", ^{
            mainProviderDict[kAMAAnotherKey1] = kAMAUnexpectedValue;
            reserveProviderDict[kAMAAnotherKey1] = kAMAExpectedValue;
            
            [backingDataProvider removeKey:kAMAAnotherKey1 error:NULL];
            
            [[[mainProvider objectForKey:kAMAAnotherKey1 error:NULL] should] beNil];
            [[[reserveProvider objectForKey:kAMAAnotherKey1 error:NULL] should] equal:kAMAExpectedValue];
        });
    });
    
    context(@"Save object", ^{
        
        it(@"Should save backup keys to bacing provider", ^{
            mainProviderDict[kAMAKey1] = nil;
            reserveProviderDict[kAMAKey1] = nil;
            
            [backingDataProvider saveObject:kAMAExpectedValue forKey:kAMAKey1 error:NULL];
            
            [[[mainProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAExpectedValue];
            [[[reserveProvider objectForKey:kAMAKey1 error:NULL] should] equal:kAMAExpectedValue];
        });
        
        it(@"Should not save non-backup keys to bacing provider", ^{
            mainProviderDict[kAMAAnotherKey1] = nil;
            reserveProviderDict[kAMAAnotherKey1] = nil;
            
            [backingDataProvider saveObject:kAMAExpectedValue forKey:kAMAAnotherKey1 error:NULL];
            
            [[[mainProvider objectForKey:kAMAAnotherKey1 error:NULL] should] equal:kAMAExpectedValue];
            [[[reserveProvider objectForKey:kAMAAnotherKey1 error:NULL] should] beNil];
        });
    });
    
    context(@"Save objecta", ^{
        
        it(@"Should save backup keys to bacing provider", ^{
            NSDictionary *const kExpectedDict = @{ kAMAKey1 : kAMAValue1, kAMAKey2 : kAMAValue2 };
            
            [backingDataProvider saveObjectsDictionary:kExpectedDict error:NULL];
            
            [[[mainProvider objectsForKeys:kExpectedDict.allKeys error:NULL] should] equal:kExpectedDict];
            [[[reserveProvider objectsForKeys:kExpectedDict.allKeys error:NULL] should] equal:kExpectedDict];
        });
        
        it(@"Should not save non-backup keys to bacing provider", ^{
            NSDictionary *const kExpectedDict = @{
                kAMAKey1 : kAMAValue1,
                kAMAKey2 : kAMAValue2,
                kAMAAnotherKey1 : kAMAExpectedValue,
                kAMAAnotherKey1 : kAMAExpectedValue,
            };
            
            [backingDataProvider saveObjectsDictionary:kExpectedDict error:NULL];
            
            [[[mainProvider objectsForKeys:kExpectedDict.allKeys error:NULL] should] equal:kExpectedDict];
            [[[reserveProvider objectsForKeys:kExpectedDict.allKeys error:NULL] should] equal:@{
                kAMAKey1 : kAMAValue1,
                kAMAKey2 : kAMAValue2,
            }];
        });
    });
});

SPEC_END
