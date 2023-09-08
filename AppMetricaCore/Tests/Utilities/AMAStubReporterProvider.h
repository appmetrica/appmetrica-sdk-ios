
#import "AMAReporterProviding.h"

@interface AMAStubReporterProvider : NSObject <AMAReporterProviding>

@property (nonatomic, strong) NSObject<AMAAppMetricaReporting > *reporter;

@end
