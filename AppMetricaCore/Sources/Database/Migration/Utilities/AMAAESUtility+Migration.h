
#import <Foundation/Foundation.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

@interface AMAAESUtility (Migration)

+ (NSData *)migrationIv:(NSString *)migrationSource;
+ (NSData *)md5_migrationIv;

@end
