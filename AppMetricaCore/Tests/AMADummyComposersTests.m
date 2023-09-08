
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMADummyAppEnvironmentComposer.h"
#import "AMADummyErrorEnvironmentComposer.h"
#import "AMADummyLocationComposer.h"
#import <CoreLocation/CoreLocation.h>

SPEC_BEGIN(AMADummyComposersTests)

describe(@"AMADummyComposers", ^{
    context(@"Compose", ^{
        context(@"AppEnvironment", ^{
            AMADummyAppEnvironmentComposer *composer = [AMADummyAppEnvironmentComposer new];
            it(@"Should return nil", ^{
                [[[composer compose] should] beNil];
            });
        });
        context(@"ErrorEnvironment", ^{
            AMADummyErrorEnvironmentComposer *composer = [AMADummyErrorEnvironmentComposer new];
            it(@"Should return nil", ^{
                [[[composer compose] should] beNil];
            });
        });
        context(@"Location", ^{
            AMADummyLocationComposer *composer = [AMADummyLocationComposer new];
            it(@"Should return nil", ^{
                [[[composer compose] should] beNil];
            });
        });
    });
});

SPEC_END
