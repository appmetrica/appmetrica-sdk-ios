
#import <Foundation/Foundation.h>
#import "AMAOptionalBool.h"

@class AMAReporterStateStorage;
@class AMAEnvironmentContainer;
@class AMAEvent;
@class AMAAppMetricaPreloadInfo;
@class AMAEventValueFactory;
@protocol AMADataEncoding;
@class AMAEventComposerProvider;
@class AMACustomEventParameters;

@interface AMAEventBuilder : NSObject

@property (nonatomic, copy, readonly) AMAAppMetricaPreloadInfo *preloadInfo;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStateStorage:(AMAReporterStateStorage *)stateStorage
                         preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo;
- (instancetype)initWithStateStorage:(AMAReporterStateStorage *)stateStorage
                         preloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
                   eventValueFactory:(AMAEventValueFactory *)eventValueFactory
                         gZipEncoder:(id<AMADataEncoding>)gZipEncoder
               eventComposerProvider:(AMAEventComposerProvider *)eventComposerProvider;

- (AMAEvent *)clientEventNamed:(NSString *)eventName
                    parameters:(NSDictionary *)parameters
               firstOccurrence:(AMAOptionalBool)firstOccurrence
                         error:(NSError **)error;

- (AMAEvent *)eventWithInternalParameters:(AMACustomEventParameters *)parameters
                                    error:(NSError **)error;

- (AMAEvent *)eventReferrerWithValue:(NSString *)value
                               error:(NSError **)error;

- (AMAEvent *)eventASATokenWithParameters:(NSDictionary *)parameters error:(NSError **)error;

- (AMAEvent *)eventOpen:(NSDictionary *)parameters
   attributionIDChanged:(BOOL)attributionIDChanged
                  error:(NSError **)outError;

- (AMAEvent *)eventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
           eventEnvironment:(NSDictionary *)eventEnvironment
                     extras:(NSDictionary<NSString *, NSData *> *)extras
                      error:(NSError **)outError;

- (AMAEvent *)permissionsEventWithJSON:(NSString *)permissions error:(NSError **)outError;

- (AMAEvent *)eventFirstWithError:(NSError **)outError;

- (AMAEvent *)eventInitWithParameters:(NSDictionary *)parameters error:(NSError **)outError;

- (AMAEvent *)eventUpdateWithError:(NSError **)outError;

- (AMAEvent *)eventStartWithData:(NSData *)data;

- (AMAEvent *)eventAlive;

- (AMAEvent *)eventProfile:(NSData *)profileData;

- (AMAEvent *)eventRevenue:(NSData *)revenueData
            bytesTruncated:(NSUInteger)bytesTruncated;

- (AMAEvent *)eventCleanup:(NSDictionary *)parameters
                     error:(NSError **)outError;

- (AMAEvent *)eventECommerce:(NSData *)eCommerceData
              bytesTruncated:(NSUInteger)bytesTruncated;

- (AMAEvent *)eventAdRevenue:(NSData *)adRevenueData
              bytesTruncated:(NSUInteger)bytesTruncated;

- (AMAEvent *)autoAppOpenEvent:(NSDictionary *)parameters
                         error:(NSError **)outError;

- (AMAEvent *)jsEvent:(NSString *)name
                value:(NSString *)value;

- (AMAEvent *)jsInitEvent:(NSString *)value;

- (AMAEvent *)attributionEventWithName:(NSString *)name
                                 value:(NSDictionary *)value;
@end
