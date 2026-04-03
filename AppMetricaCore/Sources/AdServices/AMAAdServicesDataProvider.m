
#import "AMACore.h"
#import "AMAAdServicesDataProvider.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140300
    #if !TARGET_OS_TV
        #import <AdServices/AdServices.h>
    #endif
#endif

@implementation AMAAdServicesDataProvider

- (NSString *)tokenWithError:(NSError **)error
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140300
#if !TARGET_OS_TV
#if !TARGET_OS_SIMULATOR // https://nda.ya.ru/t/CfMmPl4Q7XeEJA
    if (@available(iOS 14.3, *)) {
        NSError *localError = nil;
        NSString *token = [AAAttribution attributionTokenWithError:&localError];

        if (token != nil) {
            AMALogInfo(@"AdServices token successfully received!");
        }
        else if (localError != nil) {
            AMALogInfo(@"AdServices attribution token error: %@", localError);
            [AMAErrorUtilities fillError:error withError:localError];
        }
        else {
            AMALogInfo(@"AdServices available, but received unexpected `nil` token");
            [AMAErrorUtilities fillError:error withInternalErrorName:@"AdServices available. Nil token"];
        }

        return token;
    }
#endif
#endif
#endif
    AMALogInfo(@"AdServices unavailable");
    [AMAErrorUtilities fillError:error withInternalErrorName:@"AdServices unavailable"];
    return nil;
}

@end
