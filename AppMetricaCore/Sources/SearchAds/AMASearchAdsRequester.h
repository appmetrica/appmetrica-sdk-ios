
#import <Foundation/Foundation.h>

@class AMASearchAdsRequester;

extern NSString *const kAMASearchAdsRequesterErrorDomain;
extern NSString *const kAMASearchAdsRequesterErrorDescriptionKey;

typedef NS_ENUM(NSInteger, AMASearchAdsRequesterErrorCode) {
    AMASearchAdsRequesterErrorUnknown,
    AMASearchAdsRequesterErrorTryLater,
    AMASearchAdsRequesterErrorAdTrackingLimited,
};

@protocol AMASearchAdsRequesterDelegate <NSObject>

@required
- (void)searchAdsRequester:(AMASearchAdsRequester *)requester didSucceededWithInfo:(NSDictionary *)info;
- (void)searchAdsRequester:(AMASearchAdsRequester *)requester didFailedWithError:(NSError *)error;

@end

@interface AMASearchAdsRequester : NSObject

@property (nonatomic, weak) id<AMASearchAdsRequesterDelegate> delegate;

+ (BOOL)isAPIAvailable;

- (void)request;

@end
