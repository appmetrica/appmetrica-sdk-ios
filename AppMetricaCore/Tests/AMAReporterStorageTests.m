
#import <Kiwi/Kiwi.h>
#import "AMAReporterStorage.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseProtocol.h"
#import "AMAEvent.h"
#import "AMAEventSerializer.h"
#import "AMASessionSerializer.h"
#import "AMAReporterStateStorage.h"
#import "AMASessionStorage.h"
#import "AMAEventStorage.h"
#import "AMAReportRequestProvider.h"
#import "AMASharedReporterProvider.h"
#import "AMAEventsCleaner.h"
#import "AMASessionsCleaner.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAEnvironmentContainer.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAReporterStorageTests)

describe(@"AMAReporterStorage", ^{

    NSString *const apiKey = @"API_KEY";

    AMAReporterStoragesContainer *__block storagesContainer = nil;
    AMAEnvironmentContainer *__block eventEnvironment = nil;
    NSObject<AMADatabaseProtocol> *__block database = nil;
    NSObject<AMADatabaseKeyValueStorageProviding> *__block storageProvider = nil;
    AMAEventSerializer *__block eventSerializer = nil;
    AMASharedReporterProvider *__block reporterProvider = nil;
    AMAEventsCleaner *__block eventsCleaner = nil;
    AMASessionSerializer *__block sessionSerializer = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMASessionStorage *__block sessionStorage = nil;
    AMAEventStorage *__block eventStorage = nil;
    AMAReportRequestProvider *__block reportRequestProvider = nil;
    AMASessionsCleaner *__block sessionCleaner = nil;
    AMAReporterStorage *__block storage = nil;

    beforeEach(^{
        storagesContainer = [AMAReporterStoragesContainer nullMock];
        [AMAReporterStoragesContainer stub:@selector(sharedInstance) andReturn:storagesContainer];
        eventEnvironment = [AMAEnvironmentContainer nullMock];
        database = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
        [AMADatabaseFactory stub:@selector(reporterDatabaseForApiKey:main:eventsCleaner:) andReturn:database];
        storageProvider = [KWMock nullMockForProtocol:@protocol(AMADatabaseKeyValueStorageProviding)];
        [database stub:@selector(storageProvider) andReturn:storageProvider];

        reporterProvider = [AMASharedReporterProvider stubbedNullMockForInit:@selector(initWithApiKey:)];
        eventSerializer = [AMAEventSerializer stubbedNullMockForDefaultInit];
        sessionSerializer = [AMASessionSerializer stubbedNullMockForDefaultInit];
        stateStorage = [AMAReporterStateStorage stubbedNullMockForInit:@selector(initWithStorageProvider:eventEnvironment:)];
        sessionStorage = [AMASessionStorage stubbedNullMockForInit:@selector(initWithDatabase:serializer:stateStorage:)];
        eventStorage = [AMAEventStorage stubbedNullMockForInit:@selector(initWithDatabase:eventSerializer:)];
        reportRequestProvider =
            [AMAReportRequestProvider stubbedNullMockForInit:@selector(initWithApiKey:database:eventSerializer:sessionSerializer:)];
        eventsCleaner = [AMAEventsCleaner stubbedNullMockForInit:@selector(initWithReporterProvider:)];
        sessionCleaner = [AMASessionsCleaner stubbedNullMockForInit:@selector(initWithDatabase:eventsCleaner:apiKey:)];
    });

    void (^createStorage)(void) = ^{
        storage = [[AMAReporterStorage alloc] initWithApiKey:apiKey eventEnvironment:eventEnvironment main:YES];
    };

    it(@"Should create valid reporter provider", ^{
        [[reporterProvider should] receive:@selector(initWithApiKey:) withArguments:apiKey];
        createStorage();
    });

    it(@"Should create valid events cleaner", ^{
        [[eventsCleaner should] receive:@selector(initWithReporterProvider:) withArguments:reporterProvider];
        createStorage();
    });

    it(@"Should create valid database", ^{
        [[AMADatabaseFactory should] receive:@selector(reporterDatabaseForApiKey:main:eventsCleaner:)
                               withArguments:apiKey, theValue(YES), eventsCleaner];
        createStorage();
    });
    it(@"Should create valid state storage", ^{
        [[stateStorage should] receive:@selector(initWithStorageProvider:eventEnvironment:)
                         withArguments:storageProvider, eventEnvironment];
        createStorage();
    });
    it(@"Should create valid event storage", ^{
        [[eventStorage should] receive:@selector(initWithDatabase:eventSerializer:)
                         withArguments:database, eventSerializer];
        createStorage();
    });
    it(@"Should create valid session storage", ^{
        [[sessionStorage should] receive:@selector(initWithDatabase:serializer:stateStorage:)
                           withArguments:database, sessionSerializer, stateStorage];
        createStorage();
    });
    it(@"Should return valid report request provider", ^{
        [[reportRequestProvider should] receive:@selector(initWithApiKey:database:eventSerializer:sessionSerializer:)
                                  withArguments:apiKey, database, eventSerializer, sessionSerializer];
        createStorage();
        __unused id _ = storage.reportRequestProvider;
    });
    it(@"Should create valid session cleaner", ^{
        [[sessionCleaner should] receive:@selector(initWithDatabase:eventsCleaner:apiKey:)
                           withArguments:database, eventsCleaner, apiKey];
        createStorage();
    });
    
    it(@"Should update api key", ^{
        NSString *const newApiKey = @"NEW_API_KEY";
        createStorage();
        [storage updateAPIKey:newApiKey];
        [[storage.apiKey should] equal:newApiKey];
    });

    context(@"Created storage", ^{
        beforeEach(^{
            createStorage();
        });
        it(@"Should have valid state storage", ^{
            [[storage.stateStorage should] equal:stateStorage];
        });
        it(@"Should have valid event storage", ^{
            [[storage.eventStorage should] equal:eventStorage];
        });
        it(@"Should have valid session storage", ^{
            [[storage.sessionStorage should] equal:sessionStorage];
        });
        it(@"Should have valid report request provider", ^{
            [[storage.reportRequestProvider should] equal:reportRequestProvider];
        });
        it(@"Should have valid session cleaner", ^{
            [[storage.sessionsCleaner should] equal:sessionCleaner];
        });
        it(@"Should have valid storage provider", ^{
            [[((NSObject *)storage.keyValueStorageProvider) should] equal:storageProvider];
        });
        it(@"Should create storage in DB", ^{
            id db = [KWMock nullMock];
            id kvStorage = [KWMock nullMock];
            [database stub:@selector(inDatabase:) withBlock:^id(NSArray *params) {
                void (^block)(AMAFMDatabase *db) = params[0];
                block(db);
                return nil;
            }];
            [[storageProvider should] receive:@selector(storageForDB:) andReturn:kvStorage withArguments:db];
            [storage storageInDatabase:^(id<AMAKeyValueStoring>  _Nonnull kv) {
                [[((NSObject *)kv) should] equal:kvStorage];
            }];
        });
        context(@"Restore state", ^{
            it(@"Should wait for migration", ^{
                [[storagesContainer should] receive:@selector(waitMigrationForApiKey:) withArguments:apiKey];
                [storage restoreState];
            });
            it(@"Should restore state of state storage", ^{
                [[stateStorage should] receive:@selector(restoreState)];
                [storage restoreState];
            });
        });
    });

});

SPEC_END

