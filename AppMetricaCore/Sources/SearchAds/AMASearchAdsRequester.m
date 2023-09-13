
#import "AMASearchAdsRequester.h"

#if !TARGET_OS_TV
#import <iAd/ADClient.h>
#endif

NSString *const kAMASearchAdsRequesterErrorDomain = @"io.appmetrica.AMASearchAdsRequester";
NSString *const kAMASearchAdsRequesterErrorDescriptionKey = @"io.appmetrica.AMASearchAdsRequester.error.description";

@interface AMASearchAdsRequester ()

#if !TARGET_OS_TV
@property (nonatomic, strong, readonly) ADClient *cachedClient NS_AVAILABLE_IOS(7_1);
#endif

@end

@implementation AMASearchAdsRequester

#if TARGET_OS_TV

+ (BOOL)isAPIAvailable
{
    return NO;
}

- (void)request
{
}

#else

@synthesize cachedClient = _cachedClient;

+ (ADClient *)adClient NS_AVAILABLE_IOS(7_1)
{
    ADClient *client = nil;
    Class adClientClass = NSClassFromString(@"ADClient");
    if (adClientClass != Nil) {
        if ([adClientClass respondsToSelector:@selector(sharedClient)]) {
            client = [adClientClass sharedClient];
            if ([client respondsToSelector:@selector(requestAttributionDetailsWithBlock:)] == NO) {
                client = nil;
            }
        }
    }
    return client;
}

+ (BOOL)isAPIAvailable
{
    return [[self class] adClient] != nil;
}

- (ADClient *)cachedClient
{
    if (_cachedClient == nil) {
        @synchronized (self) {
            if (_cachedClient == nil) {
                _cachedClient = [[self class] adClient];
            }
        }
    }
    return _cachedClient;
}

- (void)request
{
    __weak __typeof(self) weakSelf = self;
    [self.cachedClient requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (attributionDetails != nil) {
            [strongSelf processAttributionDetails:attributionDetails];
        }
        else {
            [strongSelf processError:error];
        }
    }];
}

- (void)processError:(NSError *)error
{
    NSInteger outerErrorCode = AMASearchAdsRequesterErrorUnknown;
    switch (error.code) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
        case ADClientErrorTrackingRestrictedOrDenied:
        case ADClientErrorUnsupportedPlatform:
            outerErrorCode = AMASearchAdsRequesterErrorAdTrackingLimited;
            break;
        default:
            outerErrorCode = AMASearchAdsRequesterErrorTryLater;
            break;
#else
        case ADClientErrorLimitAdTracking:
            outerErrorCode = AMASearchAdsRequesterErrorAdTrackingLimited;
            break;
        case ADClientErrorUnknown:
            outerErrorCode = AMASearchAdsRequesterErrorTryLater;
            break;
        default:
            outerErrorCode = AMASearchAdsRequesterErrorUnknown;
            break;
#endif
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSUnderlyingErrorKey] = error;
    userInfo[kAMASearchAdsRequesterErrorDescriptionKey] = error.localizedDescription;
    NSError *outerError = [NSError errorWithDomain:kAMASearchAdsRequesterErrorDomain
                                              code:outerErrorCode
                                          userInfo:[userInfo copy]];

    [self.delegate searchAdsRequester:self didFailedWithError:outerError];
}

- (void)processAttributionDetails:(NSDictionary *)dictionary
{
    [self.delegate searchAdsRequester:self didSucceededWithInfo:dictionary];
}

#endif

@end
