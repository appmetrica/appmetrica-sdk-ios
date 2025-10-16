
#import "AMAIDSyncRequestsConverter.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncKeys.h"

NSUInteger const kAMAIDSyncDefaultValidResendInterval = 86400;
NSUInteger const kAMAIDSyncDefaultInvalidResendInterval = 3600;
static NSUInteger const kAMAIDSyncDefaultValidResponseCode = 200;

@implementation AMAIDSyncRequestsConverter

- (NSArray<AMAIDSyncRequest *> *)convertDictToRequests:(NSArray<NSDictionary *> *)requests
{
    NSMutableArray<AMAIDSyncRequest *> *result = [NSMutableArray array];
    
    for (id request in requests) {
        NSString *type = [request[AMAIDSyncRequestTypeKey] isKindOfClass:[NSString class]]
                       ? request[AMAIDSyncRequestTypeKey]
                       : nil;
        NSString *url = [request[AMAIDSyncRequestUrlKey] isKindOfClass:[NSString class]]
                      ? request[AMAIDSyncRequestUrlKey]
                      : nil;
        
        if (type != nil && url != nil) {
            NSDictionary *headers = [request[AMAIDSyncRequestHeadersKey] isKindOfClass:[NSDictionary class]]
                                  ? request[AMAIDSyncRequestHeadersKey]
                                  : @{};
            
            NSDictionary *preconditions = [request[AMAIDSyncRequestPreconditionsKey] isKindOfClass:[NSDictionary class]]
                                        ? request[AMAIDSyncRequestPreconditionsKey]
                                        : @{};
            
            NSNumber *validResendInterval = [request[AMAIDSyncRequestResendIntervalForValidResponseKey] isKindOfClass:[NSNumber class]]
                                          ? request[AMAIDSyncRequestResendIntervalForValidResponseKey]
                                          : @(kAMAIDSyncDefaultValidResendInterval);
            NSNumber *invalidResendInterval = [request[AMAIDSyncRequestResendIntervalForInvalidResponseKey] isKindOfClass:[NSNumber class]]
                                            ? request[AMAIDSyncRequestResendIntervalForInvalidResponseKey]
                                            : @(kAMAIDSyncDefaultInvalidResendInterval);
            
            NSArray<NSNumber *> *validResponseCodes = [request[AMAIDSyncRequestValidResponseCodesKey] isKindOfClass:[NSArray class]]
                                                    ? request[AMAIDSyncRequestValidResponseCodesKey]
                                                    : @[@(kAMAIDSyncDefaultValidResponseCode)];
            
            AMAIDSyncRequest *req = [[AMAIDSyncRequest alloc] initWithType:type
                                                                       url:url
                                                                   headers:headers
                                                             preconditions:preconditions
                                                       validResendInterval:validResendInterval
                                                     invalidResendInterval:invalidResendInterval
                                                        validResponseCodes:validResponseCodes];
            
            [result addObject:req];
        }
    }
    
    return result;
}

@end
