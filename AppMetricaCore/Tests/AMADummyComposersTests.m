
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMADummyAppEnvironmentComposer.h"
#import "AMADummyErrorEnvironmentComposer.h"
#import "AMADummyLocationComposer.h"
#import <CoreLocation/CoreLocation.h>

SPEC_BEGIN(AMADummyComposersTests)

describe(@"AMADummyComposers", ^{
    context(@"Compose", ^{
        let(appEvniromnentComposer, ^id{return [AMADummyAppEnvironmentComposer new];});
        context(@"AppEnvironment", ^{
            it(@"Should return nil", ^{
                [[[appEvniromnentComposer compose] should] beNil];
            });
            it(@"Should conform to AMAAppEnvironmentComposer", ^{
                [[appEvniromnentComposer should] conformToProtocol:@protocol(AMAAppEnvironmentComposer)];
            });
        });
        context(@"ErrorEnvironment", ^{
            it(@"Should return nil", ^{
                [[[appEvniromnentComposer compose] should] beNil];
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
