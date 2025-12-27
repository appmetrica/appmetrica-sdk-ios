
#import "AMAIDSyncReporter.h"
#import "AMAIDSyncRequestResponse.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncCore.h"

NSString *const kAMAIDSyncAppMetricaLibraryApiKey = @"20799a27-fa80-4b36-b2db-0f8141f24180";

@interface AMAIDSyncReporter ()

@property (nonatomic, strong) id<AMAAppMetricaReporting> libraryReporter;

@end

@implementation AMAIDSyncReporter

- (instancetype)init
{
    return [self initWithReporter:nil];
}

- (instancetype)initWithReporter:(nullable id<AMAAppMetricaReporting>)libraryReporter
{
    self = [super init];
    if (self) {
        _libraryReporter = libraryReporter;
    }
    return self;
}

- (void)reportEventForResponse:(AMAIDSyncRequestResponse *)response
{
    NSMutableDictionary *eventValue = [NSMutableDictionary dictionary];
    eventValue[@"type"] = response.request.type;
    eventValue[@"url"] = response.responseURL;
    if (response.code > 0) eventValue[@"responseCode"] = @(response.code);
    if (response.body != nil) eventValue[@"responseBody"] = response.body;
    if (response.headers != nil) eventValue[@"responseHeaders"] = response.headers;

    if (self.libraryReporter == nil) {
        self.libraryReporter = [AMAAppMetrica reporterForAPIKey:kAMAIDSyncAppMetricaLibraryApiKey];
    }

    [self.libraryReporter reportEvent:@"id_sync" parameters:eventValue onFailure:nil];
}

@end
