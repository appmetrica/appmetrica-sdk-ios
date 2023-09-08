
#import <Foundation/Foundation.h>

@class FMDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface AMATableSchemeController : NSObject

@property (nonatomic, copy, readonly) NSArray<NSString *> *tableNames;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTableSchemes:(NSDictionary *)schemes;

- (void)createSchemaInDB:(FMDatabase *)db;
- (void)enforceDatabaseConsistencyInDB:(FMDatabase *)db
                       onInconsistency:(nullable void (^)(dispatch_block_t fix))onInconsistency;

@end

NS_ASSUME_NONNULL_END
