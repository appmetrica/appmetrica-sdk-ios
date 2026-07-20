#import "AMACrashLogging.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAKSCrashLoader.h"
#import "AMAKSCrashReportDecoder.h"
#import "AMACrashSafeTransactor.h"
#import "AMACrashContext.h"
#import "AMADecodedCrash.h"
#import "AMAKSCrash.h"
#import "AMAKSCrashImports.h"

static NSString *const kAMALoadingCrashReportsTransactionKey = @"KSCrashLoadingReports";
NSString *const kAMAApplicationNotRespondingCrashType = @"AMAApplicationNotRespondingCrashType";

struct AMAAppMetricaCrashErrorEnvironmentWriter {
    const KSCrashReportWriter *ksCrashWriter;
};

static AMAAppMetricaCrashErrorEnvironmentCallback g_crashErrorEnvironmentCallback = NULL;

void AMAAppMetricaCrashErrorEnvironmentWriterAddStringValue(
    const AMAAppMetricaCrashErrorEnvironmentWriter *writer,
    const char *key,
    const char *value
)
{
    if (writer == NULL || writer->ksCrashWriter == NULL || key == NULL || key[0] == '\0' || value == NULL) {
        return;
    }

    writer->ksCrashWriter->addStringElement(writer->ksCrashWriter, key, value);
}

static void AMAAppMetricaKSCrashIsWritingReportCallback(
    const KSCrash_ExceptionHandlingPlan *const plan,
    const KSCrashReportWriter *writer
)
{
    if (plan == NULL || writer == NULL || g_crashErrorEnvironmentCallback == NULL) {
        return;
    }
    if (plan->crashedDuringExceptionHandling) {
        return;
    }

    AMAAppMetricaCrashErrorEnvironmentWriter appMetricaWriter = { .ksCrashWriter = writer };
    writer->beginObject(writer, kAMACrashContextCrashTimeErrorEnvironmentKeyCString);
    g_crashErrorEnvironmentCallback(&appMetricaWriter);
    writer->endContainer(writer);
}

@interface AMAKSCrashLoader () <AMAKSCrashReportDecoderDelegate>

@property (nonatomic, strong) NSMutableDictionary *decoders;
@property (nonatomic, strong) AMAUnhandledCrashDetector *unhandledCrashDetector;
@property (nonatomic, strong, readonly) AMACrashSafeTransactor *transactor;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL monitoringInstalled;
@property (nonatomic, assign) BOOL detectionEnabled;

@property (nonatomic, strong) NSMutableArray *syncLoadedCrashes;

@end

@implementation AMAKSCrashLoader

@synthesize delegate = _delegate;

