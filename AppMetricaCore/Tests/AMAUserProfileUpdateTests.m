
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAUserProfileUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAAttributeUpdateValidating.h"

SPEC_BEGIN(AMAUserProfileUpdateTests)

describe(@"AMAUserProfileUpdate", ^{

    NSArray *__block validators = nil;
    NSArray *__block attributeUpdates = nil;
    AMAUserProfileUpdate *__block update = nil;

    beforeEach(^{
        validators = @[ [KWMock nullMockForProtocol:@protocol(AMAAttributeUpdateValidating)] ];
        attributeUpdates = @[ [AMAAttributeUpdate nullMock] ];
        update = [[AMAUserProfileUpdate alloc] initWithAttributeUpdates:attributeUpdates validators:validators];
    });
    
    it(@"Should store attribute update", ^{
        [[update.attributeUpdates should] equal:attributeUpdates];
    });
    it(@"Should store validators", ^{
        [[update.validators should] equal:validators];
    });

});

SPEC_END
