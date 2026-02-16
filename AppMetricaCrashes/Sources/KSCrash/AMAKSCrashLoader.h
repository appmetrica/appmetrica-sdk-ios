
#import <Foundation/Foundation.h>
#import "AMAUnhandledCrashDetector.h"
#import "AMAKSCrashReportDecoder.h"
#import "AMACrashLoaderDelegate.h"

@class AMACrashSafeTransactor;
@class AMADecodedCrash;
@class AMAUnhandledCrashDetector;

extern NSString *const kAMAApplicationNotRespondingCrashType;

@interface AMAKSCrashLoader : NSObject <AMAKSCrashReportDecoderDelegate, AMACrashLoading>

@property (nonatomic, assign) BOOL isUnhandledCrashDetectingEnabled;
@property (nonatomic, assign, readonly) NSNumber *crashedLastLaunch;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)unhandledCrashDetector
                                    transactor:(AMACrashSafeTransactor *)transactor;

- (void)enableCrashLoader;
- (void)enableRequiredMonitoring;
- (NSArray<AMADecodedCrash *> *)syncLoadCrashReports;

+ (void)purgeRawCrashReport:(NSNumber *)reportID;
+ (void)purgeAllRawCrashReports;
+ (void)purgeCrashesDirectory;

// TODO(vasileuski): make as instance methods
+ (void)addCrashContext:(NSDictionary *)crashContext;
+ (NSDictionary *)crashContext;

- (void)reportANR;

@end
