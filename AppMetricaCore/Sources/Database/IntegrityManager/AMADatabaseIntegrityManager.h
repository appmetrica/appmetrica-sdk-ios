
#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@class AMADatabaseIntegrityManager;
@class AMADatabaseIntegrityStorage;
@class AMADatabaseIntegrityProcessor;

@protocol AMADatabaseIntegrityManagerDelegate <NSObject>

- (id)contextForIntegrityManager:(AMADatabaseIntegrityManager *)manager
            thatWillDropDatabase:(FMDatabaseQueue *)databaase;

- (void)integrityManager:(AMADatabaseIntegrityManager *)manager
    didCreateNewDatabase:(FMDatabaseQueue *)databaase
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

- (FMDatabaseQueue *)databaseWithEnsuredIntegrityWithIsNew:(BOOL *)isNew;

@end
