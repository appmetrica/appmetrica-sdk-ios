
#import "AMAEventComposerProvider.h"
#import "AMAEventComposer.h"
#import "AMAEventComposerBuilder.h"
#import "AMADummyLocationComposer.h"
#import "AMADummyAppEnvironmentComposer.h"
#import "AMAFilledErrorEnvironmentComposer.h"
#import "AMAEventTypes.h"
#import "AMAReporterStateStorage.h"

@interface AMAEventComposerProvider ()

@property(nonatomic, strong, readonly) AMAReporterStateStorage *stateStorage;
@property(nonatomic, strong, readonly) NSDictionary<NSNumber *, AMAEventComposer *> *composers;

@end

@implementation AMAEventComposerProvider

- (instancetype)initWithStateStorage:(AMAReporterStateStorage *)storage
{
    self = [super init];
    if (self != nil) {

        AMAEventComposerBuilder *crashComposerBuilder = [AMAEventComposerBuilder defaultBuilderWithStorage:storage];
        [crashComposerBuilder addAppEnvironmentComposer:[AMADummyAppEnvironmentComposer new]];
        AMAEventComposer *crashComposer = [crashComposerBuilder build];

        AMAEventComposerBuilder *noLocationAndNetworkInfoComposerBuilder =
            [AMAEventComposerBuilder defaultBuilderWithStorage:storage];
        [noLocationAndNetworkInfoComposerBuilder addLocationComposer:[AMADummyLocationComposer new]];
        AMAEventComposer *noLocationAndNetworkInfoComposer = [noLocationAndNetworkInfoComposerBuilder build];

        AMAEventComposerBuilder *errorComposerBuilder = [AMAEventComposerBuilder defaultBuilderWithStorage:storage];
        [errorComposerBuilder addErrorEnvironmentComposer:
                                  [[AMAFilledErrorEnvironmentComposer alloc] initWithStorage:storage]];

        _stateStorage = storage;
        _composers = @{
                @(AMAEventTypeAlive) : noLocationAndNetworkInfoComposer,
                @(AMAEventTypeProtobufCrash) : crashComposer,
                @(AMAEventTypeProtobufANR) : crashComposer,
                @(AMAEventTypeProtobufError) : [errorComposerBuilder build],
        };
    }
    return self;
}

- (AMAEventComposer *)composerForType:(NSUInteger)type
{
    AMAEventComposer *composer = self.composers[@(type)];
    if (!composer) {
        composer = [[AMAEventComposerBuilder defaultBuilderWithStorage:self.stateStorage] build];
    }
    return composer;
}

@end
