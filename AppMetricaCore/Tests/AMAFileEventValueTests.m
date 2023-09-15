
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAFileEventValue.h"
#import "AMAEncryptedFileStorageFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFileEventValueTests)

describe(@"AMAFileEventValue", ^{

    NSString *const relativeFilePath = @"file-name.bun";
    NSString *const absoluteFilePath = @"/path/to/file";
    NSData *const fileData = [@"FILE_DATA" dataUsingEncoding:NSUTF8StringEncoding];

    NSObject<AMAFileStorage> *__block fileStorage = nil;
    AMAEventEncryptionType const encryptionType = AMAEventEncryptionTypeAESv1;

    AMAFileEventValue *__block eventValue = nil;

    beforeEach(^{
        [AMAFileUtility stub:@selector(pathForFullFileName:) andReturn:absoluteFilePath];
        fileStorage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
        [fileStorage stub:@selector(readDataWithError:) andReturn:fileData];
        [AMAEncryptedFileStorageFactory stub:@selector(fileStorageForEncryptionType:filePath:) andReturn:fileStorage];
    });

    context(@"Empty", ^{
        beforeEach(^{
            eventValue = [[AMAFileEventValue alloc] initWithRelativeFilePath:@""
                                                              encryptionType:encryptionType];
        });
        it(@"Should be empty", ^{
            [[theValue(eventValue.empty) should] beYes];
        });
        it(@"Should return nil data", ^{
            [[[eventValue dataWithError:nil] should] beNil];
        });
        it(@"Should implement gzipped value getter", ^{
            [[eventValue should] respondToSelector:@selector(gzippedDataWithError:)];
        });
        it(@"Should return nil for gzipped value getter", ^{
            [[[eventValue gzippedDataWithError:NULL] should] beNil];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [eventValue dataWithError:&error];
            [[error should] beNil];
        });
    });

    context(@"Non-empty", ^{
        beforeEach(^{
            eventValue = [[AMAFileEventValue alloc] initWithRelativeFilePath:relativeFilePath
                                                              encryptionType:encryptionType];
        });
        it(@"Should not be empty", ^{
            [[theValue(eventValue.empty) should] beNo];
        });
        it(@"Should get valid file storage", ^{
            [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                               withArguments:theValue(encryptionType), absoluteFilePath];
            [eventValue dataWithError:nil];
        });
        it(@"Should return valid data", ^{
            [[[eventValue dataWithError:nil] should] equal:fileData];
        });
        it(@"Should implement gzipped value getter", ^{
            [[eventValue should] respondToSelector:@selector(gzippedDataWithError:)];
        });
        it(@"Should return nil for gzipped value getter", ^{
            [[[eventValue gzippedDataWithError:NULL] should] beNil];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [eventValue dataWithError:&error];
            [[error should] beNil];
        });
        context(@"Read error", ^{
            NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
            beforeEach(^{
                [fileStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0]
                                                       withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should neturn nil", ^{
                [[[eventValue dataWithError:nil] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [eventValue dataWithError:&error];
                [[error should] equal:expectedError];
            });
        });
        it(@"Should remove file on cleanup", ^{
            [[AMAFileUtility should] receive:@selector(deleteFileAtPath:) withArguments:absoluteFilePath];
            [eventValue cleanup];
        });
    });

    context(@"GZipped", ^{
        beforeEach(^{
            eventValue = [[AMAFileEventValue alloc] initWithRelativeFilePath:relativeFilePath
                                                              encryptionType:AMAEventEncryptionTypeGZip];
        });
        it(@"Should not be empty", ^{
            [[theValue(eventValue.empty) should] beNo];
        });
        it(@"Should get valid file storage", ^{
            [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                               withArguments:theValue(AMAEventEncryptionTypeGZip), absoluteFilePath];
            [eventValue dataWithError:NULL];
        });
        it(@"Should return valid data", ^{
            [[[eventValue dataWithError:nil] should] equal:fileData];
        });
        it(@"Should implement gzipped value getter", ^{
            [[eventValue should] respondToSelector:@selector(gzippedDataWithError:)];
        });
        it(@"Should get valid file storage for gzipped value getter", ^{
            [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                               withArguments:theValue(AMAEventEncryptionTypeNoEncryption), absoluteFilePath];
            [eventValue gzippedDataWithError:NULL];
        });
        it(@"Should return valid data for gzipped value getter", ^{
            [[[eventValue gzippedDataWithError:NULL] should] equal:fileData];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [eventValue dataWithError:&error];
            [[error should] beNil];
        });
        context(@"Read error", ^{
            NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
            beforeEach(^{
                [fileStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0]
                                                       withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should neturn nil", ^{
                [[[eventValue dataWithError:nil] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [eventValue dataWithError:&error];
                [[error should] equal:expectedError];
            });
        });
    });
    
    it(@"Should conform to AMAEventValueProtocol", ^{
        [[eventValue should] conformToProtocol:@protocol(AMAEventValueProtocol)];
    });
});

SPEC_END

