
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAReporterTestHelper.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAMockDatabase.h"
#import "AMADatabaseFactory.h"
#import "AMAEnvironmentContainer.h"
#import "AMAEventBuilder.h"
#import "AMAEventsCleaner.h"
#import "AMAInternalEventsReporter.h"
#import "AMAEvent.h"
#import "AMASession.h"
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMADate.h"
#import "AMAReporterProviding.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAMetricaConfiguration.h"
#import "AMAECommerceSerializer.h"
#import "AMAECommerceTruncator.h"
#import "AMAAdServicesDataProvider.h"
#import "AMASessionExpirationHandler.h"
#import "AMAAdProvider.h"
#import "AMAPrivacyTimer.h"
#import "AMAPrivacyTimerRetryPolicy.h"
#import "AMAExternalAttributionSerializer.h"
#import "AMAPrivacyTimerStorageMock.h"
#import "AMAPrivacyTimerMock.h"
#import "AMAReporter+TestUtilities.h"
#import "AMAAdRevenueSourceContainerMock.h"

@interface AMAReporterTestHelper ()

@property (nonatomic, strong, readonly) AMAReporterStoragesContainer *storagesContainer;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAReporter *> *reporters;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSObject<AMADatabaseProtocol> *> *databases;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAReporterStorage *> *reporterStorages;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAPrivacyTimer *> *privacyTimers;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAPrivacyTimerStorageMock *> *privacyTimerStorages;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAAdProvider *> *adProviders;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, AMAAdRevenueSourceContainerMock *> *adRevenueSourceStorage;

@end

@implementation AMAReporterTestHelper

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _storagesContainer = [[AMAReporterStoragesContainer alloc] init];
        _reporters = [NSMutableDictionary dictionary];
        _databases = [NSMutableDictionary dictionary];
        _reporterStorages = [NSMutableDictionary dictionary];
        _adProviders = [NSMutableDictionary dictionary];
        _privacyTimerStorages = [NSMutableDictionary dictionary];
        _privacyTimers = [NSMutableDictionary dictionary];
        _adRevenueSourceStorage = [NSMutableDictionary dictionary];
        
        __weak __typeof(self) weakSelf = self;
        [_storagesContainer stub:@selector(storageForApiKey:) withBlock:^id(NSArray *params) {
            return [weakSelf reporterStorageForApiKey:params[0] inMemory:YES main:NO];
        }];
        [_storagesContainer stub:@selector(mainStorageForApiKey:) withBlock:^id(NSArray *params) {
            return [weakSelf reporterStorageForApiKey:params[0] inMemory:YES main:YES];
        }];
        [AMAReporterStoragesContainer stub:@selector(sharedInstance) andReturn:_storagesContainer];
    }
    return self;
}

+ (NSString *)defaultApiKey
{
    return @"550e8400-e29b-41d4-a716-446655440000";
}

+ (NSString *)octopusApiKey
{
    return @"76a08b94-51d7-4d3a-95f7-284247a139b0";
}

+ (NSTimeInterval)acceptableEventDeltaOffset
{
    return 0.2;
}

+ (NSDictionary *)testUserInfo
{
    return @{ @"key" : @"value" };
}

+ (NSString *)testEventName
{
    return @"TestEvent";
}

+ (AMAApplicationState *)normalApplicationState
{
    return AMAApplicationStateManager.applicationState;
}

+ (AMAApplicationState *)previousAppVersionState
{
    return [[self normalApplicationState] copyWithNewAppVersion:@"9.9.9" appBuildNumber:@"999"];
}

+ (AMAApplicationState *)randomApplicationState
{
    return [[AMAApplicationState alloc] initWithAppVersionName:@"9.7.3.0"
                                                 appDebuggable:NO
                                                    kitVersion:@"9.8.1"
                                                kitVersionName:@"4.2.0"
                                                kitBuildNumber:182
                                                  kitBuildType:@"Release"
                                                     OSVersion:@"17.4.2"
                                                    OSAPILevel:33
                                                        locale:@"es-MX"
                                                      isRooted:YES
                                                          UUID:@"DEADBEEF-1234-5678-90AB-CDEF12345678"
                                                      deviceID:@"abc123xyz"
                                                           IFV:@"A1B2C3D4-E5F6-7890-1234-56789ABCDEF0"
                                                           IFA:@"00000000-0000-0000-0000-000000000000"
                                                           LAT:YES
                                                appBuildNumber:@"730"];
}

+ (NSString *)testJSONValue
{
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:[self testUserInfo]
                                                   options:0
                                                     error:nil];
    return [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
}

