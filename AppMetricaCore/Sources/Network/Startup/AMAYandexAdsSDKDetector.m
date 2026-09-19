#import "AMAYandexAdsSDKDetector.h"

@interface AMAYandexAdsSDKDetector ()

@property (nonatomic, copy, readonly) AMAAdsMarkerClassResolver classResolver;
@property (nonatomic, strong) NSNumber *cachedPresence;

@end

@implementation AMAYandexAdsSDKDetector

+ (instancetype)sharedInstance
{
    static AMAYandexAdsSDKDetector *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithClassResolver:^Class(NSString *name) {
        return NSClassFromString(name);
    }];
}

- (instancetype)initWithClassResolver:(AMAAdsMarkerClassResolver)classResolver
{
    self = [super init];
    if (self != nil) {
        _classResolver = [classResolver copy];
    }
    return self;
}

- (BOOL)isPresent
{
    @synchronized (self) {
        if (self.cachedPresence == nil) {
            // Ads SDK declares @objc(AnalyticsAdsMarker).
            self.cachedPresence = @(self.classResolver(@"AnalyticsAdsMarker") != Nil);
        }
        return self.cachedPresence.boolValue;
    }
}

@end
