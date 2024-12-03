#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const AMAInfoPlistAppGroupIdentifierKey;

@interface AMAAppGroupIdentifierProvider : NSObject

- (instancetype)initWithBundle:(NSBundle *)bundle;

@property (readonly, nullable) NSString *appGroupIdentifier;

@end

NS_ASSUME_NONNULL_END
