
#import <Foundation/Foundation.h>

@class AMADecodedCrash;
@protocol AMACrashProcessingReporting;

@protocol AMACrashProcessing <NSObject>

@required

@property (nonatomic, strong) NSMutableSet<id<AMACrashProcessingReporting>> *extendedCrashReporters;

- (NSString *)identifier;

- (void)processCrash:(AMADecodedCrash *)decodedCrash;

- (void)processANR:(AMADecodedCrash *)decodedCrash;

- (void)processError:(NSString *)message exception:(NSException *)exception;

@end
