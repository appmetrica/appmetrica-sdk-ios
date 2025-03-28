#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>

#import "AMAScreenshotMainReporter.h"

@interface AMAScreenshotMainReporterTests : XCTestCase

@property (nonatomic, strong) AMAScreenshotMainReporter *reporter;

@end

@implementation AMAScreenshotMainReporterTests

- (void)setUp
{
    self.reporter = [AMAScreenshotMainReporter new];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

- (void)testReportScreenshot {
    XCTestExpectation *reportEventExpectation = [self expectationWithDescription:@"reportEvent"];
    
    [AMAAppMetrica stub:@selector(reportEvent:onFailure:) withBlock:^id(NSArray *params) {
        [reportEventExpectation fulfill];
        
        return nil;
    }];
    
    [self.reporter reportScreenshot];
    [self waitForExpectations:@[reportEventExpectation]];
}

@end
