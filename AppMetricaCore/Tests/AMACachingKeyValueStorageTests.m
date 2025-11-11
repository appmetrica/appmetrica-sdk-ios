
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACachingKeyValueStorage.h"

SPEC_BEGIN(AMACachingKeyValueStorageTests)

describe(@"AMACachingKeyValueStorage", ^{

    NSString *const key = @"STORAGE_KEY";
    NSObject<AMAKeyValueStoring> *__block underlyingStorage = nil;
    AMACachingKeyValueStorage *__block storage = nil;

    beforeEach(^{
        underlyingStorage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        storage = [[AMACachingKeyValueStorage alloc] initWithStorage:underlyingStorage];
    });

    __auto_type executeAsync = ^(dispatch_block_t block) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), block);
    };

    context(@"String", ^{
        NSString *const value = @"STRING_VALUE";
        NSError *const expectedError = [NSError errorWithDomain:@"ERROR" code:42 userInfo:@{}];
        beforeEach(^{
            [underlyingStorage stub:@selector(stringForKey:error:) andReturn:value];
        });
        it(@"Should read from underlying storage twice on first read", ^{
            [[underlyingStorage should] receive:@selector(stringForKey:error:) withCount:2 arguments:key, kw_any()];
            [storage stringForKey:key error:nil];
        });
        it(@"Should read from underlying storage once on second read with different key", ^{
            [storage stringForKey:@"DIFFERENT" error:nil];
            [[underlyingStorage should] receive:@selector(stringForKey:error:) withCount:1 arguments:key, kw_any()];
            [storage stringForKey:key error:nil];
        });
        it(@"Should not write to underlying storage on first save", ^{
            [[underlyingStorage shouldNot] receive:@selector(saveString:forKey:error:)];
            [storage saveString:value forKey:key error:nil];
        });
        it(@"Should not wait for storage to open on write but provide valid value", ^{
            [underlyingStorage stub:@selector(stringForKey:error:) withBlock:^id(NSArray *params) {
                [NSThread sleepForTimeInterval:1.5];
                return @"OLD_VALUE";
            }];
            NSString *__block resultValue = nil;
            executeAsync(^{
                resultValue = [storage stringForKey:key error:nil];
            });
            BOOL __block executed = NO;
            executeAsync(^{
                [NSThread sleepForTimeInterval:0.5];
                [storage saveString:value forKey:key error:nil];
                executed = YES;
            });
            [[expectFutureValue(theValue(executed)) shouldEventuallyBeforeTimingOutAfter(1.0)] beYes];
            [[expectFutureValue(resultValue) shouldEventuallyBeforeTimingOutAfter(3.0)] equal:value];
        });
        it(@"Should store nil", ^{
            [storage saveString:nil forKey:key error:nil];
            [[[storage stringForKey:key error:nil] should] beNil];
        });
        it(@"Should remove value", ^{
            [storage removeValueForKey:key error:nil];
            [[[storage stringForKey:key error:nil] should] beNil];
        });
        it(@"Should not fill error on success", ^{
            NSError *error = nil;
            [storage stringForKey:key error:&error];
            [[error should] beNil];
        });
        it(@"Should fill error on failure", ^{
            NSError *error = nil;
            [underlyingStorage stub:@selector(stringForKey:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                return nil;
            }];
            [storage stringForKey:key error:&error];
            [[error should] equal:expectedError];
        });
        context(@"After first read", ^{
            beforeEach(^{
                [storage stringForKey:key error:nil];
            });
            it(@"Should return value from underlying storage", ^{
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should store value", ^{
                [storage saveString:value forKey:key error:nil];
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should write to underlying storage on first save", ^{
                [[underlyingStorage should] receive:@selector(saveString:forKey:error:)
                                      withArguments:value, key, kw_any()];
                [storage saveString:value forKey:key error:nil];
            });
            it(@"Should not write to underlying storage on flush", ^{
                [[underlyingStorage shouldNot] receive:@selector(saveString:forKey:error:)];
                [storage flush];
            });
            it(@"Should not read from underlying storage if saved", ^{
                [storage saveString:value forKey:key error:nil];
                [[underlyingStorage shouldNot] receive:@selector(stringForKey:error:)];
                [storage stringForKey:key error:nil];
            });
            it(@"Should store nil", ^{
                [storage saveString:nil forKey:key error:nil];
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should remove value", ^{
                [storage removeValueForKey:key error:nil];
                [[[storage stringForKey:key error:nil] should] beNil];
            });
        });
        context(@"After first write", ^{
            beforeEach(^{
                [storage saveString:value forKey:key error:nil];
            });
            it(@"Should store value", ^{
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should not read from underlying storage if saved", ^{
                [[underlyingStorage shouldNot] receive:@selector(stringForKey:error:)];
                [storage stringForKey:key error:nil];
            });
            it(@"Should not write to underlying storage on first save", ^{
                [[underlyingStorage shouldNot] receive:@selector(saveString:forKey:error:)];
                [storage saveString:value forKey:key error:nil];
            });
            it(@"Should store nil", ^{
                [storage saveString:nil forKey:key error:nil];
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should remove value", ^{
                [storage removeValueForKey:key error:nil];
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should write to underlying storage on flush", ^{
                [[underlyingStorage should] receive:@selector(saveString:forKey:error:)
                                      withArguments:value, key, kw_any()];
                [storage flush];
            });
            context(@"Should remove on flush", ^{
                beforeEach(^{
                    [storage removeValueForKey:key error:nil];
                });
                
                it(@"Should remove value from underlying storage on flush", ^{
                    [[underlyingStorage should] receive:@selector(removeValueForKey:error:)
                                          withArguments:key, kw_any()];
                    [storage flush];
                });
            });
            context(@"After flush", ^{
                beforeEach(^{
                    [storage flush];
                });
                it(@"Should write to underlying storage", ^{
                    [[underlyingStorage should] receive:@selector(saveString:forKey:error:)
                                          withArguments:value, key, kw_any()];
                    [storage saveString:value forKey:key error:nil];
                });
                it(@"Should not fill error on success", ^{
                    NSError *error = nil;
                    [storage saveString:value forKey:key error:&error];
                    [[error should] beNil];
                });
                it(@"Should fill error on failure", ^{
                    NSError *error = nil;
                    [underlyingStorage stub:@selector(saveString:forKey:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                        return nil;
                    }];
                    [storage saveString:value forKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });
        context(@"Invalid type", ^{
            beforeEach(^{
                [storage saveData:[@"DATA" dataUsingEncoding:NSUTF8StringEncoding] forKey:key error:nil];
            });
            it(@"Should return nil in production", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                [[[storage stringForKey:key error:nil] should] beNil];
            });
        });
    });

    context(@"BOOL", ^{
        NSNumber *const value = @YES;
        it(@"Should store YES", ^{
            [storage saveBoolNumber:value forKey:key error:nil];
            [[[storage boolNumberForKey:key error:nil] should] equal:value];
        });
        it(@"Should store NO", ^{
            [storage saveBoolNumber:@NO forKey:key error:nil];
            [[[storage boolNumberForKey:key error:nil] should] equal:@NO];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(boolNumberForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage boolNumberForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveBoolNumber:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveBoolNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveBoolNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveBoolNumber:value forKey:key error:nil];
        });
    });

    context(@"long long", ^{
        NSNumber *const value = [NSNumber numberWithLongLong:23];
        it(@"Should store value", ^{
            [storage saveLongLongNumber:value forKey:key error:nil];
            [[[storage longLongNumberForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(longLongNumberForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage longLongNumberForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveLongLongNumber:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveLongLongNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveLongLongNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveLongLongNumber:value forKey:key error:nil];
        });
    });
         
    context(@"unsigned long long", ^{
        NSNumber *const value = [NSNumber numberWithUnsignedLongLong:ULLONG_MAX];
        it(@"Should store value", ^{
            [storage saveUnsignedLongLongNumber:value forKey:key error:nil];
            [[[storage unsignedLongLongNumberForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(unsignedLongLongNumberForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage unsignedLongLongNumberForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveUnsignedLongLongNumber:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveUnsignedLongLongNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveUnsignedLongLongNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveUnsignedLongLongNumber:value forKey:key error:nil];
        });
    });

    context(@"double", ^{
        NSNumber *const value = @(10.8);
        it(@"Should store value", ^{
            [storage saveDoubleNumber:value forKey:key error:nil];
            [[[storage doubleNumberForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(doubleNumberForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage doubleNumberForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveDoubleNumber:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveDoubleNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveDoubleNumber:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveDoubleNumber:value forKey:key error:nil];
        });
    });

    context(@"NSDate", ^{
        NSDate *const value = [NSDate date];
        it(@"Should store value", ^{
            [storage saveDate:value forKey:key error:nil];
            [[[storage dateForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(dateForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage dateForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveDate:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveDate:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveDate:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveDate:value forKey:key error:nil];
        });
    });

    context(@"NSData", ^{
        NSData *const value = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
        it(@"Should store value", ^{
            [storage saveData:value forKey:key error:nil];
            [[[storage dataForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(dataForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage dataForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveData:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveData:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveData:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveData:value forKey:key error:nil];
        });
    });

    context(@"NSDictionary", ^{
        NSDictionary *const value = @{ @"foo": @"bar" };
        it(@"Should store value", ^{
            [storage saveJSONDictionary:value forKey:key error:nil];
            [[[storage jsonDictionaryForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(jsonDictionaryForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage jsonDictionaryForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveJSONDictionary:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveJSONDictionary:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveJSONDictionary:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveJSONDictionary:value forKey:key error:nil];
        });
    });

    context(@"NSArray", ^{
        NSArray *const value = @[ @"foo", @"bar" ];
        it(@"Should store value", ^{
            [storage saveJSONArray:value forKey:key error:nil];
            [[[storage jsonArrayForKey:key error:nil] should] equal:value];
        });
        it(@"Should read from underlying storage", ^{
            [[underlyingStorage should] receive:@selector(jsonArrayForKey:error:)
                                      withCount:2
                                      arguments:key, kw_any()];
            [storage jsonArrayForKey:key error:nil];
        });
        it(@"Should write to underlying storage on flush", ^{
            [storage saveJSONArray:value forKey:key error:nil];
            [[underlyingStorage should] receive:@selector(saveJSONArray:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage flush];
        });
        it(@"Should write to underlying storage after flush", ^{
            [storage flush];
            [[underlyingStorage should] receive:@selector(saveJSONArray:forKey:error:)
                                  withArguments:value, key, kw_any()];
            [storage saveJSONArray:value forKey:key error:nil];
        });
    });
    
    it(@"Should conform to AMAKeyValueStoring", ^{
        [[storage should] conformToProtocol:@protocol(AMAKeyValueStoring)];
    });
});

SPEC_END

