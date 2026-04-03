
#import <StoreKit/StoreKit.h>
#import "AMACore.h"
#import "AMASKAdNetworkRequestor.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"

@interface AMASKAdNetworkRequestor ()

@property (nonatomic, strong, readonly) id<AMADateProviding> dateProvider;

@end

@implementation AMASKAdNetworkRequestor

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static AMASKAdNetworkRequestor *shared = nil;
    dispatch_once(&pred, ^{
        shared = (AMASKAdNetworkRequestor *)[[[self class] alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    return [self initWithDateProvider:[[AMADateProvider alloc] init]];
}

- (instancetype)initWithDateProvider:(id<AMADateProviding>)dateProvider
{
    self = [super init];
    if (self != nil) {
        _dateProvider = dateProvider;
    }
    return self;
}

#pragma mark - Public -

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
#if !TARGET_OS_TV
- (void)registerForAdNetworkAttribution
{
    if (self.isFirstExecution) {
        [SKAdNetwork registerAppForAdNetworkAttribution];
        [AMAMetricaConfiguration sharedInstance].persistent.registerForAttributionTime = self.dateProvider.currentDate;
        AMALogNotify(@"Registered for SKAdNetwork attribution");
    }
    else {
        AMALogNotify(@"Not a first execution of an app. Skipping registering");
    }
}
#endif

- (BOOL)updateConversionValue:(NSInteger)value
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
#if !TARGET_OS_TV
    if (@available(iOS 14.0, *)) {
        AMALogInfo(@"Updating conversion value: %ld", (long) value);
        [SKAdNetwork updateConversionValue:value];
        return YES;
    }
#endif
#endif
    return NO;
}
#pragma clang diagnostic pop

#pragma mark - Private -

- (BOOL)isFirstExecution
{
    return [AMAMetricaConfiguration sharedInstance].persistent.hadFirstStartup == NO;
}

@end
