
#import <Foundation/Foundation.h>

@protocol AMACrashProcessingReporting <NSObject>

- (void)reportCrash:(NSString *)message;

@end
