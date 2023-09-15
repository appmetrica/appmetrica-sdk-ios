
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAStringAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMAStringAttributeValueUpdateTests)

describe(@"AMAStringAttributeValueUpdate", ^{

    NSString *const stringValue = @"VALUE";
    NSString *const truncatedValue = @"TRUNCATED";

    AMAAttributeValue *__block value = nil;
    NSObject<AMAStringTruncating> *__block truncator = nil;
    AMAStringAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
        truncator = [KWMock nullMockForProtocol:@protocol(AMAStringTruncating)];
        [truncator stub:@selector(truncatedString:onTruncation:) andReturn:truncatedValue];
        update = [[AMAStringAttributeValueUpdate alloc] initWithValue:stringValue truncator:truncator];
    });

    it(@"Should truncate value", ^{
        [[truncator should] receive:@selector(truncatedString:onTruncation:) withArguments:stringValue, nil];
        [update applyToValue:value];
    });

    it(@"Should update existing value", ^{
        value.stringValue = @"PREVIOUS";
        [update applyToValue:value];
        [[value.stringValue should] equal:truncatedValue];
    });

    it(@"Should set new value if undefined", ^{
        [update applyToValue:value];
        [[value.stringValue should] equal:truncatedValue];
    });

    it(@"Should conform to AMAAttributeValueUpdate", ^{
        [[update should] conformToProtocol:@protocol(AMAAttributeValueUpdate)];
    });
});

SPEC_END
