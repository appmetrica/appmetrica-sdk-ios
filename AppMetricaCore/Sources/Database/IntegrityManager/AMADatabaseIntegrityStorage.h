
#import <Foundation/Foundation.h>

@protocol AMAKeyValueStorageProviding;
@protocol AMADateProviding;

@interface AMADatabaseIntegrityStorage : NSObject

@property (nonatomic, assign, readonly) NSUInteger incidentsCount;
@property (nonatomic, strong, readonly) NSDate *firstIncidentDate;
@property (nonatomic, strong, readonly) NSDate *lastIncidentDate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorageProvider:(id<AMAKeyValueStorageProviding>)storageProvider;
- (instancetype)initWithStorageProvider:(id<AMAKeyValueStorageProviding>)storageProvider
                           dateProvider:(id<AMADateProviding>) dateProvider;

- (void)handleIncident;

@end
