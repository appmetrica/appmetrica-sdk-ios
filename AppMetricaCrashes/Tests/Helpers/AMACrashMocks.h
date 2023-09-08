
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMACrash;
// FIXME: (glinnik) Moved here potentially helpful code for crashes testing. Not compilable for now.
@interface AMACrashMocks : NSObject

+ (NSString *)testErrorName;

+ (NSString *)normalCrashID;
+ (NSString *)bigCrashID;

+ (NSString *)normalCrashType;
+ (NSDictionary *)normalCrashEnvironment;
+ (NSDictionary *)normalCrashAppEnvironment;
+ (AMACrash *)normalCrash;
+ (AMACrash *)legacyCrash;
+ (AMACrash *)crashWithoutAppState;
+ (AMACrash *)previousAppVersionCrash;
+ (AMACrash *)crashWithoutRawData;

+ (NSString *)abortKSCrashFileName;
+ (NSString *)abortWithoutSystemValuesKSCrashFileName;

+ (NSTimeInterval)crashInterval;
+ (NSDate *)normalCrashDate;

+ (AMACrash *)bigCrash;

- (void)initReporterAndSendError:(NSException *)exception;
- (void)reporter:(AMAReporter *)reporter reportException:(NSException *)exception;
- (void)initReporterAndSendErrorWithoutStartingSession:(NSException *)exception;

- (void)restartApplicationAndSendCrash;
- (void)restartApplicationAndSendNotStampedCrash;

- (void)initReporterAndSendNormalCrashWith:(BOOL)isFullReport;
- (void)initReporterAndSendLegacyCrash:(BOOL)isFullReport;
- (AMASession *)createPreviousSessionAndSendCrash;
- (AMASession *)createPreviousSessionAndSendCrashWithCrashDate:(NSDate *)crashDate;
- (AMASession *)createPreviousSessionAndSendNonStampedCrashWithCrashDate:(NSDate *)crashDate;
- (void)createPreviousSessionSetupReporterAndSendCrash;

+ (NSString *)ksCrashPath:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
