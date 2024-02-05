
#import <Foundation/Foundation.h>

@class AMAApplicationState;
@class AMASession;
@class AMAReporter;
@class AMAEventBuilder;
@class AMAAppMetricaPreloadInfo;
@protocol AMACancelableExecuting;
@protocol AMADatabaseProtocol;
@protocol AMAAsyncExecuting;
@protocol AMASyncExecuting;

@interface AMAReporterTestHelper : NSObject

+ (NSString *)defaultApiKey;
+ (NSString *)octopusApiKey;
+ (NSTimeInterval)acceptableEventDeltaOffset;
+ (NSDictionary *)testUserInfo;

+ (NSString *)testEventName;

+ (AMAApplicationState *)normalApplicationState;
+ (AMAApplicationState *)previousAppVersionState;

+ (NSString *)testJSONValue;

- (AMAReporter *)appReporter;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                                async:(BOOL)isAsync;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                                async:(BOOL)isAsync
                             inMemory:(BOOL)inMemory;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                                async:(BOOL)isAsync
                             inMemory:(BOOL)inMemory
                          preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo;
- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                             executor:(id<AMACancelableExecuting, AMASyncExecuting>)executor
                             inMemory:(BOOL)inMemory
                          preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
             attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor;

- (NSObject<AMADatabaseProtocol> *)databaseForApiKey:(NSString *)apiKey;

- (void)initReporterAndSendEventWithParameters:(NSDictionary *)parameters;
- (void)initReporterAndSendEventWithParameters:(NSDictionary *)parameters async:(BOOL)isAsync;
- (void)initReporterAndSendEventWithoutStartingSessionWithParameters:(NSDictionary *)parameters;
- (void)initReporterAndSendEventToExpiredSessionWithParameters:(NSDictionary *)parameters;
- (void)initReporterAndSendEventToExpiredSessionWithParameters:(NSDictionary *)parameters async:(BOOL)isAsync;
- (void)initReporterAndSendEventToSessionWithDate:(NSDate *)date;
- (void)initReporterTwice;
- (void)initReporterAndCreateThreeSessionsWithDifferentAppStates;
- (void)sendEvent;
- (void)restartApplication;

- (void)createAndFinishBackgroundSessionWithEventStartedAt:(NSDate *)date;
- (void)createBackgroundSessionWithEventStartedAt:(NSDate *)date;

- (void)createForegroundSessionWithDate:(NSDate *)date;
- (void)createBackgroundSessionWithDate:(NSDate *)date;
- (void)createBackgroundAndStartForegroundSessionWithDate:(NSDate *)date;
- (void)createAndFinishSessionInBackgroundWithDate:(NSDate *)date;
- (void)createAndFinishSessionInForegroundWithDate:(NSDate *)date;
- (void)finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:(AMAReporter *)reporter;

+ (void)stubTimeFromNowSec:(NSTimeInterval) fromNowSecs;
+ (void)cycleReporterWithStubbedDateFromNow:(AMAReporter *)reporter interval:(NSTimeInterval)sinceNow;
+ (void)reportDelayedEvent:(AMAReporter *)reporter delay:(NSTimeInterval)delaySec;

@end
