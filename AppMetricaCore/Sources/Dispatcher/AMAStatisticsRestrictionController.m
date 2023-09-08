
#import "AMACore.h"
#import "AMAStatisticsRestrictionController.h"
#import "AMAMetricaInMemoryConfiguration.h"

typedef BOOL(^kAMARestrictionMatchBlock)(NSString *apiKey, AMAStatisticsRestriction restriction);

@interface AMAStatisticsRestrictionController ()

@property (nonatomic, copy) NSString *mainApiKey;
@property (nonatomic, assign) AMAStatisticsRestriction mainRestriction;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *reporterRestrictions;

@end

@implementation AMAStatisticsRestrictionController

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _mainRestriction = AMAStatisticsRestrictionNotActivated;
        _reporterRestrictions = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public -

+ (instancetype)sharedInstance
{
    static AMAStatisticsRestrictionController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AMAStatisticsRestrictionController alloc] init];
    });
    return instance;
}

- (void)setMainApiKeyRestriction:(AMAStatisticsRestriction)restriction
{
    @synchronized (self) {
        if ([self shouldUpdateRestriction:self.mainRestriction withNewRestriction:restriction]) {
            AMALogInfo(@"Set statistic restriction to '%lu' for main apiKey",
                       (unsigned long)restriction);
            self.mainRestriction = restriction;
        }
    }
}

- (BOOL)shouldEnableLocationSending
{
    BOOL shouldEnable = [self shouldEnableGenericRequestsSending];
    [self logResult:shouldEnable forAction:@"enable location sending"];
    return shouldEnable;
}

- (BOOL)shouldReportToApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return NO;
    }
    @synchronized (self) {
        BOOL shouldReport = YES;
        AMAStatisticsRestriction apiKeyRestriction =
            (AMAStatisticsRestriction)[self.reporterRestrictions[apiKey] unsignedIntegerValue];

        if (self.mainRestriction == AMAStatisticsRestrictionForbidden) {
            shouldReport = NO;
        }
        else {
            shouldReport = shouldReport && apiKeyRestriction != AMAStatisticsRestrictionForbidden;
            shouldReport = shouldReport && [self anyIsActivated];

            if (shouldReport && [apiKey isEqualToString:kAMAMetricaLibraryApiKey]) {
                shouldReport = [self anyOtherIsAllowedOrUndefinedForApiKey:kAMAMetricaLibraryApiKey];
            }
        }
        [self logResult:shouldReport forAction:@"report"];
        return shouldReport;
    }
}

- (AMAStatisticsRestriction)restrictionForApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return AMAStatisticsRestrictionNotActivated;
    }
    @synchronized (self) {
        return [apiKey isEqualToString:self.mainApiKey]
            ? self.mainRestriction
            : (AMAStatisticsRestriction)[self.reporterRestrictions[apiKey] unsignedIntegerValue];
    }
}

- (void)setReporterRestriction:(AMAStatisticsRestriction)restriction forApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return;
    }
    @synchronized (self) {
        BOOL shouldUpdate = [self shouldUpdateRestriction:[self.reporterRestrictions[apiKey] unsignedIntegerValue]
                                       withNewRestriction:restriction];
        if (shouldUpdate) {
            AMALogInfo(@"Set statistic restriction to '%lu' for apiKey %@",
                       (unsigned long)restriction, apiKey);
            self.reporterRestrictions[apiKey] = @(restriction);
        }
    }
}

#pragma mark - Private -

- (BOOL)shouldUpdateRestriction:(AMAStatisticsRestriction)restriction
             withNewRestriction:(AMAStatisticsRestriction)newRestriction
{
    return restriction == AMAStatisticsRestrictionNotActivated
            || newRestriction != AMAStatisticsRestrictionUndefined;
}


- (BOOL)allRestrictionsMatch:(kAMARestrictionMatchBlock)matcher
{
    BOOL __block result = matcher(nil, self.mainRestriction);
    if (result) {
        [self.reporterRestrictions enumerateKeysAndObjectsUsingBlock:^(NSString *apiKey, NSNumber *flag, BOOL *stop) {
            AMAStatisticsRestriction restriction = (AMAStatisticsRestriction)[flag unsignedIntegerValue];
            if (matcher(apiKey, restriction) == NO) {
                result = NO;
                *stop = YES;
            }
        }];
    }
    return result;
}

- (BOOL)anyOtherIsAllowedOrUndefinedForApiKey:(NSString *)apiKey
{
    BOOL invertedStatement =
        [self allRestrictionsMatch:^BOOL(NSString *restrictionApiKey, AMAStatisticsRestriction restriction) {
            if ([restrictionApiKey isEqualToString:apiKey]) {
                return YES;
            }
            return restriction != AMAStatisticsRestrictionAllowed
                && restriction != AMAStatisticsRestrictionUndefined;
        }];
    return invertedStatement == NO;
}

- (BOOL)anyIsActivated
{
    BOOL invertedStatement = [self allRestrictionsMatch:^BOOL(NSString *apiKey, AMAStatisticsRestriction restriction) {
        return restriction == AMAStatisticsRestrictionNotActivated;
    }];
    return invertedStatement == NO;
}

- (BOOL)allAreNotForbidden
{
    return [self allRestrictionsMatch:^BOOL(NSString *apiKey, AMAStatisticsRestriction restriction) {
        return restriction != AMAStatisticsRestrictionForbidden;
    }];
}

- (void)logResult:(BOOL)result forAction:(NSString *)action
{
    AMALogInfo(@"Should %@: %@ (main: %lu, reporters: %@)",
               action, result ? @"YES": @"NO", (unsigned long)self.mainRestriction, self.reporterRestrictions);
}

- (BOOL)shouldEnableGenericRequestsSending
{
    @synchronized (self) {
        BOOL __block shouldEnable = YES;
        if (self.mainRestriction != AMAStatisticsRestrictionNotActivated) {
            shouldEnable = shouldEnable && self.mainRestriction != AMAStatisticsRestrictionForbidden;
        }
        else {
            shouldEnable = shouldEnable && [self allAreNotForbidden];
            shouldEnable = shouldEnable && [self anyIsActivated];
        }
        return shouldEnable;
    }
}

@end
