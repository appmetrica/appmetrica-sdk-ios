
#import <Foundation/Foundation.h>

@protocol AMADatabaseProtocol;
@class AMAEventSerializer;
@class AMASessionSerializer;

@interface AMAReportRequestProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApiKey:(NSString *)apiKey
                      database:(id<AMADatabaseProtocol>)database
               eventSerializer:(AMAEventSerializer *)eventSerializer
             sessionSerializer:(AMASessionSerializer *)sessionSerializer
             additionalAPIKeys:(NSArray *)additionalAPIKeys;

- (NSArray *)requestModels;

@end
