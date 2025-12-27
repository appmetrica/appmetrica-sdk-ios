
#import "AMAIDSyncReportRequest.h"
#import "AMAIDSyncRequestResponse.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncCore.h"
#import <UIKit/UIKit.h>

static NSString *const kAMAIFVParamKey = @"ifv";
static NSString *const kAMADeviceIDParamKey = @"deviceid";
static NSString *const kAMAUUIDParamKey = @"uuid";

@interface AMAIDSyncReportRequest ()

@property (nonatomic, strong) AMAIDSyncRequestResponse *response;

@end

@implementation AMAIDSyncReportRequest

- (instancetype)initWithResponse:(AMAIDSyncRequestResponse *)response
{
    self = [super init];
    if (self != nil) {
        _response = response;
        self.host = response.request.reportUrl;
    }
    return self;
}

- (NSString *)method
{
    return @"POST";
}

- (NSData *)body
{
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    bodyDict[@"type"] = self.response.request.type;
    bodyDict[@"url"] = self.response.responseURL;
    if (self.response.code > 0) bodyDict[@"responseCode"] = @(self.response.code);
    if (self.response.body != nil) bodyDict[@"responseBody"] = self.response.body;
    if (self.response.headers != nil) bodyDict[@"responseHeaders"] = self.response.headers;
    
    NSError *error = nil;
    NSData *jsonData = [AMAJSONSerialization dataWithJSONObject:bodyDict error:nil];
    
    if (error != nil || jsonData == nil) {
        AMALogError(@"Failed to serialize id sync report body to JSON: %@", error);
        return nil;
    }

    return jsonData;
}

- (NSDictionary *)headerComponents
{
    NSMutableDictionary *headers = [super headerComponents].mutableCopy;
    [headers addEntriesFromDictionary:@{
        @"Content-Type": @"application/json"
    }];
    return headers.copy;
}

- (NSDictionary *)GETParameters
{
    NSMutableDictionary *parameters = [[super GETParameters] mutableCopy];

    NSString *ifv = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSString *deviceID = [AMAAppMetrica deviceID];
    NSString *uuid = [AMAAppMetrica UUID];

    if (ifv != nil) parameters[kAMAIFVParamKey] = ifv;
    if (deviceID != nil) parameters[kAMADeviceIDParamKey] = deviceID;
    if (uuid != nil) parameters[kAMAUUIDParamKey] = uuid;

    return parameters;
}

@end
