
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AMAStatisticsRestriction) {
    AMAStatisticsRestrictionNotActivated = 0,
    AMAStatisticsRestrictionUndefined,
    AMAStatisticsRestrictionAllowed,
    AMAStatisticsRestrictionForbidden,
};

@interface AMAStatisticsRestrictionController : NSObject

- (void)setMainApiKey:(NSString *)mainApiKey;
- (void)setMainApiKeyRestriction:(AMAStatisticsRestriction)restriction;
- (void)setReporterRestriction:(AMAStatisticsRestriction)restriction forApiKey:(NSString *)apiKey;

- (AMAStatisticsRestriction)restrictionForApiKey:(NSString *)apiKey;

- (BOOL)shouldEnableLocationSending;
- (BOOL)shouldReportToApiKey:(NSString *)apiKey;

+ (instancetype)sharedInstance;

@end
