
#import "AMACrashLogging.h"
#import "AMAGenericCrashProcessor.h"
#import "AMASymbolsCollection.h"
#import "AMASymbolsManager.h"
#import "AMACrashSymbolicator.h"
#import "AMADecodedCrashSerializer.h"
#import "AMADecodedCrash.h"
#import "AMABacktraceFrame.h"
#import "AMAInfo.h"
#import "AMABacktrace.h"
#import "AMADecodedCrashSerializer.h"
#import "AMACrash+Private.h"

@interface AMAGenericCrashProcessor ()

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, strong, readonly) AMADecodedCrashSerializer *serializer;

@end

@implementation AMAGenericCrashProcessor

@synthesize extendedCrashReporters = _extendedCrashReporters;

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    return [self initWithApiKey:apiKey serializer:[[AMADecodedCrashSerializer alloc] init]];
}

- (instancetype)initWithApiKey:(NSString *)apiKey serializer:(AMADecodedCrashSerializer *)serializer
{
    if ([AMAIdentifierValidator isValidUUIDKey:apiKey] == NO) {
        return nil;
    }

    self = [super init];
    if (self != nil) {
        _apiKey = [apiKey copy];
        _serializer = serializer;
    }
    return self;
}

- (NSString *)identifier
{
    return [[self class] identifierForApiKey:self.apiKey];
}

- (AMACrash *)verifyCrash:(AMADecodedCrash *)decodedCrash
{
    //TODO: Crash fixing
    AMABuildUID *buildUID = [AMABuildUID buildUID];
    //decodedCrash.appBuildUID ?: [AMAMetricaConfiguration sharedInstance].inMemory.appBuildUID;
    
    AMASymbolsCollection *symbolsCollection = [AMASymbolsManager symbolsCollectionForApiKey:self.apiKey
                                                                                   buildUID:buildUID];
    AMADecodedCrash *symbolicatedCrash = [decodedCrash copy];
    BOOL reportNeeded = [AMACrashSymbolicator symbolicateCrash:symbolicatedCrash symbolsCollection:symbolsCollection];
    reportNeeded =
        reportNeeded || [self crash:symbolicatedCrash containsDynamicBinariesFromCollection:symbolsCollection];

    AMACrash *encodedCrash = nil;
    if (reportNeeded) {
        NSData *rawData = [self.serializer dataForCrash:symbolicatedCrash];
        encodedCrash = [[AMACrash alloc] initWithRawData:rawData
                                                    date:symbolicatedCrash.info.timestamp
                                                appState:symbolicatedCrash.appState
                                        errorEnvironment:symbolicatedCrash.errorEnvironment
                                          appEnvironment:symbolicatedCrash.appEnvironment];
    }

    return encodedCrash;
}

- (void)processCrash:(AMADecodedCrash *)decodedCrash
{
    AMACrash *crash = [self verifyCrash:decodedCrash];

    if (crash != nil) {
        id<AMAAppMetricaReporting > reporter = [AMAAppMetrica reporterForApiKey:self.apiKey];
        AMALogInfo(@"Reporting crash with timestamp %@ to apiKey %@", crash.date, self.apiKey);

//        [reporter reportCrash:crash onFailure:^(NSError *error) {
//            if (error != nil) {
//                AMALogInfo(@"Failed to report crash to apiKey %@ with error: %@", self.apiKey,
//                                   error.localizedDescription);
//            }
//        }];
    }
}

- (void)processANR:(AMADecodedCrash *)decodedCrash
{
    AMACrash *crash = [self verifyCrash:decodedCrash];

    if (crash != nil) {
//        AMAReporter *reporter = (AMAReporter *)[AMAAppMetrica reporterForApiKey:self.apiKey];
        AMALogInfo(@"Reporting ANR with timestamp %@ to apiKey %@", crash.date, self.apiKey);

//        [reporter reportANR:crash onFailure:^(NSError *error) {
//            if (error != nil) {
//                AMALogError(@"Failed to report crash to apiKey %@ with error: %@",
//                                    self.apiKey, error.localizedDescription);
//            }
//        }];
    }
}

- (void)processError:(NSString *)message exception:(NSException *)exception
{
//    id<AMAReporting> reporter = [AMAAppMetrica reporterForApiKey:self.apiKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    [reporter reportError:message exception:exception onFailure:^(NSError *error) {
//        if (error != nil) {
//            AMALogError(@"Failed to report error to apiKey %@ with error: %@",
//                                self.apiKey, error.localizedDescription);
//        }
//    }];
#pragma clang diagnostic pop
}

- (BOOL)crash:(AMADecodedCrash *)crash containsDynamicBinariesFromCollection:(AMASymbolsCollection *)collection
{
    if (collection == nil) {
        return NO;
    }

    BOOL containsAnyDynamicBinary = NO;
    for (AMABacktraceFrame *frame in crash.crashedThreadBacktrace.frames) {
        if ([collection containsDynamicBinaryWithName:frame.objectName]) {
            containsAnyDynamicBinary = YES;
            break;
        }
    }
    return containsAnyDynamicBinary;
}

+ (NSString *)identifierForApiKey:(NSString *)apiKey
{
    return [NSString stringWithFormat:@"CrashProcessorForApiKey:%@", apiKey];
}

@end
