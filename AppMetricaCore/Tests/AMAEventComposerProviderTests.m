
#import <Kiwi/Kiwi.h>
#import "AMAEventComposerProvider.h"
#import "AMAReporterStateStorage.h"
#import "AMAEventTypes.h"
#import "AMAEventComposer.h"
#import "AMADummyLocationComposer.h"
#import "AMADummyAppEnvironmentComposer.h"
#import "AMADummyErrorEnvironmentComposer.h"
#import "AMAFilledAppEnvironmentComposer.h"
#import "AMAFilledErrorEnvironmentComposer.h"
#import "AMAFilledLocationComposer.h"
#import "AMAFilledLocationEnabledComposer.h"
#import "AMAFilledProfileIdComposer.h"
#import "AMAFilledOpenIDComposer.h"
#import "AMAOpenIDComposer.h"

@interface AMAEventComposer ()

@property(nonatomic, strong, readonly) id profileIdComposer;
@property(nonatomic, strong, readonly) id locationComposer;
@property(nonatomic, strong, readonly) id locationEnabledComposer;
@property(nonatomic, strong, readonly) id networkInfoComposer;
@property(nonatomic, strong, readonly) id appEnvironmentComposer;
@property(nonatomic, strong, readonly) id errorEnvironmentComposer;
@property(nonatomic, strong, readonly) id openIDComposer;

@end

SPEC_BEGIN(AMAEventComposerProviderTests)

describe(@"AMAEventComposerProvider", ^{

    AMAEventComposer *__block eventComposer = nil;
    AMAEventComposerProvider *__block eventComposerProvider = nil;

    beforeEach(^{
        AMAReporterStateStorage *storage = [AMAReporterStateStorage nullMock];
        eventComposerProvider = [[AMAEventComposerProvider alloc] initWithStateStorage:storage];
    });

    context(@"Special types", ^{
        it(@"Should change Location and NetworkInfo for Alive", ^{
            eventComposer = [eventComposerProvider composerForType:AMAEventTypeAlive];
            [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMAFilledAppEnvironmentComposer.class];
            [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMADummyErrorEnvironmentComposer.class];
            [[eventComposer.locationComposer should] beMemberOfClass:AMADummyLocationComposer.class];
            [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
            [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
            [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
        });
        it(@"Should change AppEnvironment for Crash", ^{
            eventComposer = [eventComposerProvider composerForType:AMAEventTypeCrash];
            [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMADummyAppEnvironmentComposer.class];
            [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMADummyErrorEnvironmentComposer.class];
            [[eventComposer.locationComposer should] beMemberOfClass:AMAFilledLocationComposer.class];
            [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
            [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
            [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
        });
        it(@"Should change AppEnvironment for ProtobufCrash", ^{
            eventComposer = [eventComposerProvider composerForType:AMAEventTypeProtobufCrash];
            [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMADummyAppEnvironmentComposer.class];
            [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMADummyErrorEnvironmentComposer.class];
            [[eventComposer.locationComposer should] beMemberOfClass:AMAFilledLocationComposer.class];
            [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
            [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
            [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
        });
        it(@"Should change AppEnvironment for ProtobufANR", ^{
            eventComposer = [eventComposerProvider composerForType:AMAEventTypeProtobufANR];
            [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMADummyAppEnvironmentComposer.class];
            [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMADummyErrorEnvironmentComposer.class];
            [[eventComposer.locationComposer should] beMemberOfClass:AMAFilledLocationComposer.class];
            [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
            [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
            [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
        });
        it(@"Should change ErrorEnvironment for ProtobufError", ^{
            eventComposer = [eventComposerProvider composerForType:AMAEventTypeProtobufError];
            [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMAFilledAppEnvironmentComposer.class];
            [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMAFilledErrorEnvironmentComposer.class];
            [[eventComposer.locationComposer should] beMemberOfClass:AMAFilledLocationComposer.class];
            [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
            [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
            [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
        });
    });

    context(@"Other types", ^{
        __auto_type excludedTypes = @[
                @(AMAEventTypeAlive),
                @(AMAEventTypeCrash),
                @(AMAEventTypeProtobufCrash),
                @(AMAEventTypeProtobufANR),
                @(AMAEventTypeProtobufError),
        ];
        for (AMAEventType eventType = AMAEventTypeInit; eventType <= AMAEventTypeECommerce; ++eventType) {
            if (![excludedTypes containsObject:@(eventType)]){
                it([NSString stringWithFormat:@"Should use defaults for type %u", (unsigned int) eventType],^{
                    eventComposer = [eventComposerProvider composerForType:eventType];
                    [[eventComposer.appEnvironmentComposer should] beMemberOfClass:AMAFilledAppEnvironmentComposer.class];
                    [[eventComposer.errorEnvironmentComposer should] beMemberOfClass:AMADummyErrorEnvironmentComposer.class];
                    [[eventComposer.locationComposer should] beMemberOfClass:AMAFilledLocationComposer.class];
                    [[eventComposer.locationEnabledComposer should] beMemberOfClass:AMAFilledLocationEnabledComposer.class];
                    [[eventComposer.profileIdComposer should] beMemberOfClass:AMAFilledProfileIdComposer.class];
                    [[eventComposer.openIDComposer should] beMemberOfClass:AMAFilledOpenIDComposer.class];
                });
            }
        }
    });
});

SPEC_END
