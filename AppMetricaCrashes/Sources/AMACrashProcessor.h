
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@class AMADecodedCrashSerializer;
@class AMAErrorModel;
@class AMAExceptionFormatter;
@protocol AMACrashProcessingReporting;

@interface AMACrashProcessor : NSObject

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *ignoredCrashSignals;
@property (nonatomic, strong) NSMutableSet<id<AMACrashProcessingReporting>> *extendedCrashReporters; // FIXME: (glinnik, belanovich-sy) needed any more?

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer;
- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer
                             formatter:(AMAExceptionFormatter *)formatter NS_DESIGNATED_INITIALIZER;

- (void)processCrash:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;
- (void)processError:(AMAErrorModel *)errorModel onFailure:(void (^)(NSError *))onFailure;

@end
