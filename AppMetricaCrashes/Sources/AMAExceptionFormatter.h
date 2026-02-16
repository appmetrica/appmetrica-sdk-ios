
#import <Foundation/Foundation.h>
#import "AMAExceptionFormatting.h"

@protocol AMADateProviding;
@protocol AMASystemInfoProviding;
@class AMADecodedCrashSerializer;
@class AMABacktraceSymbolicator;

@interface AMAExceptionFormatter : NSObject <AMAExceptionFormatting>

- (instancetype)initWithDateProvider:(id<AMADateProviding>)dateProvider
                          serializer:(AMADecodedCrashSerializer *)serializer
                        symbolicator:(AMABacktraceSymbolicator *)symbolicator
                  systemInfoProvider:(id<AMASystemInfoProviding>)systemInfoProvider;
@end
