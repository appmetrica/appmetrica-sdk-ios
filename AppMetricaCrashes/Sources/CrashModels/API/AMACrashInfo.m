
#import "AMACrashInfo.h"

@interface AMACrashInfo ()

@property (nonatomic, copy, readwrite, nullable) NSString *identifier;
@property (nonatomic, strong, readwrite, nullable) NSDate *timestamp;

@end

@implementation AMACrashInfo

- (instancetype)initWithCrashReportVersion:(NSString *)crashReportVersion
{
    self = [super init];
    if (self != nil) {
        _crashReportVersion = [crashReportVersion copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMAMutableCrashInfo *copy = [[AMAMutableCrashInfo alloc] initWithCrashReportVersion:self.crashReportVersion];
    copy.identifier = self.identifier;
    copy.timestamp = self.timestamp;
    return copy;
}

@end

@implementation AMAMutableCrashInfo

@dynamic identifier;
@dynamic timestamp;

- (id)copyWithZone:(NSZone *)zone
{
    AMACrashInfo *copy = [[AMACrashInfo alloc] initWithCrashReportVersion:self.crashReportVersion];
    copy.identifier = self.identifier;
    copy.timestamp = self.timestamp;
    return copy;
}

@end
