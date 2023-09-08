
#import <Foundation/Foundation.h>

@protocol AMADatabaseProtocol;
@class AMAEventsCleaner;

@interface AMADatabaseFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (id<AMADatabaseProtocol>)configurationDatabase;
+ (NSString *)configurationDatabasePath;
+ (id<AMADatabaseProtocol>)reporterDatabaseForApiKey:(NSString *)apiKey
                                       eventsCleaner:(AMAEventsCleaner *)eventsCleaner;
+ (id<AMADatabaseProtocol>)locationDatabase;

@end