- (AMAReporter *)appReporter
{
    return [self appReporterForApiKey:[[self class] defaultApiKey] main:YES async:NO];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
{
    return [self appReporterForApiKey:apiKey main:NO async:NO];
}

- (AMAReporter *)mainAppReporterForApiKey:(NSString *)apiKey
{
    return [self appReporterForApiKey:apiKey main:YES async:NO];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor
{
    id executor = [KWMock nullMockForProtocol:@protocol(AMACancelableExecuting)];
    [executor stub:@selector(execute:) withBlock:^id (NSArray *params) {
        void (^block)(void) = params[0];
        block();
        return nil;
    }];
    return [self appReporterForApiKey:apiKey
                                 main:YES
                             executor:executor
                             inMemory:YES
                          preloadInfo:nil
             attributionCheckExecutor:attributionCheckExecutor];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey main:(BOOL)main async:(BOOL)isAsync
{
    return [self appReporterForApiKey:apiKey main:main async:isAsync inMemory:YES];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey main:(BOOL)main async:(BOOL)isAsync inMemory:(BOOL)inMemory
{
    return [self appReporterForApiKey:apiKey main:main async:isAsync inMemory:inMemory preloadInfo:nil];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                                async:(BOOL)isAsync
                             inMemory:(BOOL)inMemory
                          preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
{
    id<AMACancelableExecuting, AMASyncExecuting> executor = isAsync ? nil : [AMATestDelayedManualExecutor new];
    return [self appReporterForApiKey:apiKey main:main executor:executor inMemory:inMemory preloadInfo:preloadInfo attributionCheckExecutor:nil];
}

- (AMAReporter *)appReporterForApiKey:(NSString *)apiKey
                                 main:(BOOL)main
                             executor:(id<AMACancelableExecuting, AMASyncExecuting>)executor
                             inMemory:(BOOL)inMemory
                          preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
             attributionCheckExecutor:(id<AMAAsyncExecuting>)attributionCheckExecutor
{
    if (self.reporters[apiKey] != nil) {
        return self.reporters[apiKey];
    }

    AMAReporterStorage *reporterStorage = [self reporterStorageForApiKey:apiKey inMemory:inMemory main:main];
    AMAEventBuilder *builder =
        [[AMAEventBuilder alloc] initWithStateStorage:reporterStorage.stateStorage preloadInfo:preloadInfo];
    AMASessionExpirationHandler *expirationHandler =
        [[AMASessionExpirationHandler alloc] initWithConfiguration:[AMAMetricaConfiguration sharedInstance]
                                                            APIKey:apiKey];
    
    AMAAdProvider *adProvider = [self adProviderForApiKey:apiKey];
    AMAPrivacyTimerStorageMock *privacyStorage = [self privacyTimerStorageMockForApiKey:apiKey];
    AMAPrivacyTimerMock *privacyTimer = [[AMAPrivacyTimerMock alloc] initWithTimerRetryPolicy:privacyStorage
                                                                         delegateExecutor:executor
                                                                               adProvider:adProvider];
    
    privacyTimer.disableFire = YES;
    
    AMAAdRevenueSourceContainerMock *adRevenueSourceContainerMock = [self adRevenueSourceStorageForApiKey:apiKey];
    
    _privacyTimers[apiKey] = privacyTimer;
    AMAReporter *reporter = nil;
    if (executor == nil) {
        reporter = [[AMAReporter alloc] initWithApiKey:apiKey
                                                  main:main
                                       reporterStorage:reporterStorage
                                          eventBuilder:builder
                                      internalReporter:[AMAInternalEventsReporter nullMock]
                              attributionCheckExecutor:attributionCheckExecutor
                                          privacyTimer:privacyTimer
                                adRevenueSourceStorage:adRevenueSourceContainerMock];
    }
    else {
        
        reporter = [[AMAReporter alloc] initWithApiKey:apiKey
                                                  main:main
                                       reporterStorage:reporterStorage
                                          eventBuilder:builder
                                      internalReporter:[AMAInternalEventsReporter nullMock]
                                              executor:executor
                              attributionCheckExecutor:attributionCheckExecutor
                                   eCommerceSerializer:[[AMAECommerceSerializer alloc] init]
                                    eCommerceTruncator:[[AMAECommerceTruncator alloc] init]
                                            adServices:[AMAAdServicesDataProvider nullMock]
                         externalAttributionSerializer:[AMAExternalAttributionSerializer nullMock]
                              sessionExpirationHandler:expirationHandler
                                            adProvider:adProvider
                                          privacyTimer:privacyTimer
                                adRevenueSourceStorage:adRevenueSourceContainerMock];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [reporter stub:@selector(evenInitAdditionalParams)]; //TODO: (glinnik) Fix this after moving the reporting
#pragma clang diagnostic pop
    
    self.reporters[apiKey] = reporter;
    [reporterStorage restoreState];
    return reporter;
}

- (AMAPrivacyTimerStorageMock *)privacyTimerStorageMockForApiKey:(NSString *)apiKey 
{
    AMAPrivacyTimerStorageMock *storage = self.privacyTimerStorages[apiKey];
    if (storage != nil)
    {
        return storage;
    }
    
    storage = [[AMAPrivacyTimerStorageMock alloc] init];
    _privacyTimerStorages[apiKey] = storage;
    return storage;
}

- (AMAPrivacyTimer *)privacyTimerForApiKey:(NSString *)apiKey 
{
    return self.privacyTimers[apiKey];
}

- (AMAReporterStorage *)reporterStorageForApiKey:(NSString *)apiKey inMemory:(BOOL)inMemory main:(BOOL)main
{
    if (self.reporterStorages[apiKey] != nil) {
        return self.reporterStorages[apiKey];
    }

    AMAEnvironmentContainer *eventEnvironment = [[AMAEnvironmentContainer alloc] init];
    id<AMAReporterProviding> reporterProvider = [KWMock nullMockForProtocol:@protocol(AMAReporterProviding)];
    AMAEventsCleaner *eventsCleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:reporterProvider];

    NSObject<AMADatabaseProtocol> *database = nil;
    if (inMemory) {
        database = [AMAMockDatabase reporterDatabase];
    }
    else {
        NSString *tempDirectory = [NSFileManager defaultManager].temporaryDirectory.path;
        NSString *persistentDirectory = [tempDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        [[NSFileManager defaultManager] createDirectoryAtPath:persistentDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        [AMAFileUtility stub:@selector(persistentPathForApiKey:) andReturn:persistentDirectory];
        database = (NSObject<AMADatabaseProtocol> *)[AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:main
                                                                                    eventsCleaner:eventsCleaner];
        [AMAFileUtility clearStubs];
    }
    AMAReporterStorage *reporterStorage = [[AMAReporterStorage alloc] initWithApiKey:apiKey
                                                                    eventEnvironment:eventEnvironment
                                                                       eventsCleaner:eventsCleaner
                                                                            database:database
                                                                                main:main];
    
    self.reporterStorages[apiKey] = reporterStorage;
    self.databases[apiKey] = database;
    [[AMAMetricaConfiguration sharedInstance] stub:@selector(ensureMigrated)];
    return reporterStorage;
}

- (AMAAdProvider *)adProviderForApiKey:(NSString*)apiKey
{
    AMAAdProvider *provider = self.adProviders[apiKey];
    if (provider != nil) {
        return provider;
    }
    provider = [AMAAdProvider nullMock];
    _adProviders[apiKey] = provider;
    return provider;
}

- (NSObject<AMADatabaseProtocol> *)databaseForApiKey:(NSString *)apiKey
{
    return self.databases[apiKey];
}

- (AMAAdRevenueSourceContainerMock *)adRevenueSourceStorageForApiKey:(NSString*)apiKey
{
    AMAAdRevenueSourceContainerMock *storage = self.adRevenueSourceStorage[apiKey];
    if (storage != nil) {
        return storage;
    }
    
    storage = [AMAAdRevenueSourceContainerMock new];
    self.adRevenueSourceStorage[apiKey] = storage;
    return storage;
}

#pragma mark - Events

- (void)initReporterAndSendEventWithParameters:(NSDictionary *)parameters
                                     forApiKey:(NSString *)apiKey
                                         async:(BOOL)isAsync
{
    AMAReporter *reporter = [self appReporterForApiKey:apiKey main:NO async:isAsync];
    [reporter resumeSession];
    [reporter reportEvent:[[self class] testEventName] parameters:parameters onFailure:nil];
}

- (void)initReporterAndSendEventWithParameters:(NSDictionary *)parameters
{
    [self initReporterAndSendEventWithParameters:parameters async:NO];
}

- (void)initReporterAndSendEventWithParameters:(NSDictionary *)parameters async:(BOOL)isAsync
{
    [self initReporterAndSendEventWithParameters:parameters forApiKey:[[self class] defaultApiKey] async:isAsync];
}

- (void)initReporterAndSendEventWithoutStartingSessionWithParameters:(NSDictionary *)parameters
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportEvent:[[self class] testEventName] parameters:parameters onFailure:nil];
}

- (void)initReporterAndSendEventToExpiredSessionWithParameters:(NSDictionary *)parameters
{
    [self initReporterAndSendEventToExpiredSessionWithParameters:parameters async:NO];
}

- (void)initReporterAndSendEventToExpiredSessionWithParameters:(NSDictionary *)parameters async:(BOOL)isAsync
{
    AMAReporter *reporter = [self appReporterForApiKey:[[self class] defaultApiKey] main:NO async:isAsync];
    [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate distantPast] error:nil];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter reportEvent:[[self class] testEventName] parameters:parameters onFailure:nil];
}

- (void)initReporterAndSendEventToSessionWithDate:(NSDate *)date
{
    AMAReporter *reporter = [self appReporter];
    [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:date error:nil];
    [reporter resumeSession];
    [reporter reportEvent:[[self class] testEventName] parameters:nil onFailure:nil];
}

- (void)initReporterTwice
{
    AMAReporter *reporter = [self appReporter];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];
}

- (void)initReporterAndCreateThreeSessionsWithDifferentAppStates
{
    AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
    [helper stubApplicationState];
    AMAReporter *reporter = [self appReporter];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];

    helper.OSVersion = @"4.3";
    [helper stubApplicationState];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];

    helper.OSVersion = @"5.0";
    [helper stubApplicationState];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];
}

