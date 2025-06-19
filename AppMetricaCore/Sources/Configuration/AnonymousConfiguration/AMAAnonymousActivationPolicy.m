
#import "AMAAnonymousActivationPolicy.h"
#import "AppMetricaCore.h"

static const BOOL kAMAAnonymousActivationForReporterAllowedDefault = YES;
static NSString *const kAMAActivationForReporterAllowedKey = @"io.appmetrica.library_reporter_activation_allowed";

@interface AMAAnonymousActivationPolicy ()

@property (nonatomic, assign) NSNumber *isAnonymousActivationAllowedForReporter;
@property (nonatomic, strong, readonly) NSBundle *sourceBundle;

@end

@implementation AMAAnonymousActivationPolicy

@synthesize isAnonymousActivationAllowedForReporter = _isAnonymousActivationAllowedForReporter;

- (instancetype)init
{
    return [self initWithBundle:[NSBundle mainBundle]];
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    if (self) {
        _sourceBundle = bundle;
        _isAnonymousActivationAllowedForReporter = nil;
    }
    return self;
}

- (BOOL)isAnonymousActivationAllowedForReporter
{
    if (_isAnonymousActivationAllowedForReporter == nil) {
        @synchronized (self) {
            if (_isAnonymousActivationAllowedForReporter == nil) {
                id value = [self.sourceBundle objectForInfoDictionaryKey:kAMAActivationForReporterAllowedKey];
                if ([value isKindOfClass:[NSNumber class]]) {
                    _isAnonymousActivationAllowedForReporter = value;
                } else {
                    _isAnonymousActivationAllowedForReporter = @(kAMAAnonymousActivationForReporterAllowedDefault);
                }
            }
        }
    }
    return [_isAnonymousActivationAllowedForReporter boolValue];
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
