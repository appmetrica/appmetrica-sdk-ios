
#import <Foundation/Foundation.h>

@class KSCrash;

@interface AMAKSCrash : NSObject

+ (KSCrash *)sharedInstance;
+ (NSString *)crashesPath;

@end
