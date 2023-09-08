
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseIntegrityManager.h"
#import "AMADatabaseIntegrityStorageFactory.h"
#import "AMADatabaseIntegrityStorage.h"
#import "AMADatabaseIntegrityProcessor.h"
#import "AMADatabaseIntegrityReport.h"
#import "AMADatabaseQueueProvider.h"
@import FMDB;

SPEC_BEGIN(AMADatabaseIntegrityManagerTests)

describe(@"AMADatabaseIntegrityManager", ^{

    NSString *const databasePath = @"/path/to/database";

    FMDatabaseQueue *__block database = nil;
    AMADatabaseQueueProvider *__block databaseProvider = nil;
    AMADatabaseIntegrityReport *__block report = nil;

    NSObject<AMADatabaseIntegrityManagerDelegate> *__block delegate = nil;

    AMADatabaseIntegrityStorage *__block storage = nil;
    AMADatabaseIntegrityProcessor *__block processor = nil;
    AMADatabaseIntegrityManager *__block manager = nil;

    beforeEach(^{
        database = [FMDatabaseQueue nullMock];
        databaseProvider = [AMADatabaseQueueProvider nullMock];
        [databaseProvider stub:@selector(queueForPath:) andReturn:database];
        [AMADatabaseQueueProvider stub:@selector(sharedInstance) andReturn:databaseProvider];

        [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];

        report = [AMADatabaseIntegrityReport stubInstance:[[AMADatabaseIntegrityReport alloc] init]
                                                  forInit:@selector(init)];

        delegate = [KWMock nullMockForProtocol:@protocol(AMADatabaseIntegrityManagerDelegate)];

        storage = [AMADatabaseIntegrityStorage nullMock];
        processor = [AMADatabaseIntegrityProcessor nullMock];
        [processor stub:@selector(checkIntegrityIssuesForDatabase:report:) andReturn:theValue(NO)];
        [processor stub:@selector(fixIndexForDatabase:report:) andReturn:theValue(NO)];
        [processor stub:@selector(fixWithBackupAndRestore:report:) andReturn:theValue(NO)];
        [processor stub:@selector(fixWithCreatingNewDatabase:report:) andReturn:theValue(NO)];

        manager = [[AMADatabaseIntegrityManager alloc] initWithDatabasePath:databasePath
                                                                    storage:storage
                                                                  processor:processor];
        manager.delegate = delegate;
    });

    __auto_type stubProcessor = ^(SEL selector, BOOL(^block)(AMADatabaseIntegrityReport *)) {
        [processor stub:selector withBlock:^id(NSArray *params) {
            AMADatabaseIntegrityReport *currentReport = params[1];
            return theValue(block(currentReport));
        }];
    };

    context(@"Success", ^{
        beforeEach(^{
            stubProcessor(@selector(checkIntegrityIssuesForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                r.firstPassedFixStep = kAMADatabaseIntegrityStepInitial;
                return YES;
            });
        });
        it(@"Should return valid queue", ^{
            [[[manager databaseWithEnsuredIntegrityWithIsNew:NULL] should] equal:database];
        });
        it(@"Should check valid file path", ^{
            [[AMAFileUtility should] receive:@selector(fileExistsAtPath:) withArguments:databasePath];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should mark as new if file not exists", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
            BOOL isNew = NO;
            [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
            [[theValue(isNew) should] beYes];
        });
        it(@"Should not mark as new if file exists", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
            BOOL isNew = NO;
            [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
            [[theValue(isNew) should] beNo];
        });
        it(@"Should not call delegate to save context", ^{
            [[delegate shouldNot] receive:@selector(contextForIntegrityManager:thatWillDropDatabase:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not call delegate to restore context", ^{
            [[delegate shouldNot] receive:@selector(integrityManager:didCreateNewDatabase:context:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not apply reindex", ^{
            [[processor shouldNot] receive:@selector(fixIndexForDatabase:report:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not apply backup and resore", ^{
            [[processor shouldNot] receive:@selector(fixWithBackupAndRestore:report:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not create new database", ^{
            [[processor shouldNot] receive:@selector(fixWithCreatingNewDatabase:report:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
    });

    context(@"Reindex helps", ^{
        beforeEach(^{
            stubProcessor(@selector(fixIndexForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                r.lastAppliedFixStep = kAMADatabaseIntegrityStepReindex;
                return YES;
            });
            stubProcessor(@selector(checkIntegrityIssuesForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                r.firstPassedFixStep = kAMADatabaseIntegrityStepReindex;
                return [r.lastAppliedFixStep isEqualToString:kAMADatabaseIntegrityStepReindex];
            });
        });
        it(@"Should return valid queue", ^{
            [[[manager databaseWithEnsuredIntegrityWithIsNew:NULL] should] equal:database];
        });
        it(@"Should mark as new if file not exists", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
            BOOL isNew = NO;
            [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
            [[theValue(isNew) should] beYes];
        });
        it(@"Should not mark as new if file exists", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
            BOOL isNew = NO;
            [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
            [[theValue(isNew) should] beNo];
        });
        it(@"Should not call delegate to save context", ^{
            [[delegate shouldNot] receive:@selector(contextForIntegrityManager:thatWillDropDatabase:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not call delegate to restore context", ^{
            [[delegate shouldNot] receive:@selector(integrityManager:didCreateNewDatabase:context:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should apply reindex", ^{
            [[processor should] receive:@selector(fixIndexForDatabase:report:)
                          withArguments:database, report];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not apply backup and resore", ^{
            [[processor shouldNot] receive:@selector(fixWithBackupAndRestore:report:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
        it(@"Should not create new database", ^{
            [[processor shouldNot] receive:@selector(fixWithCreatingNewDatabase:report:)];
            [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
        });
    });

    context(@"New database", ^{
        FMDatabaseQueue *__block newDatabase = nil;

        beforeEach(^{
            newDatabase = [FMDatabaseQueue nullMock];
        });

        __auto_type stubProcessorWithNewDatabase = ^(SEL selector, BOOL(^block)(AMADatabaseIntegrityReport *)) {
            [processor stub:selector withBlock:^id(NSArray *params) {
                AMADatabaseIntegrityReport *currentReport = params[1];
                [AMATestUtilities fillObjectPointerParameter:params[0] withValue:newDatabase];
                return theValue(block(currentReport));
            }];
        };

        context(@"Backup and restore helps", ^{
            beforeEach(^{
                stubProcessorWithNewDatabase(@selector(fixWithBackupAndRestore:report:), ^(AMADatabaseIntegrityReport *r) {
                    r.lastAppliedFixStep = kAMADatabaseIntegrityStepBackupRestore;
                    return YES;
                });
                stubProcessor(@selector(checkIntegrityIssuesForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                    r.firstPassedFixStep = kAMADatabaseIntegrityStepBackupRestore;
                    return [r.lastAppliedFixStep isEqualToString:kAMADatabaseIntegrityStepBackupRestore];
                });
            });
            it(@"Should return valid queue", ^{
                [[[manager databaseWithEnsuredIntegrityWithIsNew:NULL] should] equal:newDatabase];
            });
            it(@"Should mark as new if file not exists", ^{
                [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
                BOOL isNew = NO;
                [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
                [[theValue(isNew) should] beYes];
            });
            it(@"Should not mark as new if file exists", ^{
                [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
                BOOL isNew = NO;
                [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
                [[theValue(isNew) should] beNo];
            });
            it(@"Should call delegate to save context", ^{
                [[delegate should] receive:@selector(contextForIntegrityManager:thatWillDropDatabase:)
                             withArguments:manager, database];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should call delegate to restore context", ^{
                [delegate stub:@selector(contextForIntegrityManager:thatWillDropDatabase:)
                     andReturn:@{ @"foo": @"bar" }];
                [[delegate should] receive:@selector(integrityManager:didCreateNewDatabase:context:)
                             withArguments:manager, newDatabase, @{ @"foo": @"bar" }];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply reindex", ^{
                [[processor should] receive:@selector(fixIndexForDatabase:report:)
                              withArguments:database, report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply backup and resore", ^{
                [[processor should] receive:@selector(fixWithBackupAndRestore:report:)
                              withArguments:kw_any(), report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should not create new database", ^{
                [[processor shouldNot] receive:@selector(fixWithCreatingNewDatabase:report:)];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
        });

        context(@"New database helps", ^{
            beforeEach(^{
                stubProcessorWithNewDatabase(@selector(fixWithCreatingNewDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                    r.lastAppliedFixStep = kAMADatabaseIntegrityStepNewDatabase;
                    return YES;
                });
                stubProcessor(@selector(checkIntegrityIssuesForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                    r.firstPassedFixStep = kAMADatabaseIntegrityStepNewDatabase;
                    return [r.lastAppliedFixStep isEqualToString:kAMADatabaseIntegrityStepNewDatabase];
                });
            });
            it(@"Should return valid queue", ^{
                [[[manager databaseWithEnsuredIntegrityWithIsNew:NULL] should] equal:newDatabase];
            });
            it(@"Should mark as new if file not exists", ^{
                [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
                BOOL isNew = NO;
                [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
                [[theValue(isNew) should] beYes];
            });
            it(@"Should mark as new if file exists", ^{
                [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
                BOOL isNew = NO;
                [manager databaseWithEnsuredIntegrityWithIsNew:&isNew];
                [[theValue(isNew) should] beYes];
            });
            it(@"Should call delegate to save context", ^{
                [[delegate should] receive:@selector(contextForIntegrityManager:thatWillDropDatabase:)
                             withArguments:manager, database];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should call delegate to restore context", ^{
                [delegate stub:@selector(contextForIntegrityManager:thatWillDropDatabase:)
                     andReturn:@{ @"foo": @"bar" }];
                [[delegate should] receive:@selector(integrityManager:didCreateNewDatabase:context:)
                             withArguments:manager, newDatabase, @{ @"foo": @"bar" }];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply reindex", ^{
                [[processor should] receive:@selector(fixIndexForDatabase:report:)
                              withArguments:database, report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply backup and resore", ^{
                [[processor should] receive:@selector(fixWithBackupAndRestore:report:)
                              withArguments:kw_any(), report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should create new database", ^{
                [[processor should] receive:@selector(fixWithCreatingNewDatabase:report:)
                              withArguments:kw_any(), report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
        });

        context(@"Nothing helps", ^{
            beforeEach(^{
                stubProcessorWithNewDatabase(@selector(fixWithCreatingNewDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                    r.lastAppliedFixStep = kAMADatabaseIntegrityStepNewDatabase;
                    return YES;
                });
                stubProcessor(@selector(checkIntegrityIssuesForDatabase:report:), ^(AMADatabaseIntegrityReport *r) {
                    return NO;
                });
            });
            it(@"Should return nil", ^{
                [[[manager databaseWithEnsuredIntegrityWithIsNew:NULL] should] beNil];
            });
            it(@"Should call delegate to save context", ^{
                [[delegate should] receive:@selector(contextForIntegrityManager:thatWillDropDatabase:)
                             withArguments:manager, database];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should not call delegate to restore context", ^{
                [[delegate shouldNot] receive:@selector(integrityManager:didCreateNewDatabase:context:)];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply reindex", ^{
                [[processor should] receive:@selector(fixIndexForDatabase:report:)
                              withArguments:database, report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should apply backup and resore", ^{
                [[processor should] receive:@selector(fixWithBackupAndRestore:report:)
                              withArguments:kw_any(), report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
            it(@"Should create new database", ^{
                [[processor should] receive:@selector(fixWithCreatingNewDatabase:report:)
                              withArguments:kw_any(), report];
                [manager databaseWithEnsuredIntegrityWithIsNew:NULL];
            });
        });
    });

});

SPEC_END
