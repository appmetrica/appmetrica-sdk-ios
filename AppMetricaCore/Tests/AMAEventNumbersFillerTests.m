
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventNumbersFiller.h"
#import "AMAEvent.h"
#import "AMASession.h"

SPEC_BEGIN(AMAEventNumbersFillerTests)

describe(@"AMAEventNumbersFiller", ^{

    AMAIncrementableValueStorageMock *__block globalNumberStorage = nil;
    NSMutableDictionary<NSNumber *, AMAIncrementableValueStorageMock *> *__block numberOfTypeStorages = nil;
    AMAEvent *__block event = nil;
    AMASession *__block session = nil;
    NSObject<AMAKeyValueStoring> *__block storage = nil;
    AMARollbackHolder *__block rollbackHolder = nil;
    AMAEventNumbersFiller *__block filler = nil;

    beforeEach(^{
        globalNumberStorage = [[AMAIncrementableValueStorageMock alloc] init];
        globalNumberStorage.currentMockValue = @15;
        [AMAIncrementableValueStorageFactory stub:@selector(globalEventNumberStorage)
                                        andReturn:globalNumberStorage];
        AMAIncrementableValueStorageMock *clientEventNumber = [[AMAIncrementableValueStorageMock alloc] init];
        clientEventNumber.currentMockValue = @8;
        numberOfTypeStorages = [NSMutableDictionary dictionaryWithObject:clientEventNumber forKey:@4];
        [AMAIncrementableValueStorageFactory stub:@selector(eventNumberOfTypeStorageForEventType:)
                                        withBlock:^id(NSArray *params) {
                                            NSNumber *eventType = params[0];
                                            AMAIncrementableValueStorageMock *storage = numberOfTypeStorages[eventType];
                                            if (storage == nil) {
                                                storage = [[AMAIncrementableValueStorageMock alloc] init];
                                                numberOfTypeStorages[eventType] = storage;
                                            }
                                            return storage;
                                        }];
        event = [[AMAEvent alloc] init];
        event.type = 4;
        session = [[AMASession alloc] init];
        session.eventSeq = 23;

        storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        rollbackHolder = [AMARollbackHolder nullMock];
        filler = [[AMAEventNumbersFiller alloc] init];
    });

    context(@"Generic event", ^{
        beforeEach(^{
            [filler fillNumbersOfEvent:event session:session storage:storage rollback:rollbackHolder error:nil];
        });
        it(@"Should fill seq", ^{
            [[theValue(event.sequenceNumber) should] equal:theValue(23)];
        });
        it(@"Should fill global event number", ^{
            [[theValue(event.globalNumber) should] equal:theValue(16)];
        });
        it(@"Should increment global event number", ^{
            [[globalNumberStorage.currentMockValue should] equal:@16];
        });
        it(@"Should fill event number of type", ^{
            [[theValue(event.numberOfType) should] equal:theValue(9)];
        });
        it(@"Should increment global event number", ^{
            [[numberOfTypeStorages[@4].currentMockValue should] equal:@9];
        });
    });
});

SPEC_END

