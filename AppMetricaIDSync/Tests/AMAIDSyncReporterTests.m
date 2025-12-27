
#import <XCTest/XCTest.h>
#import "AMAIDSyncReporter.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncRequestResponse.h"
#import <AppMetricaCore/AppMetricaCore.h>

@interface AMAIDSyncMockReporter : NSObject

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *parameters;

@end

@implementation AMAIDSyncMockReporter

// TODO: Add shared mock for reporter
- (void)reportEvent:(NSString *)eventName
         parameters:(NSDictionary *)parameters
          onFailure:(void (^)(NSError *))onFailure
{
    self.eventName = eventName;
    self.parameters = parameters;
}

@end

@interface AMAIDSyncReporterTests : XCTestCase
@end

@implementation AMAIDSyncReporterTests

- (void)testReportEventForRequest
{
    NSString *type = @"test_type";
    NSDictionary<NSString *, NSArray<NSString *> *> *headers = @{@"Header": @[@"Value"]};
    NSString *body = @"response body";
    NSInteger code = 200;
    NSString *responseURL = @"https://example.com";
    
    AMAIDSyncRequest *request = [[AMAIDSyncRequest alloc] initWithType:type
                                                                   url:responseURL
                                                               headers:headers
                                                         preconditions:@{}
                                                   validResendInterval:@(99)
                                                 invalidResendInterval:@(999)
                                                    validResponseCodes:@[@502]
                                                    reportEventEnabled:NO
                                                             reportUrl:nil];
    
    AMAIDSyncMockReporter *mockLibraryReporter = [[AMAIDSyncMockReporter alloc] init];
    AMAIDSyncReporter *reporter = [[AMAIDSyncReporter alloc] initWithReporter:(id<AMAAppMetricaReporting>)mockLibraryReporter];
    AMAIDSyncRequestResponse *response = [[AMAIDSyncRequestResponse alloc] initWithRequest:request
                                                                                      code:code
                                                                                      body:body
                                                                                   headers:headers
                                                                               responseURL:responseURL];
    
    [reporter reportEventForResponse:response];
    
    
    XCTAssertEqualObjects(mockLibraryReporter.eventName, @"id_sync");
    XCTAssertEqualObjects(mockLibraryReporter.parameters[@"type"], type);
    XCTAssertEqualObjects(mockLibraryReporter.parameters[@"url"], responseURL);
    XCTAssertEqualObjects(mockLibraryReporter.parameters[@"responseBody"], body);
    XCTAssertEqualObjects(mockLibraryReporter.parameters[@"responseHeaders"], headers);
    XCTAssertEqualObjects(mockLibraryReporter.parameters[@"responseCode"], @(code));
}

@end
