
#import <Foundation/Foundation.h>
#import "AMAErrorEnvironmentComposer.h"

@class AMAReporterStateStorage;

@interface AMAFilledErrorEnvironmentComposer : NSObject <AMAErrorEnvironmentComposer>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(AMAReporterStateStorage *)storage;

@end
