#import "AMASearchAdsReporter.h"

#import "AMAAppMetrica+Internal.h"
#import "AMAInternalEventsReporter.h"
#import "AMAReporter.h"

static NSString *const kAMASearchAdsReporterCallbackTypeSuccess = @"success";
static NSString *const kAMASearchAdsReporterCallbackTypeUnknown = @"unknown";
static NSString *const kAMASearchAdsReporterCallbackTypeTryLater = @"try-later";
static NSString *const kAMASearchAdsReporterCallbackTypeAdTrackingLimited = @"lat";
static NSString *const kAMASearchAdsReporterCallbackTypeJSONError = @"json-error";

@interface AMASearchAdsReporter ()

@property (nonatomic, copy, readonly) NSString *apiKey;

@end

@implementation AMASearchAdsReporter

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    if (apiKey.length == 0) {
        return nil;
    }
    
    self = [super init];
    if (self != nil) {
        _apiKey = [apiKey copy];
    }
    return self;
}

#pragma mark - Public -

- (void)reportAttributionAttempt
{
    [[self internalEventsReporter] reportSearchAdsAttempt];
}

- (void)reportAttributionSuccessWithInfo:(NSDictionary *)info
{
    NSError *error = nil;
    [self reportReferrerSuccessEventWithAttributionInfo:info error:&error];

    if (error == nil) {
        [[self internalEventsReporter] reportSearchAdsCompletionWithType:kAMASearchAdsReporterCallbackTypeSuccess
                                                              parameters:nil];
    }
    else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"data"] = [info description];
        parameters[@"domain"] = error.domain;
        parameters[@"code"] = @(error.code);
        [[self internalEventsReporter] reportSearchAdsCompletionWithType:kAMASearchAdsReporterCallbackTypeJSONError
                                                              parameters:[parameters copy]];
    }
}

- (void)reportAttributionErrorWithCode:(AMASearchAdsRequesterErrorCode)errorCode description:(NSString *)description
{
    NSString *errorCodeKey = [self errorCodeKey:errorCode];
    NSDictionary *parameters = nil;
    if (description.length > 0) {
        parameters = @{ @"description": description };
    }

    if (errorCode == AMASearchAdsRequesterErrorAdTrackingLimited) {
        [self reportReferrerFailureEventWithErrorName:errorCodeKey];
    }
    [[self internalEventsReporter] reportSearchAdsCompletionWithType:errorCodeKey parameters:parameters];
}

#pragma mark - Private -

- (AMAReporter *)appReporter
{
    return (AMAReporter *)[AMAAppMetrica reporterForAPIKey:self.apiKey];
}

- (AMAInternalEventsReporter *)internalEventsReporter
{
    return [AMAAppMetrica sharedInternalEventsReporter];
}

- (void)reportReferrerEventForStatus:(NSString *)status
                           errorName:(NSString *)errorName
                     attributionInfo:(NSDictionary *)attributionInfo
                               error:(NSError **)error
{
    NSMutableDictionary *valueDictionary = [NSMutableDictionary dictionary];
    valueDictionary[@"status"] = status;
    valueDictionary[@"error"] = errorName;
    valueDictionary[@"data"] = attributionInfo;

    NSString *value = [AMAJSONSerialization stringWithJSONObject:[valueDictionary copy] error:error];
    if (value.length > 0) {
        [[self appReporter] reportReferrerEventWithValue:value onFailure:nil];
    }
}

- (void)reportReferrerSuccessEventWithAttributionInfo:(NSDictionary *)attributionInfo error:(NSError **)error
{
    [self reportReferrerEventForStatus:@"success"
                             errorName:nil
                       attributionInfo:attributionInfo
                                 error:error];
}

- (void)reportReferrerFailureEventWithErrorName:(NSString *)errorName
{
    [self reportReferrerEventForStatus:@"failure"
                             errorName:errorName
                       attributionInfo:nil
                                 error:NULL];
}

- (NSString *)errorCodeKey:(AMASearchAdsRequesterErrorCode)errorCode
{
    switch (errorCode) {
        case AMASearchAdsRequesterErrorUnknown:
            return kAMASearchAdsReporterCallbackTypeUnknown;
        case AMASearchAdsRequesterErrorTryLater:
            return kAMASearchAdsReporterCallbackTypeTryLater;
        case AMASearchAdsRequesterErrorAdTrackingLimited:
            return kAMASearchAdsReporterCallbackTypeAdTrackingLimited;
    }
}

@end