- (instancetype)initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)unhandledCrashDetector
                                    transactor:(AMACrashSafeTransactor *)transactor
{
    self = [super init];
    if (self != nil)
    {
        _decoders = [NSMutableDictionary dictionary];
        _unhandledCrashDetector = unhandledCrashDetector;
        _transactor = transactor;
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _decoders = nil;
}

- (NSNumber *)crashedLastLaunch
{
    return self.enabled ? @(KSCrash.sharedInstance.crashedLastLaunch) : nil;
}

- (void)enableCrashLoader
{
    [self enableCrashMonitoring];

    @synchronized (self) {
        if (self.detectionEnabled) {
            return;
        }
        self.detectionEnabled = YES;

        [self.unhandledCrashDetector startDetecting];
        self.enabled = YES;
    }
}

- (void)enableCrashMonitoring
{
    @synchronized (self) {
        if (self.monitoringInstalled) {
            return;
        }
        self.monitoringInstalled = YES;

        KSCrashMonitorType monitoring = (
            KSCrashMonitorTypeMachException
            | KSCrashMonitorTypeSignal
            | KSCrashMonitorTypeCPPException
            | KSCrashMonitorTypeNSException
            | KSCrashMonitorTypeUserReported
            | KSCrashMonitorTypeSystem
            | KSCrashMonitorTypeApplicationState
        );
        [self installKSCrashWithMonitoring:monitoring];
        
        [self initializeKSCrashBinaryImageCache];
    }
}

- (void)enableRequiredMonitoring
{
    @synchronized (self) {
        if (self.monitoringInstalled) {
            return;
        }
        self.monitoringInstalled = YES;

        [self installKSCrashWithMonitoring:KSCrashMonitorTypeRequired];
    }
}

- (void)installKSCrashWithMonitoring:(KSCrashMonitorType)monitoring
{
    if ([AMAPlatformDescription isDebuggerAttached]) {
        AMALogWarn(@"A debugger is attached. Most crashes will not be reported.");
        monitoring &= KSCrashMonitorTypeDebuggerSafe;
    }

    KSCrashConfiguration *config = [KSCrashConfiguration new];
    config.installPath = AMAKSCrash.crashesPath;
    config.enableMemoryIntrospection = NO; // hot fix on arm64
    config.enableQueueNameSearch = NO;
    config.enableSwapCxaThrow = NO;
    config.monitors = monitoring;
    g_crashErrorEnvironmentCallback = self.crashErrorEnvironmentCallback;
    if (self.crashErrorEnvironmentCallback != NULL) {
        config.isWritingReportCallback = AMAAppMetricaKSCrashIsWritingReportCallback;
    }

    NSError *installationError = nil;
    BOOL handlerInstalled = [[KSCrash sharedInstance] installWithConfiguration:config error:&installationError];

    if (handlerInstalled == NO) {
        AMALogError(@"Could not enable crash reporter. Error: %@", installationError.localizedDescription);
        if (installationError.localizedFailureReason) {
            AMALogError(@"Failure reason: %@", installationError.localizedFailureReason);
        }
    } 
    else {
        AMALogInfo(@"Crash reporter successfully installed with monitoring type: %lu", (unsigned long)monitoring);
    }
}

- (void)initializeKSCrashBinaryImageCache
{
    ksbic_init();
}

- (void)shutdown
{
    // do nothing.
}

- (void)loadCrashReports
{
    if (KSCrash.sharedInstance.crashedLastLaunch == NO && self.isUnhandledCrashDetectingEnabled) {
        AMALogInfo(@"No launch crashes detected. Trying to detect unhandled crashes");
        [self.unhandledCrashDetector checkUnhandledCrash:^(AMAUnhandledCrashType crashType) {
            [self.delegate crashLoader:self didDetectProbableUnhandledCrash:crashType];
        }];
    }

    NSArray *__block reportIDs = nil;
    NSString *transactionID = kAMALoadingCrashReportsTransactionKey;
    [self.transactor processTransactionWithID:transactionID name:@"ReportIDs" transaction:^{
        reportIDs = KSCrash.sharedInstance.reportStore.reportIDs;
    } rollback:^NSString *(id context){
        [[self class] purgeAllRawCrashReports];
        return nil;
    }];

    if (reportIDs.count > 0) {
        AMALogInfo(@"Found pending crash reports:\n\t%@", reportIDs);
        [self handleCrashReports:reportIDs];
    }
}
/// Temp implementation: Synchronously loads crash reports. Assumes single-threaded operation.
- (NSArray<AMADecodedCrash *> *)syncLoadCrashReports
{
    self.syncLoadedCrashes = [NSMutableArray array];

    [self loadCrashReports];

    NSArray *result = [self.syncLoadedCrashes copy];
    self.syncLoadedCrashes = nil;

    return result;
}

- (AMAKSCrashReportDecoder *)crashReportDecoderForReportWithID:(NSNumber *)reportID
{
    AMAKSCrashReportDecoder *decoder = self.decoders[reportID];
    if (decoder == nil) {
        decoder = [[AMAKSCrashReportDecoder alloc] initWithCrashID:reportID];
        decoder.delegate = self;
        self.decoders[reportID] = decoder;
    }

    return decoder;
}

- (BOOL)handleCrashReportWithID:(NSNumber *)reportID
{
    __block BOOL success = YES;
    AMAKSCrashReportDecoder *decoder = [self crashReportDecoderForReportWithID:reportID];

    if (decoder != nil) {
        __block KSCrashReportDictionary *crashReport = nil;

        AMACrashSafeTransactorRollbackBlock rollback = ^NSString *(id context) {
            [[self class] purgeRawCrashReport:reportID];
            success = NO;
            return nil;
        };

        NSString *transactionID = kAMALoadingCrashReportsTransactionKey;
        NSString *reportTransactionName = [NSString stringWithFormat:@"ReportWithID_%lld", reportID.longLongValue];
        [self.transactor processTransactionWithID:transactionID name:reportTransactionName transaction:^{
            crashReport = [KSCrash.sharedInstance.reportStore reportForID:reportID.longLongValue];
        } rollback:rollback];

        if (success) {
            NSString *DecodeTransactionName = [NSString stringWithFormat:@"DecodeReport_%lld", reportID.longLongValue];
            [self.transactor processTransactionWithID:transactionID
                                                 name:DecodeTransactionName
                                      rollbackContext:[reportID stringValue]
                                          transaction:^{
                [decoder decode:crashReport.value];
            } rollback:rollback];
        }
    }

    return success;
}

- (void)handleCrashReports:(NSArray *)reportIDs
{
    for (NSNumber *reportID in reportIDs) {
        [self handleCrashReportWithID:reportID];
    }
}

+ (void)purgeAllRawCrashReports
{
    [KSCrash.sharedInstance.reportStore deleteAllReports];
}

+ (void)purgeCrashesDirectory
{
    [AMAFileUtility deleteFileAtPath:[AMAKSCrash crashesPath]];
}

+ (void)addCrashContext:(NSDictionary *)crashContext
{
    if (crashContext.count == 0) {
        return;
    }

    @synchronized (self) {
        NSDictionary *existingContext = [self crashContext];
        NSDictionary *newContext = nil;

        if (existingContext != nil) {
            NSMutableDictionary *currentContext = [existingContext mutableCopy];
            [currentContext addEntriesFromDictionary:crashContext];
            newContext = [currentContext copy];
        } else {
            newContext = [crashContext copy];
        }

        KSCrash.sharedInstance.userInfo = newContext;
    }
}

+ (NSDictionary *)crashContext
{
    return KSCrash.sharedInstance.userInfo;
}

- (void)reportANR
{
    [[KSCrash sharedInstance] reportUserException:kAMAApplicationNotRespondingCrashType
                                           reason:@"The main thread was unresponsive for too long"
                                         language:@"ObjC"
                                       lineOfCode:nil
                                       stackTrace:nil
                                    logAllThreads:YES
                                 terminateProgram:NO];
    [self loadCrashReports];
}

#pragma mark - AMAKSCrashReportDecoderDelegate Implementation

- (void)crashReportDecoder:(AMAKSCrashReportDecoder *)decoder
            didDecodeCrash:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error
{
    if (error != nil) {
        AMALogError(@"Failed to decode report:%@ with error: %@", decoder.crashID, error);
    }

    if (decoder.crashID != nil) {
        [self.decoders removeObjectForKey:decoder.crashID];
    }

    if (self.syncLoadedCrashes != nil) {
        if (decodedCrash != nil && error == nil) {
            [self.syncLoadedCrashes addObject:decodedCrash];
        }
    }
    else {
        [self.delegate crashLoader:self didLoadCrash:decodedCrash withError:error];
    }

    [[self class] purgeRawCrashReport:decoder.crashID];
}

- (void)crashReportDecoder:(AMAKSCrashReportDecoder *)decoder
              didDecodeANR:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error
{
    if (error != nil) {
        AMALogInfo(@"Failed to decode ANR report:%@ with error: %@", decoder.crashID, error);
    }

    if (decoder.crashID != nil) {
        [self.decoders removeObjectForKey:decoder.crashID];
    }

    if (self.syncLoadedCrashes != nil) {
        if (decodedCrash != nil && error == nil) {
            [self.syncLoadedCrashes addObject:decodedCrash];
        }
    }
    else {
        [self.delegate crashLoader:self didLoadANR:decodedCrash withError:error];
    }

    [[self class] purgeRawCrashReport:decoder.crashID];
}

#pragma mark - AMACrashReportControllerDelegate Implementation

+ (void)purgeRawCrashReport:(NSNumber *)reportID
{
    AMALogInfo(@"Will purge report with ID: %@", reportID);
    [KSCrash.sharedInstance.reportStore deleteReportWithID:reportID.integerValue];

#ifdef DEBUG
    NSArray *reports = KSCrash.sharedInstance.reportStore.reportIDs;
    if ([reports containsObject:reportID] == NO) {
        AMALogAssert(@"FAILED TO REMOVE REPORT: %@", reportID);
    }
#endif
}

@end
