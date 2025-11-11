
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAReporterStateStorage.h"
#import "AMAFilledOpenIDComposer.h"

SPEC_BEGIN(AMAFilledOpenIDComposerTests)

describe(@"AMAFilledOpenIDComposer", ^{

    AMAReporterStateStorage *__block storage;
    AMAFilledOpenIDComposer *__block composer;

    beforeEach(^{
        storage = [AMAReporterStateStorage nullMock];
        composer = [[AMAFilledOpenIDComposer alloc] initWithStorage:storage];
    });

    context(@"Compose", ^{
        it(@"Should return correct openID", ^{
            NSUInteger expectedOpenID = 777888;
            [storage stub:@selector(openID) andReturn:theValue(expectedOpenID)];
            [[theValue([composer compose]) should] equal:theValue(expectedOpenID)];
        });
    });

});

SPEC_END


