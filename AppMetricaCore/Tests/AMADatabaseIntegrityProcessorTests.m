
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseIntegrityProcessor.h"
#import "AMADatabaseIntegrityQueries.h"
#import "AMADatabaseQueueProvider.h"
#import "AMADatabaseIntegrityReport.h"
#import "AMASQLiteIntegrityIssueParser.h"
#import "AMASQLiteIntegrityIssue.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

SPEC_BEGIN(AMADatabaseIntegrityProcessorTests)

describe(@"AMADatabaseIntegrityProcessor", ^{

    NSString *const mainDBContent = @"MAIN";
    NSString *const additionalDBContent = @"ADDITIONAL";

    NSString *__block databasePath = nil;
    NSMutableArray *__block additionalDatabasePaths = nil;

    NSError *__block error = nil;
    AMADatabaseIntegrityReport *__block report = nil;
    AMASQLiteIntegrityIssue *__block issue = nil;

    AMAFMDatabaseQueue *__block database = nil;
    AMADatabaseQueueProvider *__block databaseProvider = nil;
    AMASQLiteIntegrityIssueParser *__block parser = nil;
    AMADatabaseIntegrityProcessor *__block processor = nil;

    beforeEach(^{
        error = nil;
        report = [[AMADatabaseIntegrityReport alloc] init];
        issue = [AMASQLiteIntegrityIssue nullMock];

        databasePath = [NSTemporaryDirectory() stringByAppendingString:@"AMADatabaseIntegrityProcessorTests_db"];
        [[mainDBContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:databasePath atomically:YES];

        additionalDatabasePaths = [NSMutableArray array];
        databaseProvider = [AMADatabaseQueueProvider nullMock];
        [databaseProvider stub:@selector(queueForPath:) withBlock:^id(NSArray *params) {
            NSString *path = params[0];
            if (path == nil) {
                return nil;
            }
            AMAFMDatabaseQueue *queue = [AMAFMDatabaseQueue nullMock];
            [queue stub:@selector(path) andReturn:path];
            [additionalDatabasePaths addObject:path];
            if ([NSData dataWithContentsOfFile:path] == nil) {
                [[additionalDBContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
            }
            return queue;
        }];
        [AMADatabaseQueueProvider stub:@selector(sharedInstance) andReturn:databaseProvider];

        database = [AMAFMDatabaseQueue nullMock];
        [database stub:@selector(path) andReturn:databasePath];
        
        parser = [AMASQLiteIntegrityIssueParser nullMock];
        [parser stub:@selector(issueForError:) andReturn:issue];
        [parser stub:@selector(issueForIntegityIssueString:) andReturn:issue];
        processor = [[AMADatabaseIntegrityProcessor alloc] initWithParser:parser];
    });

    afterEach(^{
        for (NSString *path in [additionalDatabasePaths arrayByAddingObject:databasePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        }
    });

    context(@"Check integrity", ^{
        NSString *const lastAppliedStep = @"LAST_APPLIED_STEP";
        NSArray *__block problems = nil;

        beforeEach(^{
            problems = @[];
            [AMADatabaseIntegrityQueries stub:@selector(integrityIssuesForDBQueue:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:error];
                return problems;
            }];
        });

        context(@"Nil database", ^{
            it(@"Should return NO", ^{
                [[theValue([processor checkIntegrityIssuesForDatabase:nil report:report]) should] beNo];
            });
            it(@"Should not parse issues", ^{
                [[parser shouldNot] receive:@selector(issueForIntegityIssueString:)];
                [processor checkIntegrityIssuesForDatabase:nil report:report];
            });
            it(@"Should not parse error", ^{
                [[parser shouldNot] receive:@selector(issueForError:)];
                [processor checkIntegrityIssuesForDatabase:nil report:report];
            });
            it(@"Should not store step", ^{
                [processor checkIntegrityIssuesForDatabase:nil report:report];
                [[report.stepIssues should] beEmpty];
            });
            it(@"Should not change first passing step", ^{
                [processor checkIntegrityIssuesForDatabase:nil report:report];
                [[report.firstPassedFixStep should] beNil];
            });
        });
        context(@"No problems", ^{
            it(@"Should return YES", ^{
                [[theValue([processor checkIntegrityIssuesForDatabase:database report:report]) should] beYes];
            });
            it(@"Should not parse issues", ^{
                [[parser shouldNot] receive:@selector(issueForIntegityIssueString:)];
                [processor checkIntegrityIssuesForDatabase:database report:report];
            });
            it(@"Should not parse error", ^{
                [[parser shouldNot] receive:@selector(issueForError:)];
                [processor checkIntegrityIssuesForDatabase:database report:report];
            });
            it(@"Should store empty step", ^{
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.stepIssues should] equal:@{ kAMADatabaseIntegrityStepInitial: @[] }];
            });
            it(@"Should change first passing step to initial if nothing was applied", ^{
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.firstPassedFixStep should] equal:kAMADatabaseIntegrityStepInitial];
            });
            it(@"Should change first passing step to last applied", ^{
                report.lastAppliedFixStep = lastAppliedStep;
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.firstPassedFixStep should] equal:lastAppliedStep];
            });
        });
        context(@"Some problem", ^{
            beforeEach(^{
                problems = @[ @"PROBLEM" ];
            });

            context(@"Critical", ^{
                beforeEach(^{
                    [issue stub:@selector(issueType) andReturn:theValue(AMASQLiteIntegrityIssueTypeCorrupt)];
                });

                it(@"Should return NO", ^{
                    [[theValue([processor checkIntegrityIssuesForDatabase:database report:report]) should] beNo];
                });
                it(@"Should parse issue", ^{
                    [[parser should] receive:@selector(issueForIntegityIssueString:) withArguments:problems[0]];
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                });
                it(@"Should not parse error", ^{
                    [[parser shouldNot] receive:@selector(issueForError:)];
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                });
                it(@"Should store initial step", ^{
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.stepIssues should] equal:@{ kAMADatabaseIntegrityStepInitial: @[ issue ] }];
                });
                it(@"Should store last applied step", ^{
                    report.lastAppliedFixStep = lastAppliedStep;
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.stepIssues should] equal:@{ lastAppliedStep: @[ issue ] }];
                });
                it(@"Should not change first passing step", ^{
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.firstPassedFixStep should] beNil];
                });
            });

            context(@"Non critical - DB is full", ^{
                beforeEach(^{
                    [issue stub:@selector(issueType) andReturn:theValue(AMASQLiteIntegrityIssueTypeFull)];
                });

                it(@"Should return YES", ^{
                    [[theValue([processor checkIntegrityIssuesForDatabase:database report:report]) should] beYes];
                });
                it(@"Should parse issue", ^{
                    [[parser should] receive:@selector(issueForIntegityIssueString:) withArguments:problems[0]];
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                });
                it(@"Should not parse error", ^{
                    [[parser shouldNot] receive:@selector(issueForError:)];
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                });
                it(@"Should store initial step", ^{
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.stepIssues should] equal:@{ kAMADatabaseIntegrityStepInitial: @[ issue ] }];
                });
                it(@"Should store last applied step", ^{
                    report.lastAppliedFixStep = lastAppliedStep;
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.stepIssues should] equal:@{ lastAppliedStep: @[ issue ] }];
                });
                it(@"Should change first passing step to initial if nothing was applied", ^{
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.firstPassedFixStep should] equal:kAMADatabaseIntegrityStepInitial];
                });
                it(@"Should change first passing step to last applied", ^{
                    report.lastAppliedFixStep = lastAppliedStep;
                    [processor checkIntegrityIssuesForDatabase:database report:report];
                    [[report.firstPassedFixStep should] equal:lastAppliedStep];
                });
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                problems = nil;
                error = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
            });

            it(@"Should return NO", ^{
                [[theValue([processor checkIntegrityIssuesForDatabase:database report:report]) should] beNo];
            });
            it(@"Should not parse issue", ^{
                [[parser shouldNot] receive:@selector(issueForIntegityIssueString:)];
                [processor checkIntegrityIssuesForDatabase:database report:report];
            });
            it(@"Should parse error", ^{
                [[parser should] receive:@selector(issueForError:) withArguments:error];
                [processor checkIntegrityIssuesForDatabase:database report:report];
            });
            it(@"Should store initial step", ^{
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.stepIssues should] equal:@{ kAMADatabaseIntegrityStepInitial: @[ issue ] }];
            });
            it(@"Should store last applied step", ^{
                report.lastAppliedFixStep = lastAppliedStep;
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.stepIssues should] equal:@{ lastAppliedStep: @[ issue ] }];
            });
            it(@"Should not change first passing step", ^{
                [processor checkIntegrityIssuesForDatabase:database report:report];
                [[report.firstPassedFixStep should] beNil];
            });
        });
    });

    context(@"Fix index", ^{
        BOOL __block result = YES;
        beforeEach(^{
            result = YES;
            [AMADatabaseIntegrityQueries stub:@selector(fixIntegrityForDBQueue:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:error];
                return theValue(result);
            }];
        });

        context(@"Nil DB", ^{
            it(@"Should return NO", ^{
                [[theValue([processor fixIndexForDatabase:nil report:report]) should] beNo];
            });
            it(@"Should not set error", ^{
                [processor fixIndexForDatabase:nil report:report];
                [[report.reindexError should] beNil];
            });
            it(@"Should not set last applied step", ^{
                [processor fixIndexForDatabase:nil report:report];
                [[report.lastAppliedFixStep should] beNil];
            });
        });
        context(@"Success", ^{
            it(@"Should return YES", ^{
                [[theValue([processor fixIndexForDatabase:database report:report]) should] beYes];
            });
            it(@"Should not set error", ^{
                [processor fixIndexForDatabase:database report:report];
                [[report.reindexError should] beNil];
            });
            it(@"Should set last applied step", ^{
                [processor fixIndexForDatabase:database report:report];
                [[report.lastAppliedFixStep should] equal:kAMADatabaseIntegrityStepReindex];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                result = NO;
                error = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
            });
            it(@"Should return NO", ^{
                [[theValue([processor fixIndexForDatabase:database report:report]) should] beNo];
            });
            it(@"Should set error", ^{
                [processor fixIndexForDatabase:database report:report];
                [[report.reindexError should] equal:error];
            });
            it(@"Should set last applied step", ^{
                [processor fixIndexForDatabase:database report:report];
                [[report.lastAppliedFixStep should] equal:kAMADatabaseIntegrityStepReindex];
            });
        });
    });

    context(@"Fix with backup and restore", ^{
        context(@"Nil DB", ^{
            beforeEach(^{
                [AMADatabaseIntegrityQueries stub:@selector(backupDBQueue:backupDB:error:)];
            });

            it(@"Should return NO", ^{
                [[theValue([processor fixWithBackupAndRestore:nil report:report]) should] beNo];
            });
            it(@"Should not set error", ^{
                [processor fixWithBackupAndRestore:nil report:report];
                [[report.backupRestoreError should] beNil];
            });
            it(@"Should not set last applied step", ^{
                [processor fixWithBackupAndRestore:nil report:report];
                [[report.lastAppliedFixStep should] beNil];
            });
            it(@"Should not create database", ^{
                [[databaseProvider shouldNot] receive:@selector(queueForPath:)];
                [processor fixWithBackupAndRestore:nil report:report];
            });
        });
        context(@"Success", ^{
            beforeEach(^{
                [AMADatabaseIntegrityQueries stub:@selector(backupDBQueue:backupDB:error:) withBlock:^id(NSArray *params) {
                    NSString *sourcePath = [params[0] path];
                    NSString *targetPath = [params[1] path];

                    [[[NSString stringWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil]
                        stringByAppendingString:@"-BACKUP"]
                        writeToFile:targetPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    return theValue(YES);
                }];
            });
            it(@"Should return YES", ^{
                [[theValue([processor fixWithBackupAndRestore:&database report:report]) should] beYes];
            });
            it(@"Should not set error", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[report.backupRestoreError should] beNil];
            });
            it(@"Should set last applied step", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[report.lastAppliedFixStep should] equal:kAMADatabaseIntegrityStepBackupRestore];
            });
            it(@"Should return valid DB path", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[database.path should] equal:databasePath];
            });
            it(@"Should return valid DB content", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                NSString *content = [NSString stringWithContentsOfFile:databasePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
                [[content should] equal:[mainDBContent stringByAppendingString:@"-BACKUP"]];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:@"DOMAIN" code:42 userInfo:nil];
                [AMADatabaseIntegrityQueries stub:@selector(backupDBQueue:backupDB:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:error];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([processor fixWithBackupAndRestore:&database report:report]) should] beNo];
            });
            it(@"Should set error", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[report.backupRestoreError should] equal:error];
            });
            it(@"Should set last applied step", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[report.lastAppliedFixStep should] equal:kAMADatabaseIntegrityStepBackupRestore];
            });
            it(@"Should create single database", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[additionalDatabasePaths should] haveCountOf:1];
            });
            it(@"Should remove createed database", ^{
                [processor fixWithBackupAndRestore:&database report:report];
                [[[NSData dataWithContentsOfFile:additionalDatabasePaths.firstObject] should] beNil];
            });
        });
    });

    context(@"Fix with drop and create new", ^{
        context(@"Nil DB", ^{
            it(@"Should return NO", ^{
                [[theValue([processor fixWithCreatingNewDatabase:nil report:report]) should] beNo];
            });
            it(@"Should not set last applied step", ^{
                [processor fixWithCreatingNewDatabase:nil report:report];
                [[report.lastAppliedFixStep should] beNil];
            });
            it(@"Should not create database", ^{
                [[databaseProvider shouldNot] receive:@selector(queueForPath:)];
                [processor fixWithCreatingNewDatabase:nil report:report];
            });
        });
        context(@"Success", ^{
            it(@"Should return YES", ^{
                [[theValue([processor fixWithCreatingNewDatabase:&database report:report]) should] beYes];
            });
            it(@"Should set last applied step", ^{
                [processor fixWithCreatingNewDatabase:&database report:report];
                [[report.lastAppliedFixStep should] equal:kAMADatabaseIntegrityStepNewDatabase];
            });
            it(@"Should return valid DB path", ^{
                [processor fixWithCreatingNewDatabase:&database report:report];
                [[database.path should] equal:databasePath];
            });
            it(@"Should return valid DB content", ^{
                [processor fixWithCreatingNewDatabase:&database report:report];
                NSString *content = [NSString stringWithContentsOfFile:databasePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
                [[content should] equal:additionalDBContent];
            });
        });
    });

});

SPEC_END
