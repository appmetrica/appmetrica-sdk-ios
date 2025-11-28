
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAIncrementableValueStorageFactoryTests)

describe(@"AMAIncrementableValueStorageFactory", ^{

    AMAIncrementableValueStorage *__block storage = nil;

    beforeEach(^{
        storage = [AMAIncrementableValueStorage stubbedNullMockForInit:@selector(initWithKey:defaultValue:)];
    });
    afterEach(^{
        [AMAIncrementableValueStorage clearStubs];
    });

    it(@"Should create valid attribution ID storage", ^{
        [[storage should] receive:@selector(initWithKey:defaultValue:)
                    withArguments:@"attribution.id", theValue(1)];
        [AMAIncrementableValueStorageFactory attributionIDStorage];
    });
    it(@"Should create valid last session ID storage", ^{
        [[storage should] receive:@selector(initWithKey:defaultValue:)
                    withArguments:@"session.id", theValue(9999999999)];
        [AMAIncrementableValueStorageFactory lastSessionIDStorage];
    });
    it(@"Should create valid global event number storage", ^{
        [[storage should] receive:@selector(initWithKey:defaultValue:)
                    withArguments:@"event.number.global", theValue(-1)];
        [AMAIncrementableValueStorageFactory globalEventNumberStorage];
    });
    context(@"Number of type storage", ^{
        it(@"Should create valid storage for type 1", ^{
            [[storage should] receive:@selector(initWithKey:defaultValue:)
                        withArguments:@"event.number.type_1", theValue(-1)];
            [AMAIncrementableValueStorageFactory eventNumberOfTypeStorageForEventType:1];
        });
        it(@"Should create valid storage for type 7", ^{
            [[storage should] receive:@selector(initWithKey:defaultValue:)
                        withArguments:@"event.number.type_7", theValue(-1)];
            [AMAIncrementableValueStorageFactory eventNumberOfTypeStorageForEventType:7];
        });
        it(@"Should create valid storage for type 1000", ^{
            [[storage should] receive:@selector(initWithKey:defaultValue:)
                        withArguments:@"event.number.type_1000", theValue(-1)];
            [AMAIncrementableValueStorageFactory eventNumberOfTypeStorageForEventType:1000];
        });
    });
    it(@"Should create valid request identifier storage", ^{
        [[storage should] receive:@selector(initWithKey:defaultValue:)
                    withArguments:@"request.id", theValue(0)];
        [AMAIncrementableValueStorageFactory requestIdentifierStorage];
    });

});

SPEC_END

