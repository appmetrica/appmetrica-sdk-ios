
#import <Foundation/Foundation.h>

@class AMABacktraceSymbolicator;
@class AMACrashReportDecoder;
@class AMADecodedCrashSerializer;
@class AMAErrorModel;
@class AMAPluginErrorDetails;

@protocol AMADateProviding;

@interface AMAExceptionFormatter : NSObject

- (instancetype)initWithDateProvider:(id<AMADateProviding>)dateProvider
                          serializer:(AMADecodedCrashSerializer *)serializer
                        symbolicator:(AMABacktraceSymbolicator *)symbolicator
                             decoder:(AMACrashReportDecoder *)decoder;

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
