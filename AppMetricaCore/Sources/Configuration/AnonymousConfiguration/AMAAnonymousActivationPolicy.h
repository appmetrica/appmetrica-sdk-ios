
#import <Foundation/Foundation.h>

@interface AMAAnonymousActivationPolicy : NSObject

- (instancetype)initWithBundle:(NSBundle *)bundle;

- (BOOL)isAnonymousActivationAllowedForReporter;

+ (instancetype)sharedInstance;

@end
