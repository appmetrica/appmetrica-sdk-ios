
#import <Foundation/Foundation.h>

@class AMADataSendingRestrictionController;
@class AMAReporterStateStorage;
@protocol AMAExecuting;

@interface AMAInternalStateReportingController : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor;
- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
           restrictionController:(AMADataSendingRestrictionController *)restrictionController;

- (void)registerStorage:(AMAReporterStateStorage *)stateStorage forApiKey:(NSString *)apiKey;

- (void)start;
- (void)shutdown;

@end
