
#import "AMAIDSyncReporter.h"
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

- (void)reportEventForRequest:(AMAIDSyncRequest *)request
                         code:(NSInteger)code
                         body:(NSString *)body
                      headers:(NSDictionary<NSString *, NSArray<NSString *> *> *)headers
                  responseURL:(NSString *)responseURL
{
    NSMutableDictionary *eventValue = [NSMutableDictionary dictionary];
    eventValue[@"type"] = request.type;
    eventValue[@"url"] = responseURL;
    if (code > 0) eventValue[@"responseCode"] = @(code);
    if (body != nil) eventValue[@"responseBody"] = body;
    if (headers != nil) eventValue[@"responseHeaders"] = headers;
    
    if (self.libraryReporter == nil) {
        self.libraryReporter = [AMAAppMetrica reporterForAPIKey:kAMAIDSyncAppMetricaLibraryApiKey];
    }
    
    [self.libraryReporter reportEvent:@"id_sync" parameters:eventValue onFailure:nil];
}

@end
