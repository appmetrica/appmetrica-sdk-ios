
#import "AMACrashMocks.h"

#import "AMACrash+Extended.h"

@implementation AMACrashMocks

+ (NSString *)testErrorName
{
    return @"TestError";
}

+ (NSDictionary *)testUserInfo
{
    return @{ @"key" : @"value" };
}

+ (NSException *)testException
{
    return [[NSException alloc] initWithName:@"Exception" reason:@"Reason" userInfo:[self testUserInfo]];
}

+ (NSString *)normalCrashID
{
    return @"B1BD9907-4290-4C17-A6CA-C57949A775FA1640447868";
}

+ (NSString *)legacyCrashID
{
    return @"B1BD9907-4290-4C17-A6CA-C57949A775FA1640447869";
}

+ (NSString *)normalCrashType
{
    return @"EXC_CRASH (SIGABRT)";
}

+ (NSDictionary *)normalCrashEnvironment
{
    return @{
        @"Test crash environment key" : @"Test crash environment value"
    };
}

+ (NSDictionary *)normalCrashAppEnvironment
{
    return @{
        @"Test app environment key" : @"Test app environment value"
    };
}

+ (NSString *)bigCrashID
{
    return @"B1BD9907-4290-4C17-A6CA-C57949A775FA1640447868-BIG";
}

+ (NSString *)abortKSCrashFileName
{
    return @"crash-abort";
}

+ (NSString *)abortWithoutSystemValuesKSCrashFileName
{
    return @"crash-abort-without-values";
}

+ (NSString *)testJSONValue
{
    NSData *JSON = [NSJSONSerialization dataWithJSONObject:[self testUserInfo]
                                                   options:0
                                                     error:nil];
    return [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
}

+ (NSTimeInterval)crashInterval
{
    return 100.0;
}

+ (NSDate *)normalCrashDate
{
    return [NSDate dateWithTimeIntervalSince1970:1405588754.0];
}


+ (AMACrash *)normalCrash
{
    return [self normalCrash:YES];
}

+ (AMACrash *)normalCrash:(BOOL)isFull
{
    return [AMACrash crashWithRawData:isFull ? [self loadCrashReport:[self normalCrashID]] : nil
                                 date:[self normalCrashDate]
                             appState:[self normalApplicationState]
                     errorEnvironment:[self normalCrashEnvironment]
                       appEnvironment:[self normalCrashAppEnvironment]];
}

+ (AMACrash *)legacyCrash
{
    return [self legacyCrash:YES];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (AMACrash *)legacyCrash:(BOOL)isFull
{

    return [AMACrash crashWithRawContent:isFull ? [self loadLegacyCrashReport:[self legacyCrashID]] : nil
                                    date:[self normalCrashDate]
                        errorEnvironment:[self normalCrashEnvironment]
                          appEnvironment:[self normalCrashAppEnvironment]];
}
#pragma clang diagnostic pop

+ (AMACrash *)notStampedCrash
{
    return [AMACrash crashWithRawData:[self loadCrashReport:[self normalCrashID]]
                                 date:nil
                             appState:[self normalApplicationState]
                     errorEnvironment:[self normalCrashEnvironment]
                       appEnvironment:[self normalCrashAppEnvironment]];
}

+ (AMACrash *)crashWithoutAppState
{
    return [AMACrash crashWithRawData:[self loadCrashReport:[self normalCrashID]]
                                 date:[self normalCrashDate]
                             appState:nil
                     errorEnvironment:[self normalCrashEnvironment]
                       appEnvironment:[self normalCrashAppEnvironment]];
}

+ (AMACrash *)previousAppVersionCrash
{
    return [AMACrash crashWithRawData:[self loadCrashReport:[self normalCrashID]]
                                 date:[self normalCrashDate]
                             appState:[self previousAppVersionState]
                     errorEnvironment:[self normalCrashEnvironment]
                       appEnvironment:[self normalCrashAppEnvironment]];
}

+ (AMACrash *)crashWithoutRawData
{
    return [AMACrash crashWithRawData:nil
                                 date:[self normalCrashDate]
                             appState:[self normalApplicationState]
                     errorEnvironment:[self normalCrashEnvironment]
                       appEnvironment:[self normalCrashAppEnvironment]];
}

- (void)initReporterAndSendNormalCrashWith:(BOOL)isFullReport
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] normalCrash:isFullReport] onFailure:nil];
}

