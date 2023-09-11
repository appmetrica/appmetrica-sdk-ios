
#import "AMACore.h"

@implementation AMAServiceConfiguration

- (instancetype)initStartupObserver:(id<AMAExtendedStartupObserving>)startupObserver
          reporterStorageController:(id<AMAReporterStorageControlling>)reporterStorageController
{
    self = [super init];
    if (self) {
        _startupObserver = startupObserver;
        _reporterStorageController = reporterStorageController;
    }
    return self;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", super.description];
    [description appendFormat:@", self.startupObserver=%@", self.startupObserver];
    [description appendFormat:@", self.reporterStorageController=%@", self.reporterStorageController];
    return description;
}
#endif

@end
