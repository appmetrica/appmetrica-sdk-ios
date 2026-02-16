
#import <Foundation/Foundation.h>
#import "AMACrashLoading.h"
#import "AMAUnhandledCrashDetector.h"

@class AMADecodedCrash;

NS_ASSUME_NONNULL_BEGIN

@protocol AMACrashLoaderDelegate <NSObject>

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
       didLoadCrash:(AMADecodedCrash *)decodedCrash
          withError:(nullable NSError *)error;

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
         didLoadANR:(AMADecodedCrash *)decodedCrash
          withError:(nullable NSError *)error;

- (void)crashLoader:(id<AMACrashLoading>)crashLoader
didDetectProbableUnhandledCrash:(AMAUnhandledCrashType)crashType;

@end

NS_ASSUME_NONNULL_END
