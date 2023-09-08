
#import "AMACrashLogging.h"
#import "AMAAppCrashProcessor.h"
#import "AMADecodedCrash.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMASignal.h"
#import "AMADecodedCrashSerializer.h"
#import "AMACrash+Private.h"
#import "AMAInfo.h"
#import "AMACrashProcessingReporting.h"

@interface AMAAppCrashProcessor ()

@property (nonatomic, strong, readonly) AMADecodedCrashSerializer *serializer;

@end

static NSString *const kAMAMetricaSource = @"metrica";

@implementation AMAAppCrashProcessor

@synthesize extendedCrashReporters = _extendedCrashReporters;

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
{
    return [self initWithIgnoredSignals:ignoredSignals serializer:[[AMADecodedCrashSerializer alloc] init]];
}

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals serializer:(AMADecodedCrashSerializer *)serializer
{
    self = [super init];

    if (self != nil) {
        _serializer = serializer;
        _ignoredCrashSignals = [ignoredSignals copy];
        _extendedCrashReporters = [NSMutableSet set];
    }

    return self;
}

- (NSString *)identifier
{
    return @"AppCrashProcessor";
}

- (void)processCrash:(AMADecodedCrash *)decodedCrash
{
    if ([self shouldIgnoreCrash:decodedCrash]) {
        return;
    }
    NSData *rawData = [self.serializer dataForCrash:decodedCrash];
    AMACrash *encodedCrash = [[AMACrash alloc] initWithRawData:rawData
                                                          date:decodedCrash.info.timestamp
                                                      appState:decodedCrash.appState
                                              errorEnvironment:decodedCrash.errorEnvironment
                                                appEnvironment:decodedCrash.appEnvironment];
    
    //TODO: Crashes fixing
//    [AMAAppMetrica reportCrash:encodedCrash onFailure:^(NSError *error) {
//        if (error != nil) {
//            AMALogError(@"Failed to report app crash with error: %@", error);
//        }
//    }];
    [self reportSafely:nil];
}

- (void)processANR:(AMADecodedCrash *)decodedCrash
{
    NSData *rawData = [self.serializer dataForCrash:decodedCrash];
    AMACrash *encodedCrash = [[AMACrash alloc] initWithRawData:rawData
                                                          date:decodedCrash.info.timestamp
                                                      appState:decodedCrash.appState
                                              errorEnvironment:decodedCrash.errorEnvironment
                                                appEnvironment:decodedCrash.appEnvironment];

//    [AMAAppMetrica reportANR:encodedCrash onFailure:^(NSError *error) {
//        if (error != nil) {
//            AMALogInfo(@"Failed to report app crash with error: %@", error);
//        }
//    }];
}

- (void)processError:(NSString *)message exception:(NSException *)exception
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    [AMAAppMetrica reportError:message exception:exception onFailure:^(NSError *error) {
//        if (error != nil) {
//            AMALogError(@"Failed to report own AppMetrica error with error: %@", error);
//        }
//    }];
    [self reportSafely:message];
}
#pragma clang diagnostic pop

- (BOOL)shouldIgnoreCrash:(AMADecodedCrash *)decodedCrash
{
    return [self.ignoredCrashSignals containsObject:@(decodedCrash.crash.error.signal.signal)];
}

#pragma mark - Private

- (void)reportSafely:(NSString *)message
{
    NSString *resultMessage = message.length == 0 ? @"Unhandled crash" : message;
    for (id<AMACrashProcessingReporting> crashReporter in self.extendedCrashReporters) {
        if (crashReporter != nil) {
            [crashReporter reportCrash:resultMessage];
        }
    }
}

@end
