
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMASQLiteIntegrityIssueParser.h"
#import "AMASQLiteIntegrityIssue.h"

SPEC_BEGIN(AMASQLiteIntegrityIssueParserTests)

describe(@"AMASQLiteIntegrityIssueParser", ^{

    AMASQLiteIntegrityIssueParser *__block parser = nil;

    beforeEach(^{
        parser = [[AMASQLiteIntegrityIssueParser alloc] init];
    });

    context(@"Errors", ^{
        NSString *const description = @"ERROR_DESCRIPTION";
        NSError *__block error = nil;
        __auto_type parse = ^AMASQLiteIntegrityIssue * {
            return [parser issueForError:error];
        };

        context(@"Different domain", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:@"DIFFERENT_DOMAIN"
                                            code:13
                                        userInfo:@{ NSLocalizedDescriptionKey: description }];
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeOther)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(13)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:description];
            });
        });
        context(@"Unknown FMDB error", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:kAMAFMDBErrorDomain
                                            code:10
                                        userInfo:@{ NSLocalizedDescriptionKey: description }];
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeOtherFMDBError)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(10)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:description];
            });
        });
        context(@"SQLITE_FULL", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:kAMAFMDBErrorDomain
                                            code:13
                                        userInfo:@{ NSLocalizedDescriptionKey: description }];
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeFull)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(13)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:description];
            });
        });
        context(@"SQLITE_CORRUPT", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:kAMAFMDBErrorDomain
                                            code:11
                                        userInfo:@{ NSLocalizedDescriptionKey: description }];
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeCorrupt)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(11)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:description];
            });
        });
        context(@"SQLITE_NOTADB", ^{
            beforeEach(^{
                error = [NSError errorWithDomain:kAMAFMDBErrorDomain
                                            code:26
                                        userInfo:@{ NSLocalizedDescriptionKey: description }];
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeNotADatabase)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(26)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:description];
            });
        });
    });

    context(@"Integrity check issues", ^{
        NSString *__block issueString = nil;
        __auto_type parse = ^AMASQLiteIntegrityIssue * {
            return [parser issueForIntegityIssueString:issueString];
        };

        context(@"Empty string", ^{
            beforeEach(^{
                issueString = @"";
            });
            it(@"Should not return nil", ^{
                [[parse() shouldNot] beNil];
            });
            it(@"Should return valid type", ^{
                [[theValue(parse().issueType) should] equal:theValue(AMASQLiteIntegrityIssueTypeOther)];
            });
            it(@"Should return valid error code", ^{
                [[theValue(parse().errorCode) should] equal:theValue(0)];
            });
            it(@"Should return valid full description", ^{
                [[parse().fullDescription should] equal:issueString];
            });
        });

        context(@"Broken pages", ^{
            AMASQLiteIntegrityIssueType const expectedType = AMASQLiteIntegrityIssueTypeBrokenPages;

            context(@"Sample 01", ^{
                beforeEach(^{
                    issueString = @"*** in database main ***\nPage 6 is never used\nPage 7 is never used";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
            context(@"Sample 02", ^{
                beforeEach(^{
                    issueString = @"*** in database main ***\nPage 6 is never used"
                                     "\nPage 7 is never used\nPage 8 is never used"
                                     "\nPage 9 is never used\nPage 10 is never used";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
            context(@"Sample 03", ^{
                beforeEach(^{
                    issueString = @"*** in database main ***\nOn page 5 at right child: invalid page number 12";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
        });
        context(@"Broken index", ^{
            AMASQLiteIntegrityIssueType const expectedType = AMASQLiteIntegrityIssueTypeBrokenIndex;

            context(@"Sample 01", ^{
                beforeEach(^{
                    issueString = @"row 1 missing from index events_session_id";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
            context(@"Sample 02", ^{
                beforeEach(^{
                    issueString = @"row 4 missing from index sqlite_autoindex_kv_1";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
            context(@"Sample 03", ^{
                beforeEach(^{
                    issueString = @"wrong # of entries in index events_session_id";
                });
                it(@"Should not return nil", ^{
                    [[parse() shouldNot] beNil];
                });
                it(@"Should return valid type", ^{
                    [[theValue(parse().issueType) should] equal:theValue(expectedType)];
                });
                it(@"Should return valid error code", ^{
                    [[theValue(parse().errorCode) should] equal:theValue(0)];
                });
                it(@"Should return valid full description", ^{
                    [[parse().fullDescription should] equal:issueString];
                });
            });
        });
    });

});

SPEC_END
