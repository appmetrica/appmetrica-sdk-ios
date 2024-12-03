
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAFallbackKeychain.h"
#import "AMAKeychain.h"
#import "AMAKeychainBridgeMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFallbackKeychainTests)

describe(@"AMAFallbackKeychainTests", ^{

    context(@"With main and fallback keychain", ^{
        NSString *const key = @"KEY";
        NSString *const dbKey = @"fallback-keychain-KEY";
        NSString *const dbValue = @"DB_VALUE";
        NSString *const mainKeychainValue = @"MAIN_KEYCHAIN_VALUE";
        NSString *const fallbackKeychainValue = @"FALLBACK_KEYCHAIN_VALUE";

        NSObject<AMAKeyValueStoring> *__block storage = nil;
        AMAKeychain *__block mainKeychain = nil;
        AMAKeychain *__block fallbackKeychain = nil;
        AMAFallbackKeychain *__block keychain = nil;

        beforeEach(^{
            AMAKeychainBridge *bridge = [[AMAKeychainBridgeMock alloc] init];

            storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
            mainKeychain = [[AMAKeychain alloc] initWithService:@"io.appmetrica.mainkeychain"
                                                    accessGroup:@""
                                                         bridge:bridge];
            fallbackKeychain = [[AMAKeychain alloc] initWithService:@"io.appmetrica.fallbackkeychain"
                                                        accessGroup:@""
                                                             bridge:bridge];
            keychain = [[AMAFallbackKeychain alloc] initWithStorage:storage
                                                       mainKeychain:mainKeychain
                                                   fallbackKeychain:fallbackKeychain];
        });

        context(@"Set", ^{
            it(@"Should save to DB", ^{
                [[storage should] receive:@selector(saveString:forKey:error:)
                            withArguments:dbValue, dbKey, kw_any()];
                [keychain setStringValue:dbValue forKey:key error:nil];
            });
            it(@"Should save to main keychain", ^{
                [[mainKeychain should] receive:@selector(setStringValue:forKey:error:)
                                 withArguments:mainKeychainValue, key, kw_any()];
                [keychain setStringValue:mainKeychainValue forKey:key error:nil];
            });
            it(@"Should add to fallback keychain", ^{
                [[fallbackKeychain should] receive:@selector(addStringValue:forKey:error:)
                                     withArguments:fallbackKeychainValue, key, kw_any()];
                [keychain setStringValue:fallbackKeychainValue forKey:key error:nil];
            });
        });

        it(@"Should take values from DB", ^{
            [storage stub:@selector(stringForKey:error:) andReturn:dbValue];
            [[[keychain stringValueForKey:key error:nil] should] equal:dbValue];
        });

        it(@"Should use valid DB key", ^{
            [[storage should] receive:@selector(stringForKey:error:) withArguments:dbKey, kw_any()];
            [keychain stringValueForKey:key error:nil];
        });

        it(@"Should prefer values from DB", ^{
            [storage stub:@selector(stringForKey:error:) andReturn:dbValue];
            [mainKeychain setStringValue:mainKeychainValue forKey:key error:nil];
            [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
            [[[keychain stringValueForKey:key error:nil] should] equal:dbValue];
        });

        it(@"Should take values from main keychain if there is no values in DB", ^{
            [mainKeychain setStringValue:mainKeychainValue forKey:key error:nil];
            [[[keychain stringValueForKey:key error:nil] should] equal:mainKeychainValue];
        });

        it(@"Should take values from fallback keychain if there is no values in main and DB", ^{
            [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
            [[[keychain stringValueForKey:key error:nil] should] equal:fallbackKeychainValue];
        });

        context(@"Fallback keychain has value", ^{
            beforeEach(^{
                [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
            });
            it(@"Should fill empty entries in DB", ^{
                [[storage should] receive:@selector(saveString:forKey:error:)
                            withArguments:fallbackKeychainValue, dbKey, kw_any()];
                [keychain stringValueForKey:key error:nil];
            });

            it(@"Should fill empty entries in main keychain", ^{
                [keychain stringValueForKey:key error:nil];
                [[[mainKeychain stringValueForKey:key error:nil] should] equal:fallbackKeychainValue];
            });
        });

        context(@"Main keychain has value", ^{
            beforeEach(^{
                [mainKeychain setStringValue:mainKeychainValue forKey:key error:nil];
            });
            it(@"Should fill empty entries in DB", ^{
                [[storage should] receive:@selector(saveString:forKey:error:)
                            withArguments:mainKeychainValue, dbKey, kw_any()];
                [keychain stringValueForKey:key error:nil];
            });
            it(@"Should fill empty entries in fallback keychain", ^{
                [keychain stringValueForKey:key error:nil];
                [[[fallbackKeychain stringValueForKey:key error:nil] should] equal:mainKeychainValue];
            });
            context(@"Error", ^{
                it(@"Should not fill entries in DB", ^{
                    [storage stub:@selector(stringForKey:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSError new]];
                        return nil;
                    }];
                    [[storage shouldNot] receive:@selector(saveString:forKey:error:)];
                    [keychain stringValueForKey:key error:nil];
                });
                it(@"Should not fill entries in fallback keychain", ^{
                    [fallbackKeychain stub:@selector(stringValueForKey:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSError new]];
                        return nil;
                    }];
                    [keychain stringValueForKey:key error:nil];
                    [[[fallbackKeychain stringValueForKey:key error:nil] should] beNil];
                });
            });
        });

        context(@"DB has value", ^{
            beforeEach(^{
                [storage stub:@selector(stringForKey:error:) andReturn:dbValue];
            });
            it(@"Should fill empty entries in main keychain", ^{
                [keychain stringValueForKey:key error:nil];
                [[[mainKeychain stringValueForKey:key error:nil] should] equal:dbValue];
            });

            it(@"Should fill empty entries in fallback keychain", ^{
                [keychain stringValueForKey:key error:nil];
                [[[fallbackKeychain stringValueForKey:key error:nil] should] equal:dbValue];
            });
            context(@"Error", ^{
                it(@"Should not fill entries in main keychain", ^{
                    [mainKeychain stub:@selector(stringValueForKey:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[1] withValue:[NSError new]];
                        return nil;
                    }];
                    [keychain stringValueForKey:key error:nil];
                    [[[mainKeychain stringValueForKey:key error:nil] should] beNil];
                });
            });
        });

        context(@"with different values under same key", ^{
           beforeEach(^{
               [mainKeychain setStringValue:mainKeychainValue forKey:key error:nil];
               [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
               [keychain stringValueForKey:key error:nil];
           });

            it(@"should preserve filled values in main keychain", ^{
                [[[mainKeychain stringValueForKey:key error:nil] should] equal:mainKeychainValue];
            });

            it(@"should preserve filled values in fallback keychain", ^{
                [[[fallbackKeychain stringValueForKey:key error:nil] should] equal:fallbackKeychainValue];
            });
        });
        it(@"Should conform to AMAKeychainStoring", ^{
            [[fallbackKeychain should] conformToProtocol:@protocol(AMAKeychainStoring)];
        });
        
        context(@"Remove", ^{
            beforeEach(^{
                [mainKeychain setStringValue:mainKeychainValue forKey:key error:nil];
                [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
            });
            
            context(@"Check keychain", ^{
                beforeEach(^{
                    [keychain removeStringValueForKey:key error:nil];
                });
                
                it(@"should remove from main keychain", ^{
                    [[mainKeychain stringValueForKey:key error:nil] shouldBeNil];
                });
                
                it(@"must not remove from fallback(vendor) keychain", ^{
                    [[fallbackKeychain stringValueForKey:key error:nil] shouldNotBeNil];
                });
            });
            
            it(@"should call remove from db storage", ^{
                [[storage should] receive:@selector(removeValueForKey:error:) andReturn:@(YES) withArguments:dbKey, kw_any()];
                [keychain removeStringValueForKey:key error:nil];
            });
        });
        
        context(@"Add", ^{
            context(@"Empty storages", ^{
                context(@"Keychains", ^{
                    beforeEach(^{
                        BOOL result = [keychain addStringValue:mainKeychainValue forKey:key error:nil];
                        [[theValue(result) should] equal:@YES];
                    });
                    it(@"should write to main keychain", ^{
                        [[[mainKeychain stringValueForKey:key error:nil] should] equal:mainKeychainValue];
                    });
                    it(@"should write to fallback keychain", ^{
                        [[[fallbackKeychain stringValueForKey:key error:nil] should] equal:mainKeychainValue];
                    });
                });
                it(@"DB storage", ^{
                    [[storage should] receive:@selector(saveString:forKey:error:) andReturn:@(YES) withArguments:mainKeychainValue, dbKey, kw_any()];
                    BOOL result = [keychain addStringValue:mainKeychainValue forKey:key error:nil];
                    [[theValue(result) should] equal:@YES];
                });
            });
            context(@"Filled storages", ^{
                beforeEach(^{
                    [mainKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
                    [fallbackKeychain setStringValue:fallbackKeychainValue forKey:key error:nil];
                });
                context(@"Keychains", ^{
                    beforeEach(^{
                        BOOL result = [keychain addStringValue:mainKeychainValue forKey:key error:nil];
                        [[theValue(result) should] equal:@NO];
                    });
                    
                    it(@"should write to main keychain", ^{
                        [[[mainKeychain stringValueForKey:key error:nil] should] equal:fallbackKeychainValue];
                    });
                    it(@"should write to fallback keychain", ^{
                        [[[fallbackKeychain stringValueForKey:key error:nil] should] equal:fallbackKeychainValue];
                    });
                });
                it(@"DB storage", ^{
                    [[storage should] receive:@selector(stringForKey:error:) 
                                    andReturn:fallbackKeychainValue
                                withArguments:dbKey, kw_any()];
                    BOOL result = [keychain addStringValue:mainKeychainValue forKey:key error:nil];
                    [[theValue(result) should] equal:@NO];
                });
            });
        });
    });
});

SPEC_END
