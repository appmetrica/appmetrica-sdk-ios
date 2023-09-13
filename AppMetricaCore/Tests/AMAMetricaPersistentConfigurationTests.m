
#import <UIKit/UIKit.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMockDatabase.h"
#import "AMAKeychain.h"
#import "AMAKeychainBridgeMock.h"
#import "AMAEnvironmentContainer.h"
#import "AMAStartupPermission.h"
#import "AMAStorageKeys.h"
#import "AMAAttributionModelConfiguration.h"

SPEC_BEGIN(AMAMetricaPersistentConfigurationTests)

describe(@"AMAMetricaPersistentConfiguration", ^{
    double floatingComparisonDelta = 1e-5;
    id<AMADatabaseProtocol> __block database = nil;
    AMAKeychain *__block keychain = nil;
    AMAMetricaInMemoryConfiguration *__block inMemory = nil;
    id<AMAKeyValueStoring> __block storage = nil;

    AMAMetricaPersistentConfiguration *(^createConfig)(void) = ^{
        return [[AMAMetricaPersistentConfiguration alloc] initWithStorage:database.storageProvider.syncStorage
                                                                 keychain:keychain
                                                    inMemoryConfiguration:inMemory];
    };

    beforeEach(^{
        database = [AMAMockDatabase configurationDatabase];
        keychain = [[AMAKeychain alloc] initWithService:@"a"
                                            accessGroup:@"b"
                                                 bridge:[[AMAKeychainBridgeMock alloc] init]];
        inMemory = [AMAMetricaInMemoryConfiguration nullMock];
        storage = database.storageProvider.syncStorage;
    });

    context(@"Saves startup update date", ^{
        NSString *const key = @"startup.updated_at";
        NSDate *updateDate = [NSDate date];
        it(@"Should save update date in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            config.startupUpdatedAt = updateDate;
            NSDate *savedDate = [database.storageProvider.syncStorage dateForKey:AMAStorageStringKeyStartupUpdatedAt
                                                                           error:nil];

            NSTimeInterval savedInterval = [savedDate timeIntervalSince1970];
            NSTimeInterval expectedInterval = [updateDate timeIntervalSince1970];
            [[theValue(savedInterval) should] equal:expectedInterval withDelta:floatingComparisonDelta];
        });
    });
    context(@"Saves first startup update date", ^{
        NSDate *firstUpdateDate = [NSDate date];
        NSString *const key = @"startup.first_update.date";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(dateForKey:error:) withArguments:key, kw_any()];
            [config firstStartupUpdateDate];
        });
        it(@"Should return nil initially", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            NSDate *savedDate = config.firstStartupUpdateDate;
            [[savedDate should] beNil];
        });
        it(@"Should save first update date in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            config.firstStartupUpdateDate = firstUpdateDate;
            NSDate *savedDate = config.firstStartupUpdateDate;

            NSTimeInterval savedInterval = [savedDate timeIntervalSince1970];
            NSTimeInterval expectedInterval = [firstUpdateDate timeIntervalSince1970];
            [[theValue(savedInterval) should] equal:expectedInterval withDelta:floatingComparisonDelta];
        });
    });
    context(@"Saves deviceID", ^{
        NSString *deviceID = @"550e8400-e29b-41d4-a716-446655440000";
        it(@"Should save deviceID", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            config.deviceID = deviceID;
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[anotherConfig.deviceID should] equal:deviceID];
        });
        it(@"Should use ifv as device id", ^{
            NSUUID *stubUUID = [[NSUUID alloc] initWithUUIDString:@"550e8400-e29b-41d4-a716-446655440001"];
            UIDevice *stubDevice = [UIDevice new];
            [stubDevice stub:@selector(identifierForVendor) andReturn:stubUUID];
            [UIDevice stub:@selector(currentDevice) andReturn:stubDevice];

            AMAMetricaPersistentConfiguration *config = createConfig();
            [[config.deviceID should] equal:stubUUID.UUIDString];
        });
    });
    context(@"Saves deviceIDHash", ^{
        NSString *deviceIDHash = @"160518";
        it(@"Should save deviceIDHash", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            config.deviceIDHash = deviceIDHash;
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[anotherConfig.deviceIDHash should] equal:deviceIDHash];
        });
    });
    context(@"userStartupHosts", ^{
        NSArray *const values = @[ @"a", @"b" ];
        NSString *const key = @"user.startup.hosts";
        it(@"Should return valid value", ^{
            [database.storageProvider.syncStorage saveJSONArray:values forKey:key error:nil];
            [[createConfig().userStartupHosts should] equal:values];
        });
        it(@"Should save value", ^{
            createConfig().userStartupHosts = values;
            [[[database.storageProvider.cachingStorage jsonArrayForKey:key error:nil] should] equal:values];
        });
        context(@"Non-strings", ^{
            NSArray *const nonStringsValue = @[ @1, @2 ];
            NSString *const invalidSourceValue = @"[1,2]";
            beforeEach(^{
                [database.storageProvider.syncStorage saveString:invalidSourceValue forKey:key error:nil];
            });
            it(@"Should return nil", ^{
                [[createConfig().userStartupHosts should] beNil];
            });
        });
    });

    context(@"lastPermissionsUpdateDate", ^{
        NSDate *const lastPermissionsUpdateDate = [NSDate dateWithTimeIntervalSince1970:23];
        NSString *const key = @"permissions.collecting.last_update_date";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(dateForKey:error:) withArguments:key, kw_any()];
            [config lastPermissionsUpdateDate];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setLastPermissionsUpdateDate:lastPermissionsUpdateDate];
            [[[config lastPermissionsUpdateDate] should] equal:lastPermissionsUpdateDate];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setLastPermissionsUpdateDate:lastPermissionsUpdateDate];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig lastPermissionsUpdateDate] should] equal:lastPermissionsUpdateDate];
        });
        it(@"Should save nil", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setLastPermissionsUpdateDate:lastPermissionsUpdateDate];
            [config setLastPermissionsUpdateDate:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig lastPermissionsUpdateDate] should] beNil];
        });
    });
    
    context(@"extensionsLastReportDate", ^{
        NSDate *const extensionsLastReportDate = [NSDate dateWithTimeIntervalSince1970:22];
        NSString *const key = @"extensions.reporting.last.date";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(dateForKey:error:) withArguments:key, kw_any()];
            [config extensionsLastReportDate];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setExtensionsLastReportDate:extensionsLastReportDate];
            [[[config extensionsLastReportDate] should] equal:extensionsLastReportDate];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setExtensionsLastReportDate:extensionsLastReportDate];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig extensionsLastReportDate] should] equal:extensionsLastReportDate];
        });
        it(@"Should save nil", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setExtensionsLastReportDate:extensionsLastReportDate];
            [config setExtensionsLastReportDate:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig extensionsLastReportDate] should] beNil];
        });
    });

    context(@"registerForAttributionTime", ^{
        NSDate *const time = [NSDate dateWithTimeIntervalSince1970:24];
        NSString *const key = @"register.for.attribution.time";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(dateForKey:error:) withArguments:key, kw_any()];
            [config registerForAttributionTime];
        });
        it(@"Should be nil by default", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[[config registerForAttributionTime] should] beNil];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setRegisterForAttributionTime:time];
            [[[config registerForAttributionTime] should] equal:time];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setRegisterForAttributionTime:time];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig registerForAttributionTime] should] equal:time];
        });
        it(@"Should save nil", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setRegisterForAttributionTime:time];
            [config setRegisterForAttributionTime:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig registerForAttributionTime] should] beNil];
        });
    });
    context(@"eventCountsByKey", ^{
        NSDictionary *dict = @{
            @"11" : @23,
            @"22" : @24
        };
        NSString *const key = @"event.counts.by.key";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(jsonDictionaryForKey:error:) withArguments:key, kw_any()];
            [config eventCountsByKey];
        });
        it(@"Should be nil by default", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[[config eventCountsByKey] should] beNil];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventCountsByKey:dict];
            [[[config eventCountsByKey] should] equal:dict];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventCountsByKey:dict];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig eventCountsByKey] should] equal:dict];
        });
        it(@"Should save nil", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventCountsByKey:dict];
            [config setEventCountsByKey:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig eventCountsByKey] should] beNil];
        });
    });

    context(@"eventSum", ^{
        NSDecimalNumber *eventSum = [NSDecimalNumber decimalNumberWithString:@"878787"];
        NSString *const key = @"events.sum";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(stringForKey:error:) withArguments:key, kw_any()];
            [config eventSum];
        });
        it(@"Should be 0 by default", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[[config eventSum] should] beZero];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventSum:eventSum];
            [[[config eventSum] should] equal:eventSum];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventSum:eventSum];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig eventSum] should] equal:eventSum];
        });
        it(@"Should save zero", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setEventSum:eventSum];
            [config setEventSum:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig eventSum] should] beZero];
        });
    });

    context(@"conversionValue", ^{
        NSNumber *value = @767676;
        NSString *const key = @"conversion.value";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(longLongNumberForKey:error:) withArguments:key, kw_any()];
            [config conversionValue];
        });
        it(@"Should be nil by default", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[[config conversionValue] should] beNil];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setConversionValue:value];
            [[[config conversionValue] should] equal:value];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setConversionValue:value];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig conversionValue] should] equal:value];
        });
        it(@"Should save nil", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setConversionValue:value];
            [config setConversionValue:nil];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[[anotherConfig conversionValue] should] beNil];
        });
    });

    context(@"checkedInitialAttribution", ^{
        NSString *const key = @"checked.initial.attribution";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
            [config checkedInitialAttribution];
        });
        it(@"Should be NO by default", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[theValue([config checkedInitialAttribution]) should] beNo];
        });
        it(@"Should save in memory", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setCheckedInitialAttribution:YES];
            [[theValue([config checkedInitialAttribution]) should] beYes];
        });
        it(@"Should save in database", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setCheckedInitialAttribution:YES];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[theValue([anotherConfig checkedInitialAttribution]) should] beYes];
        });
        it(@"Should save NO", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [config setCheckedInitialAttribution:YES];
            [config setCheckedInitialAttribution:NO];
            AMAMetricaPersistentConfiguration *anotherConfig = createConfig();
            [[theValue([anotherConfig checkedInitialAttribution]) should] beNo];
        });
    });
    context(@"revenueTransactionIds", ^{
        NSArray *const values = @[ @"a", @"b" ];
        NSString *const key = @"revenue.transaction.ids";
        it(@"Should use valid key", ^{
            AMAMetricaPersistentConfiguration *config = createConfig();
            [[(NSObject *)storage should] receive:@selector(jsonArrayForKey:error:) withArguments:key, kw_any()];
            [config revenueTransactionIds];
        });
        it(@"Should return valid value", ^{
            [database.storageProvider.syncStorage saveJSONArray:values forKey:key error:nil];
            [[createConfig().revenueTransactionIds should] equal:values];
        });
        it(@"Should save value", ^{
            createConfig().revenueTransactionIds = values;
            [[[database.storageProvider.cachingStorage jsonArrayForKey:key error:nil] should] equal:values];
        });
        context(@"Non-strings", ^{
            NSString *const invalidSourceValue = @"[1,2]";
            beforeEach(^{
                [database.storageProvider.syncStorage saveString:invalidSourceValue forKey:key error:nil];
            });
            it(@"Should return nil", ^{
                [[createConfig().revenueTransactionIds should] beNil];
            });
        });
    });
    context(@"attributionModel", ^{
        NSDictionary *dictionary = @{ @"aaa" : @"bbb" };
        AMAAttributionModelConfiguration *__block allocedModel = nil;
        NSString *const key = @"attribution.model";
        context(@"Read", ^{
            beforeEach(^{
                [database.storageProvider.syncStorage saveJSONDictionary:dictionary
                                                                  forKey:key
                                                                   error:NULL];
                allocedModel = [AMAAttributionModelConfiguration nullMock];
                [AMAAttributionModelConfiguration stub:@selector(alloc) andReturn:allocedModel];
            });
            it(@"Should use valid key", ^{
                AMAMetricaPersistentConfiguration *config = createConfig();
                [[(NSObject *)storage should] receive:@selector(jsonDictionaryForKey:error:) withArguments:key, kw_any()];
                [config attributionModelConfiguration];
            });
            it(@"Should return nil", ^{
                [allocedModel stub:@selector(initWithJSON:) andReturn:nil withArguments:dictionary];
                [[createConfig().attributionModelConfiguration should] beNil];
            });
            it(@"Should return valid object", ^{
                AMAAttributionModelConfiguration *model = [AMAAttributionModelConfiguration nullMock];
                [allocedModel stub:@selector(initWithJSON:) andReturn:model withArguments:dictionary];
                [[createConfig().attributionModelConfiguration should] equal:model];
            });
        });
        context(@"Save", ^{
            it(@"Should save nil", ^{
                createConfig().attributionModelConfiguration = nil;
                [[[database.storageProvider.syncStorage jsonDictionaryForKey:key error:NULL] should] beNil];
            });
            it(@"Should save valid object", ^{
                AMAAttributionModelConfiguration *model = [AMAAttributionModelConfiguration nullMock];
                [model stub:@selector(JSON) andReturn:dictionary];
                createConfig().attributionModelConfiguration = model;
                [[[database.storageProvider.syncStorage jsonDictionaryForKey:key error:NULL] should] equal:dictionary];
            });
        });
    });
    
    context(@"hadFirstStartup", ^{
        NSNumber *const value = @YES;
        NSString *const key = @"startup.had.first";
        AMAMetricaPersistentConfiguration *__block configuration = nil;
        beforeEach(^{
            [(NSObject *)storage stub:@selector(boolNumberForKey:error:) andReturn:value];
            configuration = createConfig();
        });
        
        it(@"Should use valid key", ^{
            [[(NSObject *)storage should] receive:@selector(boolNumberForKey:error:) withArguments:key, kw_any()];
            [configuration hadFirstStartup];
        });
        it(@"Should return valid value", ^{
            [[theValue(configuration.hadFirstStartup) should] beYes];
        });
        it(@"Should return NO by default", ^{
            [(NSObject *)storage stub:@selector(boolNumberForKey:error:) andReturn:nil];
            [[theValue(configuration.hadFirstStartup) should] beNo];
        });
        it(@"Should save valid value", ^{
            [[(NSObject *)storage should] receive:@selector(saveBoolNumber:forKey:error:) withArguments:value, key, kw_any()];
            configuration.hadFirstStartup = value.boolValue;
        });
    });
});

SPEC_END