- (void)initReporterAndSendLegacyCrash:(BOOL)isFullReport
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] legacyCrash:isFullReport] onFailure:nil];
}

- (AMASession *)createPreviousSessionWithCrashDate:(NSDate *)crashDate
                                 endCurrentSession:(BOOL)endCurrentSession
                                        crashBlock:(dispatch_block_t)crashBlock
{
    NSTimeInterval sessionTimeout = 10;
    NSTimeInterval sessionCreationDelta = sessionTimeout * 0.5;

    AMAReporter *reporter = [self appReporter];
    NSDate *previousSessionCreationDate = [[[self class] normalCrashDate] dateByAddingTimeInterval:-sessionCreationDelta];
    AMASession *previousSession =
        [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:previousSessionCreationDate
                                                                      error:nil];
    NSDate *finishDate = [previousSession.startDate.deviceDate dateByAddingTimeInterval:[[self class] crashInterval]];
    [reporter.reporterStorage.sessionStorage finishSession:previousSession atDate:finishDate error:nil];
    AMASession *newSession = [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:crashDate error:nil];
    if (endCurrentSession) {
        [reporter.reporterStorage.sessionStorage finishSession:newSession atDate:crashDate error:nil];
    }
    [NSDate stub:@selector(date) andReturn:crashDate];
    crashBlock();
    [NSDate clearStubs];
    return previousSession;
}

- (AMASession *)createPreviousSessionAndSendCrash
{
    return [self createPreviousSessionAndSendCrashWithCrashDate:[NSDate date]];
}

- (AMASession *)createPreviousSessionAndSendCrashWithCrashDate:(NSDate *)crashDate
{
    return [self createPreviousSessionWithCrashDate:crashDate endCurrentSession:NO crashBlock:^{
        AMAReporter *reporter = [self appReporter];
        [reporter reportCrash:[[self class] normalCrash] onFailure:nil];
    }];
}

- (AMASession *)createPreviousSessionAndSendNonStampedCrashWithCrashDate:(NSDate *)crashDate
{
    return [self createPreviousSessionWithCrashDate:crashDate endCurrentSession:NO crashBlock:^{
        AMAReporter *reporter = [self appReporter];
        [reporter reportCrash:[[self class] notStampedCrash] onFailure:nil];
    }];
}

- (void)createPreviousSessionSetupReporterAndSendCrash
{
    [self createPreviousSessionWithCrashDate:[[self class] normalCrashDate] endCurrentSession:YES crashBlock:^{
        AMAReporter *reporter = [self appReporterForApiKey:[[self class] defaultApiKey]];
        [reporter reportCrash:[[self class] normalCrash] onFailure:nil];
    }];
}

- (void)createBackgroundSessionWithEventStartedAt:(NSDate *)date
{
    // Because of https://nda.ya.ru/t/1sBu32F56fHZtc
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

- (void)restartApplicationAndSendCrash
{
    [self restartApplication];
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] normalCrash] onFailure:nil];
}

- (void)restartApplicationAndSendNotStampedCrash
{
    [self restartApplication];
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] notStampedCrash] onFailure:nil];
}

#pragma mark - Errors

- (void)initReporterAndSendError:(NSException *)exception
{
    AMAReporter *reporter = [self appReporter];
    [reporter resumeSession];
    [self reporter:reporter reportException:exception];
}

- (void)reporter:(AMAReporter *)reporter reportException:(NSException *)exception
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [reporter reportError:[[self class] testErrorName] exception:exception onFailure:nil];
#pragma clang diagnostic pop
}

- (void)initReporterAndSendErrorWithoutStartingSession:(NSException *)exception
{
    AMAReporter *reporter = [self appReporter];
    [self reporter:reporter reportException:exception];
}

- (void)initReporterAndSendNormalCrashWith:(BOOL)isFullReport
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] normalCrash:isFullReport] onFailure:nil];
}

- (void)initReporterAndSendLegacyCrash:(BOOL)isFullReport
{
    AMAReporter *reporter = [self appReporter];
    [reporter reportCrash:[[self class] legacyCrash:isFullReport] onFailure:nil];
}

