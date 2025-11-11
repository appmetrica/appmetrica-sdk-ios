
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventValueFactory.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMAFileEventValue.h"
#import "AMAEncryptedFileStorageFactory.h"

SPEC_BEGIN(AMAEventValueFactoryTests)

describe(@"AMAEventValueFactory", ^{

    NSUInteger const expectedBytesTruncated = 23;
    NSUInteger __block bytesTruncated = 0;

    AMATestTruncator *__block stringTruncator = nil;
    AMATestTruncator *__block partialDataTruncator = nil;
    AMATestTruncator *__block fullDataTruncator = nil;
    AMAEventValueFactory *__block factory = nil;

    beforeEach(^{
        bytesTruncated = 0;
        stringTruncator = [[AMATestTruncator alloc] init];
        partialDataTruncator = [[AMATestTruncator alloc] init];
        fullDataTruncator = [[AMATestTruncator alloc] init];
        factory = [[AMAEventValueFactory alloc] initWithStringTruncator:stringTruncator
                                                   partialDataTruncator:partialDataTruncator
                                                      fullDataTruncator:fullDataTruncator];
    });

    context(@"String", ^{
        NSString *const stringValue = @"EVENT_VALUE";
        it(@"Should create value of valid type", ^{
            NSObject *value = (NSObject *)[factory stringEventValue:stringValue bytesTruncated:&bytesTruncated];
            [[value should] beKindOfClass:[AMAStringEventValue class]];
        });
        it(@"Should hold valid value", ^{
            AMAStringEventValue *value = (AMAStringEventValue *)[factory stringEventValue:stringValue
                                                                           bytesTruncated:&bytesTruncated];
            [[value.value should] equal:stringValue];
        });
        context(@"Truncation", ^{
            NSString *const truncatedValue = @"TRUNCATED_EVENT_VALUE";
            beforeEach(^{
                [stringTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
            });
            it(@"Should truncate value", ^{
                AMAStringEventValue *value = (AMAStringEventValue *)[factory stringEventValue:stringValue
                                                                               bytesTruncated:&bytesTruncated];
                [[value.value should] equal:truncatedValue];
            });
            it(@"Should fill bytes truncated", ^{
                [factory stringEventValue:stringValue bytesTruncated:&bytesTruncated];
                [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
            });
        });
    });

    context(@"Binary", ^{
        NSData *const binaryValue = [@"BINARY_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
        it(@"Should create value of valid type", ^{
            NSObject *value = (NSObject *)[factory binaryEventValue:binaryValue
                                                            gZipped:NO
                                                     bytesTruncated:&bytesTruncated];
            [[value should] beKindOfClass:[AMABinaryEventValue class]];
        });
        context(@"Value", ^{
            AMABinaryEventValue *__block value = nil;
            beforeEach(^{
                value = (AMABinaryEventValue *)[factory binaryEventValue:binaryValue
                                                                 gZipped:NO
                                                          bytesTruncated:&bytesTruncated];
            });
            it(@"Should hold valid value", ^{
                [[value.data should] equal:binaryValue];
            });
            it(@"Should hold gzipped flag", ^{
                [[theValue(value.gZipped) should] beNo];
            });
        });
        context(@"Truncation", ^{
            NSData *const truncatedValue = [@"TRUNCATED_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
            beforeEach(^{
                [partialDataTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
            });
            it(@"Should truncate value", ^{
                AMABinaryEventValue *value = (AMABinaryEventValue *)[factory binaryEventValue:binaryValue
                                                                                      gZipped:NO
                                                                               bytesTruncated:&bytesTruncated];
                [[value.data should] equal:truncatedValue];
            });
            it(@"Should fill bytes truncated", ^{
                [factory binaryEventValue:binaryValue gZipped:NO bytesTruncated:&bytesTruncated];
                [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
            });
        });
        context(@"GZipped", ^{
            AMABinaryEventValue *__block value = nil;
            beforeEach(^{
                value = (AMABinaryEventValue *)[factory binaryEventValue:binaryValue
                                                                 gZipped:YES
                                                          bytesTruncated:&bytesTruncated];
            });
            it(@"Should hold valid value", ^{
                [[value.data should] equal:binaryValue];
            });
            it(@"Should hold gzipped flag", ^{
                [[theValue(value.gZipped) should] beYes];
            });
        });
    });

    context(@"File", ^{
        NSData *const fileData = [@"FILE_DATA" dataUsingEncoding:NSUTF8StringEncoding];
        NSString *const fileName = @"file-name.bin";
        NSString *const filePath = @"/path/to/file";
        AMAEventEncryptionType const encryptionType = AMAEventEncryptionTypeAESv1;
        AMAEventValueFactoryTruncationType const truncationType = AMAEventValueFactoryTruncationTypePartial;

        NSObject<AMAFileStorage> *__block fileStorage = nil;
        beforeEach(^{
            fileStorage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
            [AMAEncryptedFileStorageFactory stub:@selector(fileStorageForEncryptionType:filePath:)
                                       andReturn:fileStorage];
            [fileStorage stub:@selector(writeData:error:) andReturn:theValue(YES)];
            [AMAFileUtility stub:@selector(pathForFullFileName:) andReturn:filePath];
        });

        AMAFileEventValue *(^eventValue)(void) = ^{
            return (AMAFileEventValue *)[factory fileEventValue:fileData
                                                       fileName:fileName
                                                        gZipped:NO
                                                 encryptionType:encryptionType
                                                 truncationType:truncationType
                                                 bytesTruncated:&bytesTruncated
                                                          error:nil];
        };

        it(@"Should create value of valid type", ^{
            [[eventValue() should] beKindOfClass:[AMAFileEventValue class]];
        });
        it(@"Should create valid file path", ^{
            [[AMAFileUtility should] receive:@selector(pathForFullFileName:) withArguments:fileName];
            eventValue();
        });
        it(@"Should create valid file storage", ^{
            [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                               withArguments:theValue(encryptionType), filePath];
            eventValue();
        });
        it(@"Should write valid content", ^{
            [[fileStorage should] receive:@selector(writeData:error:) withArguments:fileData, kw_any()];
            eventValue();
        });
        context(@"Event value fields", ^{
            it(@"Should have valid relative path", ^{
                [[eventValue().relativeFilePath should] equal:fileName];
            });
            it(@"Should have valid encryption type", ^{
                [[theValue(eventValue().encryptionType) should] equal:theValue(encryptionType)];
            });
        });
        context(@"Partial truncation", ^{
            NSData *const truncatedValue = [@"TRUNCATED_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
            beforeEach(^{
                [partialDataTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
            });
            it(@"Should write valid content", ^{
                [[fileStorage should] receive:@selector(writeData:error:) withArguments:truncatedValue, kw_any()];
                eventValue();
            });
            it(@"Should fill bytes truncated", ^{
                eventValue();
                [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
            });
        });
        context(@"Full truncation", ^{
            NSData *const truncatedValue = [@"TRUNCATED_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
            beforeEach(^{
                [fullDataTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
            });
            it(@"Should write valid content", ^{
                [[fileStorage should] receive:@selector(writeData:error:) withArguments:truncatedValue, kw_any()];
                [factory fileEventValue:fileData
                               fileName:fileName
                                gZipped:NO
                         encryptionType:encryptionType
                         truncationType:AMAEventValueFactoryTruncationTypeFull
                         bytesTruncated:&bytesTruncated
                                  error:nil];
            });
            it(@"Should fill bytes truncated", ^{
                [factory fileEventValue:fileData
                               fileName:fileName
                                gZipped:NO
                         encryptionType:encryptionType
                         truncationType:AMAEventValueFactoryTruncationTypeFull
                         bytesTruncated:&bytesTruncated
                                  error:nil];
                [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
            });
        });
        context(@"Encoding error", ^{
            NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:42 userInfo:nil];
            beforeEach(^{
                [fileStorage stub:@selector(writeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return theValue(NO);
                }];
            });
            it(@"Should return nil", ^{
                [[eventValue() should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [factory fileEventValue:fileData
                               fileName:fileName
                                gZipped:NO
                         encryptionType:encryptionType
                         truncationType:truncationType
                         bytesTruncated:&bytesTruncated
                                  error:&error];
                [[error should] equal:expectedError];
            });
        });
        context(@"GZipped", ^{
            __auto_type gzippedEventValue = ^{
                return (AMAFileEventValue *)[factory fileEventValue:fileData
                                                           fileName:fileName
                                                            gZipped:YES
                                                     encryptionType:encryptionType
                                                     truncationType:AMAEventValueFactoryTruncationTypeFull
                                                     bytesTruncated:&bytesTruncated
                                                              error:nil];
            };
            it(@"Should create value of valid type", ^{
                [[gzippedEventValue() should] beKindOfClass:[AMAFileEventValue class]];
            });
            it(@"Should create valid file path", ^{
                [[AMAFileUtility should] receive:@selector(pathForFullFileName:) withArguments:fileName];
                gzippedEventValue();
            });
            it(@"Should create valid file storage", ^{
                [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                                   withArguments:theValue(AMAEventEncryptionTypeNoEncryption), filePath];
                gzippedEventValue();
            });
            it(@"Should write valid content", ^{
                [[fileStorage should] receive:@selector(writeData:error:) withArguments:fileData, kw_any()];
                gzippedEventValue();
            });
            context(@"Event value fields", ^{
                it(@"Should have valid relative path", ^{
                    [[gzippedEventValue().relativeFilePath should] equal:fileName];
                });
                it(@"Should have valid encryption type", ^{
                    [[theValue(gzippedEventValue().encryptionType) should] equal:theValue(AMAEventEncryptionTypeGZip)];
                });
            });
            context(@"Full truncation", ^{
                NSData *const truncatedValue = [@"TRUNCATED_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
                beforeEach(^{
                    [fullDataTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
                });
                it(@"Should write valid content", ^{
                    [[fileStorage should] receive:@selector(writeData:error:) withArguments:truncatedValue, kw_any()];
                    gzippedEventValue();
                });
                it(@"Should fill bytes truncated", ^{
                    gzippedEventValue();
                    [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                });
            });
        });
        context(@"Not GZipped", ^{
            __auto_type notGZippedEventValue = ^{
                return (AMAFileEventValue *)[factory fileEventValue:fileData
                                                           fileName:fileName
                                                            gZipped:NO
                                                     encryptionType:encryptionType
                                                     truncationType:AMAEventValueFactoryTruncationTypePartial
                                                     bytesTruncated:&bytesTruncated
                                                              error:nil];
            };
            it(@"Should create value of valid type", ^{
                [[notGZippedEventValue() should] beKindOfClass:[AMAFileEventValue class]];
            });
            it(@"Should create valid file path", ^{
                [[AMAFileUtility should] receive:@selector(pathForFullFileName:) withArguments:fileName];
                notGZippedEventValue();
            });
            it(@"Should create valid file storage", ^{
                [[AMAEncryptedFileStorageFactory should] receive:@selector(fileStorageForEncryptionType:filePath:)
                                                   withArguments:theValue(encryptionType), filePath];
                notGZippedEventValue();
            });
            it(@"Should write valid content", ^{
                [[fileStorage should] receive:@selector(writeData:error:) withArguments:fileData, kw_any()];
                notGZippedEventValue();
            });
            context(@"Event value fields", ^{
                it(@"Should have valid relative path", ^{
                    [[notGZippedEventValue().relativeFilePath should] equal:fileName];
                });
                it(@"Should have valid encryption type", ^{
                    [[theValue(notGZippedEventValue().encryptionType) should] equal:theValue(encryptionType)];
                });
            });
            context(@"Partial truncation", ^{
                NSData *const truncatedValue = [@"PARTIALLY_TRUNCATED_EVENT_VALUE" dataUsingEncoding:NSUTF8StringEncoding];
                beforeEach(^{
                    [partialDataTruncator enableTruncationWithResult:truncatedValue bytesTruncated:expectedBytesTruncated];
                });
                it(@"Should write valid content", ^{
                    [[fileStorage should] receive:@selector(writeData:error:) withArguments:truncatedValue, kw_any()];
                    notGZippedEventValue();
                });
                it(@"Should fill bytes truncated", ^{
                    notGZippedEventValue();
                    [[theValue(bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                });
            });
        });

    });

});

SPEC_END

