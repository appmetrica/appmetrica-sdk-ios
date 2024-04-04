#import "AMAReporter.h"

@interface AMAReporterMock : AMAReporter

@property (nonatomic, strong) NSDictionary *lastAttribution;
@property (nonatomic, assign) AMAAttributionSource lastSource;
@property (nonatomic, copy) void (^lastOnFailure)(NSError *error);
@property (nonatomic, assign) BOOL reportExternalAttributionCalled;

- (instancetype)init;

@end

