
#import <Foundation/Foundation.h>

@interface AMAInternalEventsReporter : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)reportSchemaInconsistencyWithDescription:(NSString *)inconsistencyDescription;
- (void)reportFailedTransactionWithID:(NSString *)transactionID
                            ownerName:(NSString *)ownerName
                      rollbackContent:(NSString *)rollbackContent
                    rollbackException:(NSException *)rollbackException
                       rollbackFailed:(BOOL)rollbackFailed;

- (void)reportSearchAdsAttempt;
- (void)reportSearchAdsCompletionWithType:(NSString *)callbackType parameters:(NSDictionary *)parameters;

- (void)reportEventFileNotFoundForEventWithType:(NSUInteger)eventType;

- (void)reportExtensionsReportWithParameters:(NSDictionary *)parameters;
- (void)reportExtensionsReportCollectingException:(NSException *)exception;

- (void)reportCorruptedCrashReportWithError:(NSError *)error;
- (void)reportUnsupportedCrashReportVersionWithError:(NSError *)error;
- (void)reportRecrashWithError:(NSError *)error;
- (void)reportSKADAttributionParsingError:(NSDictionary *)parameters;

@end
