#import "AMAYandexAdsStartupStateProvider.h"
#import "AMASavedAppMetricaConfigRepository.h"
#import "AMAActivationTypeResolver.h"
#import "AMAYandexAdsSDKDetector.h"
#import "AMAMetricaPersistentConfiguration.h"

static NSString *const kAMAStartupYandexAdsOnlyParameter = @"hoyas";

@interface AMAYandexAdsStartupStateProvider ()

@property (nonatomic, strong, readonly) AMASavedAppMetricaConfigRepository *repository;
@property (nonatomic, strong, readonly) AMAYandexAdsSDKDetector *detector;
@property (nonatomic, strong, readonly) AMAMetricaPersistentConfiguration *persistentConfiguration;

@end

@implementation AMAYandexAdsStartupStateProvider

- (instancetype)initWithRepository:(AMASavedAppMetricaConfigRepository *)repository
                          detector:(AMAYandexAdsSDKDetector *)detector
           persistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
{
    self = [super init];
    if (self != nil) {
        _repository = repository;
        _detector = detector;
        _persistentConfiguration = persistentConfiguration;
    }
    return self;
}

- (BOOL)isYandexAdsOnly
{
    if (self.detector.isPresent == NO) {
        return NO;
    }
    AMAAppMetricaConfiguration *configuration = [self.repository validSavedConfig];
    BOOL hasOrdinaryConfiguration = configuration != nil &&
        [AMAActivationTypeResolver isAnonymousConfiguration:configuration] == NO;
    return hasOrdinaryConfiguration == NO;
}

- (NSSet<NSString *> *)reservedParameterKeys
{
    return [NSSet setWithObject:kAMAStartupYandexAdsOnlyParameter];
}

- (NSDictionary<NSString *, NSString *> *)startupParameters
{
    return @{ kAMAStartupYandexAdsOnlyParameter: self.isYandexAdsOnly ? @"1" : @"0" };
}

- (BOOL)requiresUpdateForParameters:(NSDictionary<NSString *, NSString *> *)parameters
{
    BOOL isYandexAdsOnly = parameters[kAMAStartupYandexAdsOnlyParameter].boolValue;
    NSNumber *lastYandexAdsOnlyState = self.persistentConfiguration.lastStartupYandexAdsOnlyState;
    return lastYandexAdsOnlyState == nil
        ? isYandexAdsOnly
        : lastYandexAdsOnlyState.boolValue != isYandexAdsOnly;
}

- (void)startupDidSucceedWithParameters:(NSDictionary<NSString *, NSString *> *)parameters
{
    self.persistentConfiguration.lastStartupYandexAdsOnlyState =
        @(parameters[kAMAStartupYandexAdsOnlyParameter].boolValue);
}

@end
