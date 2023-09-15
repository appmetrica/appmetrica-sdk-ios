
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEncryptedFileStorage.h"

SPEC_BEGIN(AMAEncryptedFileStorageTests)

describe(@"AMAEncryptedFileStorage", ^{
    
    NSData *const encryptedFileData = [@"ENCRYPTED FILE DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const decryptedFileData = [@"DECRYPTED FILE DATA" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSObject<AMAFileStorage> *__block underlyingStorage = nil;
    NSObject<AMADataEncoding> *__block encoder = nil;
    AMAEncryptedFileStorage *__block storage = nil;
    
    beforeEach(^{
        underlyingStorage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
        encoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        storage = [[AMAEncryptedFileStorage alloc] initWithUnderlyingStorage:underlyingStorage
                                                                     encoder:encoder];
    });
    
    context(@"Read", ^{
        beforeEach(^{
            [underlyingStorage stub:@selector(readDataWithError:) andReturn:encryptedFileData];
            [encoder stub:@selector(decodeData:error:) andReturn:decryptedFileData];
        });
        context(@"Success", ^{
            it(@"Should decrypt data", ^{
                [[encoder should] receive:@selector(decodeData:error:) withArguments:encryptedFileData, kw_any()];
                [storage readDataWithError:NULL];
            });
            it(@"Should return data", ^{
                [[[storage readDataWithError:NULL] should] equal:decryptedFileData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage readDataWithError:&error];
                [[error should] beNil];
            });
        });
        context(@"Underlying storage error", ^{
            NSError *__block readError = nil;
            beforeEach(^{
                readError = [NSError nullMock];
                [underlyingStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0] withValue:readError];
                    return nil;
                }];
            });
            it(@"Should not call data decryption", ^{
                [[encoder shouldNot] receive:@selector(decodeData:error:)];
                [storage readDataWithError:NULL];
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
        context(@"Encoder error", ^{
            NSError *__block decryptionError = nil;
            beforeEach(^{
                decryptionError = [NSError nullMock];
                [encoder stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:decryptionError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[storage readDataWithError:NULL] should] beNil];
            });
            it(@"Should fill error with underlying error", ^{
                NSError *error = nil;
                [storage readDataWithError:&error];
                [[error should] equal:decryptionError];
            });
        });
    });
    context(@"Write", ^{
        beforeEach(^{
            [encoder stub:@selector(encodeData:error:) andReturn:encryptedFileData];
            [underlyingStorage stub:@selector(writeData:error:) andReturn:theValue(YES)];
        });
        context(@"Success", ^{
            it(@"Should return YES", ^{
                [[theValue([storage writeData:decryptedFileData error:NULL]) should] beYes];
            });
            it(@"Should encrypt data", ^{
                [[encoder should] receive:@selector(encodeData:error:)
                            withArguments:decryptedFileData, kw_any()];
                [storage writeData:decryptedFileData error:NULL];
            });
            it(@"Should write data", ^{
                [[underlyingStorage should] receive:@selector(writeData:error:)
                                      withArguments:encryptedFileData, kw_any()];
                [storage writeData:decryptedFileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:decryptedFileData error:&error];
                [[error should] beNil];
            });
        });
        context(@"Underlying storage error", ^{
            NSError *__block writeError = nil;
            beforeEach(^{
                writeError = [NSError nullMock];
                [underlyingStorage stub:@selector(writeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:writeError];
                    return nil;
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([storage writeData:decryptedFileData error:NULL]) should] beNo];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:decryptedFileData error:&error];
                [[error should] equal:writeError];
            });
        });
        context(@"Encoder error", ^{
            NSError *__block encryptionError = nil;
            beforeEach(^{
                encryptionError = [NSError nullMock];
                [encoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:encryptionError];
                    return nil;
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([storage writeData:decryptedFileData error:NULL]) should] beNo];
            });
            it(@"Should not write any data", ^{
                [[underlyingStorage shouldNot] receive:@selector(writeData:error:)];
                [storage writeData:decryptedFileData error:NULL];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [storage writeData:decryptedFileData error:&error];
                [[error should] equal:encryptionError];
            });
        });
    });
    
    it(@"Should AMAFileStorage", ^{
        [[storage should] conformToProtocol:@protocol(AMAFileStorage)];
    });
});

SPEC_END
