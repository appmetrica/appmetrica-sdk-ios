
#import <Foundation/Foundation.h>

@interface AMACrashErrorsFactory : NSObject

+ (NSError *)crashReportDecodingError;
+ (NSError *)crashReportRecrashError;
+ (NSError *)crashUnsupportedReportVersionError:(id)version;

@end
