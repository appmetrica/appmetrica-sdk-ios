
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>
#import "AMAKeychainBridgeMock.h"

SPEC_BEGIN(AMAKeychainTests)

describe(@"AMAKeychainTests", ^{

    context(@"with default identifier", ^{
        AMAKeychain *__block keychain = nil;
        AMAKeychainBridge *__block bridge = nil;

        beforeEach(^{
            bridge = [[AMAKeychainBridgeMock alloc] init];
            keychain = [[AMAKeychain alloc] initWithService:@"io.appmetrica.keychaintestidentifier"
                                                accessGroup:@""
                                                     bridge:bridge];
        });

        it(@"should store value for key", ^{
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain setStringValue:@"quux" forKey:@"baz" error:nil];

            [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
            [[[keychain stringValueForKey:@"baz" error:nil] should] equal:@"quux"];
        });

        it(@"should reset values", ^{
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain resetKeychain];

            [[[keychain stringValueForKey:@"foo" error:nil] should] beNil];
        });

        it(@"should preserve value on update with the same value", ^{
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
        });

        it(@"should update value", ^{
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain setStringValue:@"quux" forKey:@"foo" error:nil];
            [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"quux"];
        });

        it(@"Should not update existing value", ^{
            [keychain addStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain addStringValue:@"UPDATED" forKey:@"foo" error:nil];
            [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
        });

        it(@"should remove value", ^{
            [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain removeStringValueForKey:@"foo" error:nil];
            [[[keychain stringValueForKey:@"foo" error:nil] should] beNil];
        });

        it(@"Should not remove update value when setting nil", ^{
            NSString *value = nil;
            [keychain addStringValue:@"bar" forKey:@"foo" error:nil];
            [keychain setStringValue:value forKey:@"foo" error:nil];
            [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
        });

        it(@"should be available by default", ^{
            [[theValue(keychain.isAvailable) should] beTrue];
        });

        context(@"Errors", ^{
            OSStatus const errorStatus = errSecBadReq;
            NSError *__block error = nil;
            beforeEach(^{
                error = nil;
            });

            NSError *(^errorWithCode)(AMAKeychainErrorCode, OSStatus) = ^(AMAKeychainErrorCode code, OSStatus status) {
                return [NSError errorWithDomain:kAMAKeychainErrorDomain
                                           code:code
                                       userInfo:@{ kAMAKeychainErrorKeyCode: @(status) }];
            };

            context(@"Copy error", ^{
                beforeEach(^{
                    [bridge stub:@selector(copyMatchingEntryWithQuery:resultData:) andReturn:theValue(errorStatus)];
                });
                context(@"Getter", ^{
                    it(@"Should return nil in getter", ^{
                        [[[keychain stringValueForKey:@"foo" error:nil] should] beNil];
                    });
                    it(@"Should fill valid error", ^{
                        [keychain stringValueForKey:@"foo" error:&error];
                        [[error should] equal:errorWithCode(AMAKeychainErrorCodeGeneral, errorStatus)];
                    });
                });
                context(@"Setter", ^{
                    it(@"Should add key", ^{
                        [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
                        [bridge clearStubs];
                        [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
                    });
                    it(@"Should not update key", ^{
                        [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
                        [keychain setStringValue:@"UPDATED" forKey:@"foo" error:nil];
                        [bridge clearStubs];
                        [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
                    });
                });
            });
            context(@"Deserialization error", ^{
                beforeEach(^{
                    NSArray *notAString = @[ @"foo" ];
                    [keychain setStringValue:(id)notAString forKey:@"foo" error:nil];
                });
                it(@"Should return nil in getter", ^{
                    [[[keychain stringValueForKey:@"foo" error:nil] should] beNil];
                });
                it(@"Should fill error with underlying error", ^{
                    [keychain stringValueForKey:@"foo" error:&error];
                    [error.userInfo[NSUnderlyingErrorKey] shouldNotBeNil];
                });
            });
            context(@"Delete error", ^{
                beforeEach(^{
                    [bridge stub:@selector(copyMatchingEntryWithQuery:resultData:) andReturn:theValue(errorStatus)];
                });
                it(@"Should return nil in getter", ^{
                    [[[keychain stringValueForKey:@"foo" error:nil] should] beNil];
                });
                it(@"Should fill valid error", ^{
                    [keychain stringValueForKey:@"foo" error:&error];
                    [[error should] equal:errorWithCode(AMAKeychainErrorCodeGeneral, errorStatus)];
                });
            });
        });

        context(@"and aliased keychain", ^{
            let (aliasedKeychain, ^{
                return [[AMAKeychain alloc] initWithService:@"io.appmetrica.keychaintestidentifier"
                                                accessGroup:@""
                                                     bridge:bridge];
            });

            beforeEach(^{
                [aliasedKeychain resetKeychain];
            });

            it(@"should immediately store value", ^{
                [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
                [[[aliasedKeychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
            });

            it (@"should immediately get value", ^{
                [aliasedKeychain setStringValue:@"bar" forKey:@"foo" error:nil];
                [[[keychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
            });
        });

        context(@"and independent storage", ^{
            let (indiKeychain, ^{
                return [[AMAKeychain alloc] initWithService:@"io.appmetrica.keychaintestidentifier.new"
                                                accessGroup:@""
                                                     bridge:bridge];
            });

            beforeEach(^{
                [indiKeychain resetKeychain];
            });

            it(@"should not overlap set", ^{
                [keychain setStringValue:@"bar" forKey:@"foo" error:nil];
                [[[indiKeychain stringValueForKey:@"foo" error:nil] should] beNil];
            });

            it(@"should not overlap reset", ^{
                [indiKeychain setStringValue:@"bar" forKey:@"foo" error:nil];
                [keychain resetKeychain];
                [[[indiKeychain stringValueForKey:@"foo" error:nil] should] equal:@"bar"];
            });
        });
        it(@"Should conform to AMAKeychainStoring", ^{
            [[keychain should] conformToProtocol:@protocol(AMAKeychainStoring)];
        });
    });
});

SPEC_END
