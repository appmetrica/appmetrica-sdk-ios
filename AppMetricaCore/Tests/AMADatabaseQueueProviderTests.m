
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseQueueProvider.h"
#import <sqlite3.h>
#import "AMAAppMetrica+Internal.h"
#import "AMAInternalEventsReporter.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

SPEC_BEGIN(AMADatabaseQueueProviderTests)

describe(@"AMADatabaseQueueProvider", ^{

    NSString *const fileName = @"db.sqlite";
    NSString *const path = [@"/path/to" stringByAppendingPathComponent:fileName];

    NSFileManager *__block fileManager = nil;
    AMAFMDatabaseQueue *__block databaseQueue = nil;
    AMAFMDatabase *__block database = nil;
    AMAInternalEventsReporter *__block reporter = nil;
    AMADatabaseQueueProvider *__block provider = nil;

    beforeEach(^{
        [AMAFileUtility stub:@selector(createPathIfNeeded:)];
        [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(NO)];

        fileManager = [NSFileManager nullMock];
        [fileManager stub:@selector(setAttributes:ofItemAtPath:error:) andReturn:theValue(YES)];
        [NSFileManager stub:@selector(defaultManager) andReturn:fileManager];

        database = [AMAFMDatabase nullMock];
        databaseQueue = [AMAFMDatabaseQueue stubbedNullMockForInit:@selector(initWithPath:flags:)];
        [databaseQueue stub:@selector(inDatabase:) withBlock:^id(NSArray *params) {
            void (^block)(AMAFMDatabase *db) = params[0];
            if (block != nil) {
                block(database);
            }
            return nil;
        }];

        reporter = [AMAInternalEventsReporter nullMock];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:reporter];

        provider = [[AMADatabaseQueueProvider alloc] init];
    });

    it(@"Should create path", ^{
        [[AMAFileUtility should] receive:@selector(createPathIfNeeded:) withArguments:@"/path/to"];
        [provider queueForPath:path];
    });

    it(@"Should remove protection", ^{
        [[fileManager should] receive:@selector(setAttributes:ofItemAtPath:error:)
                        withArguments:@{ NSFileProtectionKey: NSFileProtectionNone }, path, kw_any()];
        [provider queueForPath:path];
    });

    it(@"Should disable backups", ^{
        [[AMAFileUtility should] receive:@selector(setSkipBackupAttributesOnPath:)
                           withArguments:path];
        [provider queueForPath:path];
    });

    it(@"Should create queue with valid arguments", ^{
        int flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE;
        [[databaseQueue should] receive:@selector(initWithPath:flags:) withArguments:path, theValue(flags)];
        [provider queueForPath:path];
    });

    it(@"Should add nolock flag in extenstion", ^{
        [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(YES)];
        [[databaseQueue should] receive:@selector(initWithPath:flags:)
                          withArguments:@"file:/path/to/db.sqlite?nolock=1", kw_any()];
        [provider queueForPath:path];
    });

    it(@"Should add auto_vacuum pragma", ^{
        [[database should] receive:@selector(executeUpdate:) withArguments:@"PRAGMA auto_vacuum=FULL"];
        [provider queueForPath:path];
    });

    context(@"Logs", ^{
        it(@"Should disable logs by default", ^{
            [[database should] receive:@selector(setLogsErrors:) withArguments:theValue(NO)];
            [provider queueForPath:path];
        });
        it(@"Should enable logs on queue creation", ^{
            [[database should] receive:@selector(setLogsErrors:) withArguments:theValue(YES)];
            provider.logsEnabled = YES;
            [provider queueForPath:path];
        });
        it(@"Should enable logs after queue creation", ^{
            [[database should] receive:@selector(setLogsErrors:) withArguments:theValue(YES)];
            [provider queueForPath:path];
            provider.logsEnabled = YES;
        });
        it(@"Should not set logs enabled twice", ^{
            provider.logsEnabled = YES;
            [provider queueForPath:path];
            [[databaseQueue shouldNot] receive:@selector(inDatabase:)];
            provider.logsEnabled = YES;
        });
    });
});

SPEC_END

