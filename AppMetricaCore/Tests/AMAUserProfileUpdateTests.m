
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAUserProfileUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAAttributeUpdateValidating.h"

SPEC_BEGIN(AMAUserProfileUpdateTests)

describe(@"AMAUserProfileUpdate", ^{

    NSArray *__block validators = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAUserProfileUpdate *__block update = nil;

    beforeEach(^{
        validators = @[ [KWMock nullMockForProtocol:@protocol(AMAAttributeUpdateValidating)] ];
        attributeUpdate = [AMAAttributeUpdate nullMock];
        update = [[AMAUserProfileUpdate alloc] initWithAttributeUpdate:attributeUpdate validators:validators];
    });
    
    it(@"Should store attribute update", ^{
        [[update.attributeUpdate should] equal:attributeUpdate];
    });
    it(@"Should store validators", ^{
        [[update.validators should] equal:validators];
    });

});

SPEC_END
