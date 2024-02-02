
#import <Foundation/Foundation.h>

@class AMACrashReporter;
@class AMADecodedCrash;
@class AMADecodedCrashSerializer;
@class AMAErrorModel;
@class AMAExceptionFormatter;
@protocol AMACrashProcessingReporting;

@interface AMACrashProcessor : NSObject

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *ignoredCrashSignals;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter
                    extendedProcessors:(NSArray<id<AMACrashProcessingReporting>> *)extendedCrashProcessors;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter
                             formatter:(AMAExceptionFormatter *)formatter
                    extendedProcessors:(NSArray<id<AMACrashProcessingReporting>> *)extendedCrashProcessors NS_DESIGNATED_INITIALIZER;

- (void)processCrash:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processError:(NSError *)error;

@end
