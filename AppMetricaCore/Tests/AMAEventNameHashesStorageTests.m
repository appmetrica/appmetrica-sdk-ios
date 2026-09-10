
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventNameHashesStorage.h"
#import "AMAEventNameHashesSerializer.h"
#import "AMAEventNameHashesCollection.h"
#import "AMACore.h"
#import "AMALogSpy.h"

SPEC_BEGIN(AMAEventNameHashesStorageTests)

describe(@"AMAEventNameHashesStorage", ^{

    NSData *const serializedData = [@"SERIALIZED_DATA" dataUsingEncoding:NSUTF8StringEncoding];

    AMAEventNameHashesCollection *__block collection = nil;
    NSObject<AMAFileStorage> *__block fileStorage = nil;
    AMAEventNameHashesSerializer *__block serializer = nil;
    AMAEventNameHashesStorage *__block storage = nil;
    AMALogSpy *__block logSpy = nil;

    beforeEach(^{
        logSpy = [[AMALogSpy alloc] init];
        [AMALogFacade stub:@selector(sharedLog) andReturn:logSpy];
        collection = [AMAEventNameHashesCollection nullMock];
        fileStorage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
        serializer = [AMAEventNameHashesSerializer nullMock];
        storage = [[AMAEventNameHashesStorage alloc] initWithFileStorage:fileStorage serializer:serializer];
    });

    afterEach(^{
        [AMALogFacade clearStubs];
    });

    context(@"Load", ^{
        beforeEach(^{
            [fileStorage stub:@selector(fileExists) andReturn:theValue(YES)];
            [fileStorage stub:@selector(readDataWithError:) andReturn:serializedData];
            [serializer stub:@selector(collectionForData:) andReturn:collection];
        });
        it(@"Should load data", ^{
            [[fileStorage should] receive:@selector(readDataWithError:)];
            [storage loadCollection];
        });
        it(@"Should deserialize data", ^{
            [[serializer should] receive:@selector(collectionForData:) withArguments:serializedData];
            [storage loadCollection];
        });
        it(@"Should return collection", ^{
            [[[storage loadCollection] should] equal:collection];
        });
        it(@"Should preserve read errors after the file existence check", ^{
            [[serializer shouldNot] receive:@selector(collectionForData:)];
            NSArray *errorCodes = @[ @(NSFileReadNoPermissionError), @(NSFileReadNoSuchFileError) ];
            for (NSNumber *errorCode in errorCodes) {
                logSpy = [[AMALogSpy alloc] init];
                [AMALogFacade stub:@selector(sharedLog) andReturn:logSpy];
                NSError *readError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                        code:errorCode.integerValue
                                                    userInfo:nil];
                [fileStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0] withValue:readError];
                    return nil;
                }];
                [[[storage loadCollection] should] beNil];
                NSString *text = [NSString stringWithFormat:@"Failed to read event name hashes collection: %@", readError];
                AMALogMessageSpy *message = [AMALogMessageSpy messageWithText:text
                                                                   channel:@"AppMetricaCore"
                                                                     level:AMALogLevelWarning];
                [[logSpy.messages should] equal:@[ message ]];
            }
        });
    });

    context(@"Missing file", ^{
        it(@"Should return nil without reading, deserializing or logging", ^{
            [fileStorage stub:@selector(fileExists) andReturn:theValue(NO)];
            [[fileStorage shouldNot] receive:@selector(readDataWithError:)];
            [[serializer shouldNot] receive:@selector(collectionForData:)];
            [[[storage loadCollection] should] beNil];
            [[logSpy.messages should] beEmpty];
        });
    });

    context(@"Save", ^{
        beforeEach(^{
            [serializer stub:@selector(dataForCollection:) andReturn:serializedData];
            [fileStorage stub:@selector(writeData:error:) andReturn:theValue(YES)];
        });
        it(@"Should serialize data", ^{
            [[serializer should] receive:@selector(dataForCollection:) withArguments:collection];
            [storage saveCollection:collection];
        });
        it(@"Should save data", ^{
            [[fileStorage should] receive:@selector(writeData:error:) withArguments:serializedData, kw_any()];
            [storage saveCollection:collection];
        });
        it(@"Should return YES", ^{
            [[theValue([storage saveCollection:collection]) should] beYes];
        });
        context(@"Write error", ^{
            beforeEach(^{
                [fileStorage stub:@selector(writeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1]
                                                       withValue:[NSError errorWithDomain:@"" code:0 userInfo:nil]];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([storage saveCollection:collection]) should] beNo];
            });
        });
    });

});

SPEC_END
