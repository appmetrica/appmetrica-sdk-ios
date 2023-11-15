
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@class AMAApplicationState;

NS_SWIFT_NAME(RequestParameters)
@interface AMARequestParameters : NSObject <AMADictionaryRepresentation>

- (instancetype)initWithApiKey:(NSString *)apiKey
                 attributionID:(NSString *)attributionID
                     requestID:(NSString *)requestID
              applicationState:(AMAApplicationState *)appState
              inMemoryDatabase:(BOOL)inMemoryDatabase;

@end
