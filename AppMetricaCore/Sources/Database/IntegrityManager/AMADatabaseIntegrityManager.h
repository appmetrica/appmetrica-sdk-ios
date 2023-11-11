
#import <Foundation/Foundation.h>

@class AMAFMDatabaseQueue;
@class AMADatabaseIntegrityManager;
@class AMADatabaseIntegrityStorage;
@class AMADatabaseIntegrityProcessor;

@protocol AMADatabaseIntegrityManagerDelegate <NSObject>

- (id)contextForIntegrityManager:(AMADatabaseIntegrityManager *)manager
            thatWillDropDatabase:(AMAFMDatabaseQueue *)databaase;

- (void)integrityManager:(AMADatabaseIntegrityManager *)manager
    didCreateNewDatabase:(AMAFMDatabaseQueue *)databaase
                 context:(id)context;

@end

@interface AMADatabaseIntegrityManager : NSObject

@property (nonatomic, weak) id<AMADatabaseIntegrityManagerDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDatabasePath:(NSString *)databasePath;
- (instancetype)initWithDatabasePath:(NSString *)databasePath
                             storage:(AMADatabaseIntegrityStorage *)storage
                           processor:(AMADatabaseIntegrityProcessor *)processor;

- (AMAFMDatabaseQueue *)databaseWithEnsuredIntegrityWithIsNew:(BOOL *)isNew;

@end