- (void)sendEvent
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportEvent:[[self class] testEventName] onFailure:nil];
}

- (void)restartApplication
{
    AMAReporter *reporter = [self appReporter];
    [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
    [reporter start];
}

- (void)createBackgroundSessionWithEventStartedAt:(NSDate *)date
{
    // TODO: Because of https://nda.ya.ru/t/1sBu32F56fHZtc
    NSDate *eventDateWithTreshold = [date dateByAddingTimeInterval:0.001];

    [self createBackgroundSessionWithDate:date];
    AMAReporter *reporter = [self appReporter];
    [NSDate stub:@selector(date) andReturn:eventDateWithTreshold];
    [reporter reportEvent:[[self class] testEventName] onFailure:nil];
    [NSDate clearStubs];
}

- (void)createAndFinishBackgroundSessionWithEventStartedAt:(NSDate *)date
{
    [self createBackgroundSessionWithDate:date];
    AMASessionStorage *sessionStorage = [self appReporter].reporterStorage.sessionStorage;
    AMASession *session = [sessionStorage lastSessionWithError:nil];
    [sessionStorage finishSession:session atDate:date error:nil];
    // TODO(bamx23): EVENT_ALIVE is needed
}

#pragma mark - Sessions

- (void)createForegroundSessionWithDate:(NSDate *)date
{
    [[self appReporter].reporterStorage.sessionStorage newGeneralSessionCreatedAt:date error:nil];
}

- (void)createBackgroundSessionWithDate:(NSDate *)date
{
    [[self appReporter].reporterStorage.sessionStorage newBackgroundSessionCreatedAt:date error:nil];
}

- (void)createBackgroundAndStartForegroundSessionWithDate:(NSDate *)date
{
    AMAReporter *reporter = [self appReporter];
    [reporter.reporterStorage.sessionStorage newBackgroundSessionCreatedAt:date error:nil];
    [reporter resumeSession];
}

- (void)createAndFinishSessionInBackgroundWithDate:(NSDate *)date
{
    AMAReporter *reporter = [self appReporter];
    [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:date error:nil];
    [self finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
}

- (void)createAndFinishSessionInForegroundWithDate:(NSDate *)date
{
    AMAReporter *reporter = [self appReporter];
    [reporter start];
    [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:date error:nil];
    [self finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
}

- (void)finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:(AMAReporter *)reporter
{
    NSDate *now = [NSDate date];
    [NSDate stub:@selector(date) andReturn:[NSDate distantFuture]];
    [reporter resumeSession];
    [NSDate clearStubs];
}

+ (void)stubTimeFromNowSec:(NSTimeInterval)fromNowSecs
{
    NSDate *date = [[NSDate date] dateByAddingTimeInterval:fromNowSecs];
    [NSDate stub:@selector(date) andReturn:date];
}

+ (void)cycleReporterWithStubbedDateFromNow:(AMAReporter *)reporter interval:(NSTimeInterval)sinceNow
{
    [self stubTimeFromNowSec:sinceNow];
    [reporter start];
    [reporter shutdown];
}

+ (void)reportDelayedEvent:(AMAReporter *)reporter delay:(NSTimeInterval)delaySec
{
    [self stubTimeFromNowSec:delaySec];
    [reporter reportEvent:@"test" onFailure:nil];
}


@end
