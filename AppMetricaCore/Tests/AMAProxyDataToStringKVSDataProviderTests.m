
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAProxyDataToStringKVSDataProvider.h"
#import "AMAInMemoryKeyValueStorageDataProvider.h"

SPEC_BEGIN(AMAProxyDataToStringKVSDataProviderTests)

describe(@"AMAProxyDataToStringKVSDataProvider", ^{
    
    AMAProxyDataToStringKVSDataProvider *__block dataProvider = nil;
    AMAInMemoryKeyValueStorageDataProvider *__block inMemoryProvider = nil;
    NSMutableDictionary *__block dict = nil;
    
    NSString *const kAMAHello64 = [[NSData dataWithBytes:"hello" length:6] base64EncodedStringWithOptions:0];
    NSData *const kAMAHello = [[NSData alloc] initWithBase64EncodedString:kAMAHello64 options:0];
    NSString *const kAMAWorld64 = [[NSData dataWithBytes:"world" length:6] base64EncodedStringWithOptions:0];
    NSData *const kAMAWorld = [[NSData alloc] initWithBase64EncodedString:kAMAWorld64 options:0];
    
    beforeEach(^{
        dict = [NSMutableDictionary dictionary];
        inMemoryProvider = [[AMAInMemoryKeyValueStorageDataProvider alloc] initWithDictionary:dict];
        dataProvider = [[AMAProxyDataToStringKVSDataProvider alloc] initWithUnderlyingDataProvider:inMemoryProvider];
    });
    
    it(@"Should return all keys", ^{
        NSArray *const kExpectedKeys = @[ @"a", @"b", @"c", @"d" ];
        [dict addEntriesFromDictionary:[NSDictionary dictionaryWithObjects:@[ @"e", @"f", @"g", @"h" ]
                                                                   forKeys:kExpectedKeys]];
        [[[dataProvider allKeysWithError:NULL] should] containObjectsInArray:kExpectedKeys];
    });
    
    context(@"Object for key", ^{
        
        it(@"Should return decoded value", ^{
            dict[@"a"] = kAMAHello64;
            [[[dataProvider objectForKey:@"a" error:NULL] should] equal:kAMAHello];
        });
        
        it(@"Should assert if the value is not NSString", ^{
            dict[@"a"] = [NSData data];
            [[theBlock(^{
                [dataProvider objectForKey:@"a" error:NULL];
            }) should] raise];
        });
        
        it(@"Should not assert if the value is NSNull", ^{
            [inMemoryProvider stub:@selector(objectForKey:error:) andReturn:NSNull.null];
            [[theBlock(^{
                [dataProvider objectForKey:@"a" error:NULL];
            }) shouldNot] raise];
        });
        
        it(@"Should return nil if the value is NSNull", ^{
            [inMemoryProvider stub:@selector(objectForKey:error:) andReturn:NSNull.null];
            [[[dataProvider objectForKey:@"a" error:NULL] should] equal:NSNull.null];
        });
    });
    
    context(@"Objects for keys", ^{
        
        it(@"Should return decoded values", ^{
            dict[@"a"] = kAMAHello64;
            dict[@"b"] = kAMAWorld64;
            
            [[[dataProvider objectsForKeys:@[ @"a", @"b" ] error:NULL] should] equal:@{ @"a" : kAMAHello,
                                                                                        @"b" : kAMAWorld, }];
        });
        
        it(@"Should assert if one of the values is not NSString", ^{
            dict[@"a"] = [NSData data];
            dict[@"b"] = kAMAWorld64;
            [[theBlock(^{
                [dataProvider objectsForKeys:@[ @"a", @"b" ] error:NULL];
            }) should] raise];
        });
        
        it(@"Should not assert if the value is NSNull", ^{
            [inMemoryProvider stub:@selector(objectsForKeys:error:) andReturn:@{ @"a" : NSNull.null }];
            [[theBlock(^{
                [dataProvider objectForKey:@"a" error:NULL];
            }) shouldNot] raise];
        });
        
        it(@"Should return nil if the value is NSNull", ^{
            [inMemoryProvider stub:@selector(objectsForKeys:error:) andReturn:@{ @"a" : NSNull.null }];
            [[[dataProvider objectForKey:@"a" error:NULL] should] beNil];
        });
        
    });
    
    it(@"Should remove key", ^{
        dict[@"a"] = kAMAHello64;
        
        [dataProvider removeKey:@"a" error:NULL];
        
        [[[inMemoryProvider objectForKey:@"a" error:NULL] should] beNil];
    });
    
    context(@"Save object for key", ^{
        
        it(@"Should save object in base64", ^{
            [dataProvider saveObject:kAMAHello forKey:@"a" error:NULL];
            [[[inMemoryProvider objectForKey:@"a" error:NULL] should] equal:kAMAHello64];
        });
        
        it(@"Should assert if saved value is not NSData", ^{
            [[theBlock(^{
                [dataProvider saveObject:@"Hello" forKey:@"a" error:NULL];
            }) should] raise];
        });
        
        it(@"Should not assert if the value is NSNull", ^{
            [[theBlock(^{
                [dataProvider saveObject:NSNull.null forKey:@"a" error:NULL];
            }) shouldNot] raise];
        });
        
        it(@"Should save NSNull if the value is NSNull", ^{
            [[inMemoryProvider should] receive:@selector(saveObject:forKey:error:) withArguments:NSNull.null, @"a", kw_any()    ];
            [dataProvider saveObject:NSNull.null forKey:@"a" error:NULL];
        });
    });
    
    context(@"Save objects", ^{
        
        it(@"Should save objects in base64", ^{
            [dataProvider saveObjectsDictionary:@{ @"a" : kAMAHello, @"b" : kAMAWorld,  } error:NULL];
            [[[inMemoryProvider objectsForKeys:@[ @"a", @"b" ] error:NULL] should] equal:@{
                @"a" : kAMAHello64,
                @"b" : kAMAWorld64,
            }];
        });
        
        it(@"Should assert if one of saved values is not NSData", ^{
            [[theBlock(^{
                [dataProvider saveObjectsDictionary:@{ @"a" : kAMAHello, @"b" : @"World",  } error:NULL];
            }) should] raise];
        });
        
        it(@"Should not assert if the value is NSNull", ^{
            [[theBlock(^{
                [dataProvider saveObjectsDictionary:@{ @"a" : NSNull.null} error:NULL];
            }) shouldNot] raise];
        });
        
        it(@"Should save nil if the value is NSNull", ^{
            [[inMemoryProvider should] receive:@selector(saveObjectsDictionary:error:) withArguments:@{ @"a" : NSNull.null}, kw_any()];
            [dataProvider saveObjectsDictionary:@{ @"a" : NSNull.null} error:NULL];
        });
    });
});

SPEC_END
