
#import <Foundation/Foundation.h>

@class AMAErrorModel;
@class AMAPluginErrorDetails;

@protocol AMAExceptionFormatting <NSObject>

- (NSData *)formattedException:(NSException *)exception;
- (NSData *)formattedError:(AMAErrorModel *)error;
- (NSData *)formattedCrashErrorDetails:(AMAPluginErrorDetails *)errorDetails
                        bytesTruncated:(NSUInteger *)bytesTruncated;
- (NSData *)formattedErrorErrorDetails:(AMAPluginErrorDetails *)errorDetails

                        bytesTruncated:(NSUInteger *)bytesTruncated;
- (NSData *)formattedCustomErrorErrorDetails:(AMAPluginErrorDetails *)errorDetails
                                  identifier:(NSString *)identifier
                              bytesTruncated:(NSUInteger *)bytesTruncated;

@end
