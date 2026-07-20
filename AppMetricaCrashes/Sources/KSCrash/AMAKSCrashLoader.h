
#import <Foundation/Foundation.h>
#import "AMAUnhandledCrashDetector.h"
#import "AMAKSCrashReportDecoder.h"
#import "AMACrashLoaderDelegate.h"
#import "AMAAppMetricaCrashesConfiguration.h"

@class AMACrashSafeTransactor;
@class AMADecodedCrash;
@class AMAUnhandledCrashDetector;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMAApplicationNotRespondingCrashType;

@interface AMAKSCrashLoader : NSObject <AMAKSCrashReportDecoderDelegate, AMACrashLoading>

@property (nonatomic, assign) BOOL isUnhandledCrashDetectingEnabled;
@property (nonatomic, assign, readonly, nullable) NSNumber *crashedLastLaunch;
@property (nonatomic, assign, nullable) AMAAppMetricaCrashErrorEnvironmentCallback crashErrorEnvironmentCallback;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)unhandledCrashDetector
                                    transactor:(AMACrashSafeTransactor *)transactor;

- (void)enableCrashLoader;
- (void)enableCrashMonitoring;
- (void)enableRequiredMonitoring;
- (NSArray<AMADecodedCrash *> *)syncLoadCrashReports;

+ (void)purgeRawCrashReport:(NSNumber *)reportID;
+ (void)purgeAllRawCrashReports;
+ (void)purgeCrashesDirectory;

// TODO(vasileuski): make as instance methods
+ (void)addCrashContext:(nullable NSDictionary *)crashContext;
+ (nullable NSDictionary *)crashContext;

- (void)reportANR;

@end

NS_ASSUME_NONNULL_END
