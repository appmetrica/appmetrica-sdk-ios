
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

SPEC_BEGIN(AMAIncrementableValueStorageTests)

describe(@"AMAIncrementableValueStorage", ^{

    NSString *const storageKey = @"io.appmetrica.attribution.id";
    NSNumber *const defaultValue = @23;
    NSNumber *const storedValue = @42;

    NSObject<AMAKeyValueStoring> *__block storage = nil;
    AMARollbackHolder *__block rollbackHolder = nil;
    AMAIncrementableValueStorage *__block valueStorage = nil;

    beforeEach(^{
        storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        rollbackHolder = [[AMARollbackHolder alloc] init];
        valueStorage = [[AMAIncrementableValueStorage alloc] initWithKey:storageKey
                                                            defaultValue:[defaultValue longLongValue]];
    });

    context(@"Getter", ^{

        it(@"Should use default ID if absent in storage", ^{
            [[[valueStorage valueWithStorage:storage] should] equal:defaultValue];
        });
        it(@"Should not save default ID", ^{
            [[storage shouldNot] receive:@selector(saveLongLongNumber:forKey:error:)];
            [valueStorage valueWithStorage:storage];
        });

        context(@"Identifier in storage", ^{
            beforeEach(^{
                [storage stub:@selector(longLongNumberForKey:error:) andReturn:storedValue];
            });

            it(@"Should use proper storage key", ^{
                KWCaptureSpy *spy = [storage captureArgument:@selector(longLongNumberForKey:error:) atIndex:0];
                [valueStorage valueWithStorage:storage];
                [[spy.argument should] equal:storageKey];
            });
            it(@"Should load from storage", ^{
                [[[valueStorage valueWithStorage:storage] should] equal:storedValue];
            });

            context(@"Second call", ^{
                beforeEach(^{
                    [valueStorage valueWithStorage:storage];
                });
                it(@"Should not load twice", ^{
                    [[storage shouldNot] receive:@selector(longLongNumberForKey:error:)];
                    [valueStorage valueWithStorage:storage];
                });
                it(@"Should return cached value", ^{
                    [[[valueStorage valueWithStorage:storage] should] equal:storedValue];
                });
            });
        });
    });

    context(@"Next identifier", ^{

        it(@"Should use proper if absent in storage", ^{
            [[[valueStorage nextInStorage:storage rollback:rollbackHolder error:nil] should] equal:@24];
        });
        it(@"Should save", ^{
            [[storage should] receive:@selector(saveLongLongNumber:forKey:error:)
                        withArguments:@24, storageKey, kw_any()];
            [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
        });
        
        it(@"Should subscribe on rollback", ^{
            [[rollbackHolder should] receive:@selector(subscribeOnRollback:)];
            
            [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
        });
        
        it(@"Should set rollback true if failed to save value", ^{
            [storage stub:@selector(saveLongLongNumber:forKey:error:) andReturn:theValue(NO)];
            
            [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
            
            [[theValue(rollbackHolder.rollback) should] beYes];
        });
        
        it(@"Should set rollback false if saved value", ^{
            [storage stub:@selector(saveLongLongNumber:forKey:error:) andReturn:theValue(YES)];
            
            [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
            
            [[theValue(rollbackHolder.rollback) should] beNo];
        });

        context(@"Identifier in storage", ^{
            beforeEach(^{
                [storage stub:@selector(longLongNumberForKey:error:) andReturn:storedValue];
            });

            it(@"Should use proper storage key on load", ^{
                KWCaptureSpy *spy = [storage captureArgument:@selector(longLongNumberForKey:error:) atIndex:0];
                [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
                [[spy.argument should] equal:storageKey];
            });
            it(@"Should save", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:)
                            withArguments:@43, storageKey, kw_any()];
                [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
            });
            it(@"Should return proper value", ^{
                [[[valueStorage nextInStorage:storage rollback:rollbackHolder error:nil] should] equal:@43];
            });
        });
    });

    context(@"Big numbers", ^{
        long long const bigInteger = 23000000000000;
        NSNumber *const bigNumber = [NSNumber numberWithLongLong:bigInteger];
        NSNumber *const nextBigNumber = [NSNumber numberWithLongLong:bigInteger + 1];

        context(@"Default value", ^{
            beforeEach(^{
                valueStorage = [[AMAIncrementableValueStorage alloc] initWithKey:storageKey
                                                                    defaultValue:bigInteger];
            });
            it(@"Should return value", ^{
                [[[valueStorage valueWithStorage:storage] should] equal:bigNumber];
            });
            it(@"Should return next value", ^{
                [[[valueStorage nextInStorage:storage rollback:rollbackHolder error:nil] should] equal:nextBigNumber];
            });
            it(@"Should store next value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:)
                            withArguments:nextBigNumber, kw_any(), kw_any()];
                [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
            });
        });
        context(@"Load value", ^{
            beforeEach(^{
                [storage stub:@selector(longLongNumberForKey:error:) andReturn:bigNumber];
            });
            it(@"Should return value", ^{
                [[[valueStorage valueWithStorage:storage] should] equal:bigNumber];
            });
            it(@"Should return next value", ^{
                [[[valueStorage nextInStorage:storage rollback:rollbackHolder error:nil] should] equal:nextBigNumber];
            });
            it(@"Should store next value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:)
                            withArguments:nextBigNumber, kw_any(), kw_any()];
                [valueStorage nextInStorage:storage rollback:rollbackHolder error:nil];
            });
        });
    });

});

SPEC_END
