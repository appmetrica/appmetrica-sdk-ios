
#import <Foundation/Foundation.h>
#import "AMACore.h"
#import "AMAInfoPlistPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAIronSourceModuleEntryPoint : NSObject <AMAModuleEntryPoint, AMAModulePreActivationHandler>

- (instancetype)init;
- (instancetype)initWithPolicy:(AMAInfoPlistPolicy *)policy NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
