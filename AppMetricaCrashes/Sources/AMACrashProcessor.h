
#import <Foundation/Foundation.h>

@class AMACrashReporter;
@class AMADecodedCrash;
@class AMADecodedCrashSerializer;
@class AMAErrorModel;
@class AMAExceptionFormatter;

@interface AMACrashProcessor : NSObject

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *ignoredCrashSignals;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                         crashReporter:(AMACrashReporter *)crashReporter
                             formatter:(AMAExceptionFormatter *)formatter NS_DESIGNATED_INITIALIZER;

- (void)processCrash:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processError:(NSError *)error;

@end
