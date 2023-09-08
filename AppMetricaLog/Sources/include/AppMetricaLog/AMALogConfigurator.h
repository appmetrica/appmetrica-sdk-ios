
#import <AppMetricaLog/AppMetricaLog.h>

NS_ASSUME_NONNULL_BEGIN

@class AMALogFacade;

@interface AMALogConfigurator : NSObject

- (instancetype)initWithLog:(AMALogFacade *)log;

- (void)setChannel:(AMALogChannel)channel enabled:(BOOL)enabled;
- (void)setupLogWithChannel:(AMALogChannel)channel;

@end

NS_ASSUME_NONNULL_END
