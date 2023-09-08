
#import <Foundation/Foundation.h>
#import "AMAUnhandledCrashDetector.h"

@protocol AMACrashLoaderDelegate;
@class AMADecodedCrash;
@class AMAUnhandledCrashDetector;

extern NSString *const kAMAApplicationNotRespondingCrashType;

@interface AMACrashLoader : NSObject

@property (nonatomic, weak) id<AMACrashLoaderDelegate> delegate;
@property (nonatomic, assign) BOOL isUnhandledCrashDetectingEnabled;
@property (nonatomic, assign, readonly) NSNumber *crashedLastLaunch;

- (instancetype)initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)unhandledCrashDetector;

- (void)enableCrashLoader;
- (void)enableRequiredMonitoring;
- (void)enableSwapOfCxaThrow;
- (void)loadCrashReports;

+ (void)purgeRawCrashReport:(NSNumber *)reportID;
+ (void)purgeAllRawCrashReports;
+ (void)purgeCrashesDirectory;

// TODO(vasileuski): make as instance methods
+ (void)addCrashContext:(NSDictionary *)crashContext;
+ (NSDictionary *)crashContext;

- (void)reportANR;

@end

@protocol AMACrashLoaderDelegate <NSObject>

- (void)crashLoader:(AMACrashLoader *)crashLoader
       didLoadCrash:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error;

- (void)crashLoader:(AMACrashLoader *)crashLoader didLoadANR:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;

- (void)crashLoader:(AMACrashLoader *)crashLoader didDetectProbableUnhandledCrash:(AMAUnhandledCrashType)crashType;

@end
