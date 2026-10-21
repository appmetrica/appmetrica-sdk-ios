
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMADeepLinkProcessor.h"
#import "AMACore.h"
#import "AMADeepLinkPayloadFactory.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"

NSString *const kAMADeepLinkTypeOpen = @"open";

@interface AMADeepLinkProcessor ()

@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *reportedURLs;

@end

@implementation AMADeepLinkProcessor

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _reportedURLs = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Public -

- (NSDictionary *)consumeURL:(NSURL *)url
                      ofType:(NSString *)type
                      isAuto:(BOOL)isAuto
               reattribution:(BOOL *)reattribution
{
    if (reattribution != NULL) {
        *reattribution = NO;
    }

    NSError *error = nil;
    NSDictionary *payload =
        [AMADeepLinkPayloadFactory deepLinkPayloadForURL:url ofType:type isAuto:isAuto error:&error];
    if (payload == nil) {
        AMALogWarn(@"Failed to process URL: %@", error);
        return nil;
    }

    NSString *urlString = url.absoluteString ?: @"";
    if ([self.reportedURLs containsObject:urlString]) {
        AMALogWarn(@"URL has already been reported: %@", urlString);
        return nil;
    }

    [self.reportedURLs addObject:urlString];
    if (reattribution != NULL) {
        *reattribution = [self isReatributionURL:url];
    }
    return payload;
}

#pragma mark - Private -

- (BOOL)isReatributionURL:(NSURL *)url
{
    BOOL result = NO;
    NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:url];
    NSString *referrer = parameters[@"referrer"];
    if (referrer.length != 0) {
        referrer = [AMAURLUtilities unescapeString:referrer];
        NSArray *referrerComponents = [referrer componentsSeparatedByString:@"&"];
        NSArray<AMAPair *> *conditions = [[AMAMetricaConfiguration sharedInstance].startup attributionDeeplinkConditions];
        for (NSString *component in referrerComponents) {
            NSArray *keyValuePair = [component componentsSeparatedByString:@"="];
            if ([self doesKeyValuePair:keyValuePair matchReattributionConditions:conditions]) {
                result = YES;
                break;
            }
        }
    }
    return result;
}

- (BOOL)doesKeyValuePair:(NSArray *)keyValuePair matchReattributionConditions:(NSArray<AMAPair *> *)conditions
{
    if (keyValuePair.count == 0 || keyValuePair.count > 2) {
        return NO;
    }
    NSString *name = [keyValuePair[0] stringByRemovingPercentEncoding];
    NSString *value = nil;
    if (keyValuePair.count == 2) {
        value = [keyValuePair[1] stringByRemovingPercentEncoding];
    }
    if ([name isEqualToString:@"reattribution"] && [value isEqualToString:@"1"]) {
        return YES;
    }
    for (AMAPair *condition in conditions) {
        if ([name isEqualToString:condition.key]) {
            if (condition.value == nil || [condition.value isEqualToString:value]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
