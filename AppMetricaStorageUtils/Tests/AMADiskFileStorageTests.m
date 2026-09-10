
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

SPEC_BEGIN(AMADiskFileStorageTests)

describe(@"AMADiskFileStorage", ^{

    NSString *const path = @"/path/to/file";
    NSData *const fileData = [@"FILE DATA" dataUsingEncoding:NSUTF8StringEncoding];

    AMADiskFileStorage *__block storage = nil;

    beforeEach(^{
        storage = [[AMADiskFileStorage alloc] initWithPath:path options:0];
    });
    afterEach(^{
        [AMAFileUtility clearStubs];
    });

    context(@"File exists", ^{
        it(@"Should provide valid path", ^{
            [[AMAFileUtility should] receive:@selector(fileExistsAtPath:) withArguments:path];
            [storage fileExists];
        });
        it(@"Should return YES if so", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
            [[theValue(storage.fileExists) should] beYes];
        });
        it(@"Should return NO if so", ^{
            [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
            [[theValue(storage.fileExists) should] beNo];
        });
    });

    context(@"Read", ^{
        context(@"Success", ^{
            beforeEach(^{
                [AMAFileUtility stub:@selector(rawContentAtFilePath:error:) andReturn:fileData];
            });
            it(@"Should return data", ^{
                [[[storage readDataWithError:NULL] should] equal:fileData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage readDataWithError:&error];
                [[error should] beNil];
            });
        });
        context(@"Failure", ^{
            NSError *__block readError = nil;
            beforeEach(^{
                readError = [NSError nullMock];
                [AMAFileUtility stub:@selector(rawContentAtFilePath:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:readError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[storage readDataWithError:NULL] should] beNil];
            });
            it(@"Should fill error with underlying error", ^{
                NSError *error = nil;
                [storage readDataWithError:&error];
                [[error should] equal:readError];
            });
        });
        context(@"No-backup", ^{
            beforeEach(^{
                storage = [[AMADiskFileStorage alloc] initWithPath:path
                                                           options:AMADiskFileStorageOptionNoBackup];
                [AMAFileUtility stub:@selector(rawContentAtFilePath:error:) andReturn:fileData];
            });
            it(@"Should return data", ^{
                [[[storage readDataWithError:NULL] should] equal:fileData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage readDataWithError:&error];
                [[error should] beNil];
            });
            it(@"Should not create directory", ^{
                [[AMAFileUtility shouldNot] receive:@selector(createPathIfNeeded:)];
                [storage readDataWithError:NULL];
            });
            it(@"Should set no-backup flag", ^{
                [[AMAFileUtility should] receive:@selector(setSkipBackupAttributesOnPath:) withArguments:path];
                [storage readDataWithError:NULL];
            });
        });
    });
    context(@"Write", ^{
        context(@"Success", ^{
            beforeEach(^{
                [AMAFileUtility stub:@selector(writeData:filePath:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([storage writeData:fileData error:NULL]) should] beYes];
            });
            it(@"Should write data", ^{
                [[AMAFileUtility should] receive:@selector(writeData:filePath:error:)
                                   withArguments:fileData, path, kw_any()];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:fileData error:&error];
                [[error should] beNil];
            });
            it(@"Should not create directory", ^{
                [[AMAFileUtility shouldNot] receive:@selector(createPathIfNeeded:)];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not set no-backup flag", ^{
                [[AMAFileUtility shouldNot] receive:@selector(setSkipBackupAttributesOnPath:)];
                [storage writeData:fileData error:NULL];
            });
        });
        context(@"Failure", ^{
            NSError *__block writeError = nil;
            beforeEach(^{
                writeError = [NSError nullMock];
                [AMAFileUtility stub:@selector(writeData:filePath:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:writeError];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([storage writeData:fileData error:NULL]) should] beNo];
            });
            it(@"Should write data", ^{
                [[AMAFileUtility should] receive:@selector(writeData:filePath:error:)
                                   withArguments:fileData, path, kw_any()];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:fileData error:&error];
                [[error should] equal:writeError];
            });
        });
        context(@"No-backup", ^{
            beforeEach(^{
                storage = [[AMADiskFileStorage alloc] initWithPath:path
                                                           options:AMADiskFileStorageOptionNoBackup];
                [AMAFileUtility stub:@selector(writeData:filePath:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([storage writeData:fileData error:NULL]) should] beYes];
            });
            it(@"Should write data", ^{
                [[AMAFileUtility should] receive:@selector(writeData:filePath:error:)
                                   withArguments:fileData, path, kw_any()];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:fileData error:&error];
                [[error should] beNil];
            });
            it(@"Should not create directory", ^{
                [[AMAFileUtility shouldNot] receive:@selector(createPathIfNeeded:)];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should set no-backup flag", ^{
                [[AMAFileUtility should] receive:@selector(setSkipBackupAttributesOnPath:) withArguments:path];
                [storage writeData:fileData error:NULL];
            });
        });
        context(@"Create dictionary", ^{
            beforeEach(^{
                storage = [[AMADiskFileStorage alloc] initWithPath:path
                                                           options:AMADiskFileStorageOptionCreateDirectory];
                [AMAFileUtility stub:@selector(writeData:filePath:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([storage writeData:fileData error:NULL]) should] beYes];
            });
            it(@"Should write data", ^{
                [[AMAFileUtility should] receive:@selector(writeData:filePath:error:)
                                   withArguments:fileData, path, kw_any()];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:fileData error:&error];
                [[error should] beNil];
            });
            it(@"Should create directory", ^{
                [[AMAFileUtility should] receive:@selector(createPathIfNeeded:) withArguments:@"/path/to"];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should not set no-backup flag", ^{
                [[AMAFileUtility shouldNot] receive:@selector(setSkipBackupAttributesOnPath:)];
                [storage writeData:fileData error:NULL];
            });
        });
        context(@"All flags", ^{
            beforeEach(^{
                AMADiskFileStorageOptions options =
                    AMADiskFileStorageOptionCreateDirectory | AMADiskFileStorageOptionNoBackup;
                storage = [[AMADiskFileStorage alloc] initWithPath:path options:options];
                [AMAFileUtility stub:@selector(writeData:filePath:error:) andReturn:theValue(YES)];
            });
            it(@"Should create directory", ^{
                [[AMAFileUtility should] receive:@selector(createPathIfNeeded:) withArguments:@"/path/to"];
                [storage writeData:fileData error:NULL];
            });
            it(@"Should set no-backup flag", ^{
                [[AMAFileUtility should] receive:@selector(setSkipBackupAttributesOnPath:) withArguments:path];
                [storage writeData:fileData error:NULL];
            });
        });
    });

    context(@"No-backup lifecycle", ^{
        NSData *__block readData = nil;
        BOOL __block writeResult = YES;
        BOOL __block attributeResult = YES;
        NSUInteger __block attributeAttempts = 0;
        NSError *__block storageError = nil;

        beforeEach(^{
            storage = [[AMADiskFileStorage alloc] initWithPath:path options:AMADiskFileStorageOptionNoBackup];
            readData = fileData;
            writeResult = YES;
            attributeResult = YES;
            attributeAttempts = 0;
            storageError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoPermissionError userInfo:nil];
            [AMAFileUtility stub:@selector(rawContentAtFilePath:error:) withBlock:^id(NSArray *params) {
                if (readData == nil) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:storageError];
                }
                return readData;
            }];
            [AMAFileUtility stub:@selector(writeData:filePath:error:) withBlock:^id(NSArray *params) {
                if (writeResult == NO) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:storageError];
                }
                return theValue(writeResult);
            }];
            [AMAFileUtility stub:@selector(setSkipBackupAttributesOnPath:) withBlock:^id(NSArray *params) {
                ++attributeAttempts;
                return theValue(attributeResult);
            }];
        });

        it(@"Should preserve failed reads and writes and set the attribute on the next successful operation", ^{
            readData = nil;
            writeResult = NO;
            NSError *error = nil;
            [[[storage readDataWithError:&error] should] beNil];
            [[error should] equal:storageError];
            error = nil;
            [[theValue([storage writeData:fileData error:&error]) should] beNo];
            [[error should] equal:storageError];
            [[theValue(attributeAttempts) should] beZero];

            writeResult = YES;
            [[theValue([storage writeData:fileData error:NULL]) should] beYes];
            [[theValue(attributeAttempts) should] equal:theValue(1)];
            readData = fileData;
            [storage readDataWithError:NULL];
            [[theValue(attributeAttempts) should] equal:theValue(1)];
        });

        it(@"Should retry a failed attribute update and cache only a successful update", ^{
            attributeResult = NO;
            NSError *error = nil;
            [[[storage readDataWithError:&error] should] equal:fileData];
            [[error should] beNil];
            [[theValue(attributeAttempts) should] equal:theValue(1)];

            attributeResult = YES;
            [[theValue([storage writeData:fileData error:&error]) should] beYes];
            [[error should] beNil];
            [[theValue(attributeAttempts) should] equal:theValue(2)];
            [storage readDataWithError:NULL];
            [storage writeData:fileData error:NULL];
            [[theValue(attributeAttempts) should] equal:theValue(2)];
        });

        it(@"Should set the attribute after reading an empty file", ^{
            readData = [NSData data];
            [[[storage readDataWithError:NULL] should] equal:readData];
            [[theValue(attributeAttempts) should] equal:theValue(1)];
        });
    });

});

SPEC_END