- (AMASession *)createPreviousSessionWithCrashDate:(NSDate *)crashDate
                                 endCurrentSession:(BOOL)endCurrentSession
                                        crashBlock:(dispatch_block_t)crashBlock
{
    NSTimeInterval sessionTimeout = 10;
    NSTimeInterval sessionCreationDelta = sessionTimeout * 0.5;

    AMAReporter *reporter = [self appReporter];
    NSDate *previousSessionCreationDate = [[[self class] normalCrashDate] dateByAddingTimeInterval:-sessionCreationDelta];
    AMASession *previousSession =
        [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:previousSessionCreationDate
                                                                      error:nil];
    NSDate *finishDate = [previousSession.startDate.deviceDate dateByAddingTimeInterval:[[self class] crashInterval]];
    [reporter.reporterStorage.sessionStorage finishSession:previousSession atDate:finishDate error:nil];
    AMASession *newSession = [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:crashDate error:nil];
    if (endCurrentSession) {
        [reporter.reporterStorage.sessionStorage finishSession:newSession atDate:crashDate error:nil];
    }
    [NSDate stub:@selector(date) andReturn:crashDate];
    crashBlock();
    [NSDate clearStubs];
    return previousSession;
}

- (AMASession *)createPreviousSessionAndSendCrash
{
    return [self createPreviousSessionAndSendCrashWithCrashDate:[NSDate date]];
}

- (AMASession *)createPreviousSessionAndSendCrashWithCrashDate:(NSDate *)crashDate
{
    return [self createPreviousSessionWithCrashDate:crashDate endCurrentSession:NO crashBlock:^{
        AMAReporter *reporter = [self appReporter];
        [reporter reportCrash:[[self class] normalCrash] onFailure:nil];
    }];
}

- (AMASession *)createPreviousSessionAndSendNonStampedCrashWithCrashDate:(NSDate *)crashDate
{
    return [self createPreviousSessionWithCrashDate:crashDate endCurrentSession:NO crashBlock:^{
        AMAReporter *reporter = [self appReporter];
        [reporter reportCrash:[[self class] notStampedCrash] onFailure:nil];
    }];
}

- (void)createPreviousSessionSetupReporterAndSendCrash
{
    [self createPreviousSessionWithCrashDate:[[self class] normalCrashDate] endCurrentSession:YES crashBlock:^{
        AMAReporter *reporter = [self appReporterForApiKey:[[self class] defaultApiKey]];
        [reporter reportCrash:[[self class] normalCrash] onFailure:nil];
    }];
}

+ (NSData *)loadCrashReport:(NSString *)crashID
{
    NSError *__autoreleasing error = nil;
    return [NSData dataWithContentsOfFile:[self bundleCrashPath:crashID]
                                  options:NSDataReadingMappedIfSafe
                                    error:&error];
}

+ (NSString *)loadLegacyCrashReport:(NSString *)crashID
{
    NSError *__autoreleasing error = nil;
    return [NSString stringWithContentsOfFile:[self bundleCrashPath:crashID]
                                     encoding:NSUTF8StringEncoding
                                        error:&error];
}

+ (NSString *)bundleCrashPath:(NSString *)crashID
{
    return [AMAModuleBundleProvider.moduleBundle pathForResource:crashID ofType:@"crash"];
}

+ (NSString *)bundleInfoPath:(NSString *)crashID
{
    return [AMAModuleBundleProvider.moduleBundle pathForResource:crashID ofType:@"plist"];
}

+ (NSString *)ksCrashPath:(NSString *)fileName
{
    return [AMAModuleBundleProvider.moduleBundle pathForResource:fileName ofType:@"json"];
}

+ (AMACrash *)bigCrash
{
    NSMutableData *bigCrashReport =
        [[AMAReporterTestHelper loadCrashReport:[AMAReporterTestHelper bigCrashID]] mutableCopy];
    for (NSUInteger index = 0; index < 200000; ++index) { // append 600000 random digits
        [bigCrashReport appendData:[[@(arc4random() % 1000) stringValue] dataUsingEncoding:NSASCIIStringEncoding]];
    }
    return [[AMACrash alloc] initWithRawData:bigCrashReport date:[NSDate date] errorEnvironment:nil];
}

@end
