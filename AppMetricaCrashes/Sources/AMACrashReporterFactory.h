
#import <Foundation/Foundation.h>

@protocol AMACrashReporting;
@protocol AMAExceptionFormatting;
@protocol AMAExecuting;
@class AMAHostStateProvider;
@protocol AMAExecutablesUUIDProviding;

@interface AMACrashReporterFactory : NSObject

+ (id<AMACrashReporting>)crashReporterWithExecutor:(id<AMAExecuting>)executor
                                 hostStateProvider:(AMAHostStateProvider *)hostStateProvider;
+ (Class<AMACrashReporting>)crashReporterClass;

+ (id<AMAExceptionFormatting>)exceptionFormatter;

+ (Class<AMAExecutablesUUIDProviding>)executablesUUIDProviderClass;

+ (id<AMAExecutablesUUIDProviding>)executablesUUIDProvider;

@end
