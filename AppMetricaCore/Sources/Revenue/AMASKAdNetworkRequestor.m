
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
#if !TARGET_OS_TV
    AMALogInfo(@"Updating conversion value: %ld", (long) value);
    [SKAdNetwork updateConversionValue:value];
    return YES;
#else
    return NO;
#endif
}

#pragma mark - Private -

- (BOOL)isFirstExecution
{
    return [AMAMetricaConfiguration sharedInstance].persistent.hadFirstStartup == NO;
}

@end
