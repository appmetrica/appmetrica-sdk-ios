
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseIntegrityStorage.h"
#import "AMATestKVSProvider.h"

SPEC_BEGIN(AMADatabaseIntegrityStorageTests)

describe(@"AMADatabaseIntegrityStorage", ^{

    AMADateProviderMock *__block dateProvider = nil;
    NSObject<AMAKeyValueStoring> *__block kvStorage = nil;
    AMATestKVSProvider *__block storageProvider = nil;
    AMADatabaseIntegrityStorage *__block storage = nil;

    beforeEach(^{
        dateProvider = [[AMADateProviderMock alloc] init];
        [dateProvider freezeWithDate:[NSDate dateWithTimeIntervalSince1970:42]];

        storageProvider = [[AMATestKVSProvider alloc] init];
        kvStorage = (NSObject<AMAKeyValueStoring> *)storageProvider.syncStorage;
        storage = [[AMADatabaseIntegrityStorage alloc] initWithStorageProvider:storageProvider
                                                                  dateProvider:dateProvider];
    });

    context(@"Incidents count", ^{
        NSString *const key = @"incidents_count";

        it(@"Should request value", ^{
            [[kvStorage should] receive:@selector(unsignedLongLongNumberForKey:error:)
                          withArguments:key, kw_any()];
            [storage incidentsCount];
        });
        it(@"Should return existing value", ^{
            [kvStorage saveLongLongNumber:@23 forKey:key error:NULL];
            [[theValue(storage.incidentsCount) should] equal:theValue(23)];
        });
        it(@"Should return default value", ^{
            [[theValue(storage.incidentsCount) should] equal:theValue(0)];
        });
        it(@"Should increment value", ^{
            [kvStorage saveLongLongNumber:@23 forKey:key error:NULL];
            [storage handleIncident];
            [[[kvStorage longLongNumberForKey:key error:NULL] should] equal:@24];
        });
    });

    context(@"First incident date", ^{
        NSString *const key = @"first_incident_date";

        it(@"Should request value", ^{
            [[kvStorage should] receive:@selector(dateForKey:error:)
                          withArguments:key, kw_any()];
            [storage firstIncidentDate];
        });
        it(@"Should return existing value", ^{
            [kvStorage saveDate:dateProvider.currentDate forKey:key error:NULL];
            [[storage.firstIncidentDate should] equal:dateProvider.currentDate];
        });
        it(@"Should return default value", ^{
            [[storage.firstIncidentDate should] beNil];
        });
        it(@"Should store current date if nil", ^{
            [storage handleIncident];
            [[[kvStorage dateForKey:key error:NULL] should] equal:dateProvider.currentDate];
        });
        it(@"Should store previous value if it exists", ^{
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:23];
            [kvStorage saveDate:date forKey:key error:NULL];
            [storage handleIncident];
            [[[kvStorage dateForKey:key error:NULL] should] equal:date];
        });
    });

    context(@"Last incident date", ^{
        NSString *const key = @"last_incident_date";

        it(@"Should request value", ^{
            [[kvStorage should] receive:@selector(dateForKey:error:)
                          withArguments:key, kw_any()];
            [storage lastIncidentDate];
        });
        it(@"Should return existing value", ^{
            [kvStorage saveDate:dateProvider.currentDate forKey:key error:NULL];
            [[storage.lastIncidentDate should] equal:dateProvider.currentDate];
        });
        it(@"Should return default value", ^{
            [[storage.lastIncidentDate should] beNil];
        });
        it(@"Should store current date if nil", ^{
            [storage handleIncident];
            [[[kvStorage dateForKey:key error:NULL] should] equal:dateProvider.currentDate];
        });
        it(@"Should store current date even if previous one exists", ^{
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:23];
            [kvStorage saveDate:date forKey:key error:NULL];
            [storage handleIncident];
            [[[kvStorage dateForKey:key error:NULL] should] equal:dateProvider.currentDate];
        });
    });

});

SPEC_END
