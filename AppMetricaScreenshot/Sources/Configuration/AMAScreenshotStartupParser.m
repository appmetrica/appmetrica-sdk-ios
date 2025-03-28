#import "AMAScreenshotStartupParser.h"
#import "AMAScreenshotConfiguration.h"
#import "AMAScreenshotStartupResponse.h"

@implementation AMAScreenshotStartupParser

+ (AMAScreenshotStartupResponse *)parse:(NSDictionary*)startupDictionary
{
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupResponse new];
    
    NSDictionary *screenshotFeature = startupDictionary[@"features"][@"list"][@"screenshot"];
    if (screenshotFeature != nil) {
        response.featureEnabled = [screenshotFeature[@"enabled"] boolValue];
    }
    
    NSDictionary *apiCaptor = startupDictionary[@"screenshot"][@"api_captor_config"];
    if (apiCaptor != nil) {
        response.captorEnabled = [apiCaptor[@"enabled"] boolValue];
    }
    
    return response;
}

@end
