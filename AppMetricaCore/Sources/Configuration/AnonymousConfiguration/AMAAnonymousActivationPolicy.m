
#import "AMAAnonymousActivationPolicy.h"
#import "AppMetricaCore.h"

static BOOL kAMAAnonymousActivationForReporterAllowedDefault = YES;
static NSString *const kAMAActivationForReporterAllowedKey = @"io.appmetrica.library_reporter_activation_allowed";

@interface AMAAnonymousActivationPolicy ()

@property (nonatomic, copy) NSNumber *anonymousActivationAllowedForReporter;
@property (nonatomic, strong, readonly) NSBundle *sourceBundle;

@end

@implementation AMAAnonymousActivationPolicy

- (instancetype)init
{
    return [self initWithBundle:[NSBundle mainBundle]];
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    if (self) {
        _sourceBundle = bundle;
        _anonymousActivationAllowedForReporter = nil;
    }
    return self;
}

- (BOOL)isAnonymousActivationAllowedForReporter
{
    if (_anonymousActivationAllowedForReporter == nil) {
        @synchronized (self) {
            if (_anonymousActivationAllowedForReporter == nil) {
                id value = [self.sourceBundle objectForInfoDictionaryKey:kAMAActivationForReporterAllowedKey];
                if ([value isKindOfClass:[NSNumber class]]) {
                    _anonymousActivationAllowedForReporter = value;
                } else {
                    _anonymousActivationAllowedForReporter = @(kAMAAnonymousActivationForReporterAllowedDefault);
                }
            }
        }
    }
    return [_anonymousActivationAllowedForReporter boolValue];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static AMAAnonymousActivationPolicy *instance;
    dispatch_once(&onceToken, ^{
        instance = [[AMAAnonymousActivationPolicy alloc] init];
    });
    return instance;
}

@end
