
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMADummyAppEnvironmentComposer.h"
#import "AMADummyEventEnvironmentComposer.h"
#import "AMADummyLocationComposer.h"
#import <CoreLocation/CoreLocation.h>

SPEC_BEGIN(AMADummyComposersTests)

describe(@"AMADummyComposers", ^{
    context(@"Compose", ^{
        let(appEnviromnentComposer, ^id{return [AMADummyAppEnvironmentComposer new];});
        let(eventEnviromnentComposer, ^id{return [AMADummyEventEnvironmentComposer new];});
        let(locationComposer, ^id{return [AMADummyLocationComposer new];});
        
        context(@"AppEnvironment", ^{
            it(@"Should return nil", ^{
                [[[appEnviromnentComposer compose] should] beNil];
            });
            it(@"Should conform to AMAAppEnvironmentComposer", ^{
                [[appEnviromnentComposer should] conformToProtocol:@protocol(AMAAppEnvironmentComposer)];
            });
        });
        context(@"ErrorEnvironment", ^{
            it(@"Should return nil", ^{
                [[[eventEnviromnentComposer compose] should] beNil];
            });
            it(@"Should conform to AMAEventEnvironmentComposer", ^{
                [[eventEnviromnentComposer should] conformToProtocol:@protocol(AMAEventEnvironmentComposer)];
            });
        });
        context(@"Location", ^{
            it(@"Should return nil", ^{
                [[[locationComposer compose] should] beNil];
            });
            it(@"Should conform to AMALocationComposer", ^{
                [[locationComposer should] conformToProtocol:@protocol(AMALocationComposer)];
            });
        });
    });
});

SPEC_END
