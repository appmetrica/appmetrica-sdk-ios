
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAIDSyncStartupConfiguration.h"

SPEC_BEGIN(AMAIDSyncStartupConfigurationTests)

describe(@"AMAIDSyncStartupConfiguration", ^{

    NSObject<AMAKeyValueStoring> *__block storage = nil;
    AMAIDSyncStartupConfiguration *__block configuration = nil;

    beforeEach(^{
        storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        configuration = [[AMAIDSyncStartupConfiguration alloc] initWithStorage:storage];
    });

    it(@"Should have valid all keys", ^{
        NSArray *expectedKeys = @[
            @"id.sync.enabled",
            @"id.sync.requests",
            @"id.sync.launch.delay.seconds",
        ];
        NSArray *keys = [AMAIDSyncStartupConfiguration allKeys];
        [[[NSSet setWithArray:keys] should] equal:[NSSet setWithArray:expectedKeys]];
    });
    
    context(@"Bool values", ^{
        NSNumber *const value = @YES;
        beforeEach(^{
            [storage stub:@selector(boolNumberForKey:error:) andReturn:value];
        });
        context(@"idSyncEnabled", ^{
            NSString *const key = @"id.sync.enabled";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
                [configuration idSyncEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.idSyncEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
                [[theValue(configuration.idSyncEnabled) should] beNo];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.idSyncEnabled = value.boolValue;
            });
        });
    });

    context(@"Long long values", ^{
        NSNumber *const value = @(23.42);
        beforeEach(^{
            [storage stub:@selector(longLongNumberForKey:error:) andReturn:value];
        });
        context(@"launchDelaySeconds", ^{
            NSString *const key = @"id.sync.launch.delay.seconds";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
                [configuration launchDelaySeconds];
            });
            it(@"Should return valid value", ^{
                [[configuration.launchDelaySeconds should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveLongLongNumber:forKey:error:) withArguments:value, key, kw_any()];
                configuration.launchDelaySeconds = value;
            });
        });
    });

    context(@"Array values", ^{
        NSArray *const value = @[ @{ @"foo" : @"bar" }, @{ @"foo" : @"bar" } ];
        NSArray *const nonStringsValue = @[ @1, @2, @"qwe" ];
        beforeEach(^{
            [storage stub:@selector(jsonArrayForKey:error:) andReturn:value];
        });

        context(@"requests", ^{
            NSString *const key = @"id.sync.requests";
            it(@"Should use valid key", ^{
                [[storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
                [configuration requests];
            });
            it(@"Should return valid value", ^{
                [[configuration.requests should] equal:value];
            });
            it(@"Should save valid value", ^{
                [[storage should] receive:@selector(saveJSONArray:forKey:error:) withArguments:value, key, kw_any()];
                configuration.requests = value;
            });
            context(@"Non-dict", ^{
                beforeEach(^{
                    [storage stub:@selector(jsonArrayForKey:error:) andReturn:nonStringsValue];
                });
                it(@"Should return nil", ^{
                    [[configuration.requests should] beNil];
                });
            });
        });

    });
});

SPEC_END
