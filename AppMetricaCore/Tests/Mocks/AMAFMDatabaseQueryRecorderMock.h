#import <Foundation/Foundation.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAFMDatabaseQueryRecorderMock : AMAFMDatabase

@property (nonatomic, copy, readonly) NSArray<NSString *> *executedStatements;

@end

NS_ASSUME_NONNULL_END
