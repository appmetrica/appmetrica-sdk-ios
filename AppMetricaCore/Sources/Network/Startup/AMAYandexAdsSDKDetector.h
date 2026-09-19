#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef Class _Nullable (^AMAAdsMarkerClassResolver)(NSString *name);

@interface AMAYandexAdsSDKDetector : NSObject

@property (nonatomic, assign, readonly) BOOL isPresent;

+ (instancetype)sharedInstance;
- (instancetype)initWithClassResolver:(AMAAdsMarkerClassResolver)classResolver;

@end

NS_ASSUME_NONNULL_END
