
#import "AMAIDSyncStartupResponse.h"
#import "AMAIDSyncStartupConfiguration.h"

@implementation AMAIDSyncStartupResponse

- (instancetype)initWithStartupConfiguration:(AMAIDSyncStartupConfiguration *)configuration
{
    self = [super init];
    if (self != nil) {
        _configuration = configuration;
    }
    return self;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", super.description];
    [description appendFormat:@", self.configuration=%@", self.configuration];
    [description appendString:@">"];
    return description;
}
#endif

@end
