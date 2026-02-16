
#import "AMAKSCrashSystemInfoProvider.h"
#import "AMAKSCrashReportDecoder.h"
#import "AMAKSCrash.h"
#import "AMAKSCrashImports.h"
#import "AMASystemInfo.h"

@interface AMAKSCrashSystemInfoProvider ()

@property (nonatomic, strong, readonly) AMAKSCrashReportDecoder *decoder;

@end

@implementation AMAKSCrashSystemInfoProvider

- (instancetype)init
{
    return [self initWithDecoder:[[AMAKSCrashReportDecoder alloc] init]];
}

- (instancetype)initWithDecoder:(AMAKSCrashReportDecoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _decoder = decoder;
    }
    return self;
}

- (AMASystemInfo *)currentSystemInfo
{
    NSDictionary *systemInfo = KSCrash.sharedInstance.systemInfo;
    return [self.decoder systemInfoForDictionary:systemInfo];
}

@end
