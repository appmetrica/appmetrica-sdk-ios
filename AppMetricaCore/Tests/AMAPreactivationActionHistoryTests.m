
#import <Kiwi/Kiwi.h>
#import "AMAPreactivationActionHistory.h"
#import "AMAEnvironmentContainerActionHistory.h"

SPEC_BEGIN(AMAPreactivationActionHistoryTests)

describe(@"AMAPreactivationHistory", ^{

    context(@"Init", ^{
        AMAPreactivationActionHistory *history = [[AMAPreactivationActionHistory alloc] init];
        it(@"App Environment should not be nil", ^{
            [[history.appEnvironment shouldNot] beNil];
        });
        it(@"User profile ID should be nil", ^{
            [[history.userProfileID should] beNil];
        });
    });
});

SPEC_END
