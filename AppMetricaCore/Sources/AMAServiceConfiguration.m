
#import "AMACore.h"

@implementation AMAServiceConfiguration

- (instancetype)initStartupProvider:(id)startupProvider
          reporterStorageController:(id<AMAReporterStorageControlling>)reporterStorageController
{
    self = [super init];
    if (self) {
        _startupProvider = startupProvider;
        _reporterStorageController = reporterStorageController;
    }
    return self;
}

@end
