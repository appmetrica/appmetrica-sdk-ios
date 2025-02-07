
#import "AMACrashSafeTransactor.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMATransactionReporter : NSObject<AMATransactionReporting>

- (instancetype)initWithApiKey:(NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
