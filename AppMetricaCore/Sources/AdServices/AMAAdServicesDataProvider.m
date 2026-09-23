
#import "AMACore.h"
#import "AMAAdServicesDataProvider.h"

#if !TARGET_OS_TV
#import <AdServices/AdServices.h>
#endif

@implementation AMAAdServicesDataProvider

- (NSString *)tokenWithError:(NSError **)error
{
#if !TARGET_OS_TV && !TARGET_OS_SIMULATOR // https://nda.ya.ru/t/CfMmPl4Q7XeEJA
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
#else
    AMALogInfo(@"AdServices unavailable");
    [AMAErrorUtilities fillError:error withInternalErrorName:@"AdServices unavailable"];
    return nil;
#endif
}

@end
