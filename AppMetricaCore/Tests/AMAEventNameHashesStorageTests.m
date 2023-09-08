
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventNameHashesStorage.h"
#import "AMAEventNameHashesSerializer.h"
#import "AMAEventNameHashesCollection.h"
#import "AMACore.h"

SPEC_BEGIN(AMAEventNameHashesStorageTests)

describe(@"AMAEventNameHashesStorage", ^{

    NSData *const serializedData = [@"SERIALIZED_DATA" dataUsingEncoding:NSUTF8StringEncoding];

    AMAEventNameHashesCollection *__block collection = nil;
    NSObject<AMAFileStorage> *__block fileStorage = nil;
    AMAEventNameHashesSerializer *__block serializer = nil;
    AMAEventNameHashesStorage *__block storage = nil;

    beforeEach(^{
        collection = [AMAEventNameHashesCollection nullMock];
        fileStorage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
        serializer = [AMAEventNameHashesSerializer nullMock];
        storage = [[AMAEventNameHashesStorage alloc] initWithFileStorage:fileStorage serializer:serializer];
    });

    context(@"Load", ^{
        beforeEach(^{
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
        context(@"Read error", ^{
            beforeEach(^{
                [fileStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0]
                                                       withValue:[NSError errorWithDomain:@"" code:0 userInfo:nil]];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[storage loadCollection] should] beNil];
            });
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
