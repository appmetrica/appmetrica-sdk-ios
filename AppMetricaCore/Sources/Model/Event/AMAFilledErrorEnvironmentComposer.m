
#import "AMAFilledErrorEnvironmentComposer.h"
#import "AMAReporterStateStorage.h"
#import "AMAEnvironmentContainer.h"

@interface AMAFilledErrorEnvironmentComposer()

@property(nonatomic, strong, readonly)AMAReporterStateStorage *stateStorage;

@end

@implementation AMAFilledErrorEnvironmentComposer

- (instancetype)initWithStorage:(AMAReporterStateStorage *)storage
{
    self = [super init];
    if (self != nil) {
        _stateStorage = storage;
    }
    return self;
}

- (NSDictionary *)compose
{
    NSDictionary *errorEnvironment = self.stateStorage.errorEnvironment.dictionaryEnvironment;
    return errorEnvironment.count != 0 ? errorEnvironment : nil;
}

@end
