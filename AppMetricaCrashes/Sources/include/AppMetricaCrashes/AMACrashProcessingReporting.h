
#import <Foundation/Foundation.h>

NS_SWIFT_NAME(CrashProcessingReporting)
@protocol AMACrashProcessingReporting <NSObject>

- (void)reportCrash:(NSString *)message;

@end
