#import <XCTest/XCTest.h>
#import <AppMetricaScreenshot/AppMetricaScreenshot.h>
#import "AMAScreenshotWatcher.h"
#import "AMAMockScreenshotReporter.h"

@interface AMAScreenshotWatcher (Unprivate)
- (void)handleNotification:(NSNotification*)notification;
@end

@interface AMAScreenshotWatcherTests : XCTestCase

@property (nonatomic, strong) NSNotificationCenter *notificationCenter;
@property (nonatomic, strong) AMAMockScreenshotReporter *mockReporter;
@property (nonatomic, strong) AMAScreenshotWatcher *controller;

@end

@implementation AMAScreenshotWatcherTests

- (void)setUp
{
    self.notificationCenter = [NSNotificationCenter defaultCenter];
    self.mockReporter = [AMAMockScreenshotReporter new];
    self.controller = [[AMAScreenshotWatcher alloc] initWithReporter:self.mockReporter
                                                  notificationCenter:self.notificationCenter];
}

- (void)testCreateScreenshot
{
    self.mockReporter.reportScreenshotExpectation = [self expectationWithDescription:@"report screenshot"];
    
    [self.controller handleNotification:nil];
    
    [self waitForExpectations:@[self.mockReporter.reportScreenshotExpectation] timeout:1];
}

- (void)testCreateTwoScreenshot
{
    self.mockReporter.reportScreenshotExpectation = [self expectationWithDescription:@"report screenshot"];
    self.mockReporter.reportScreenshotExpectation.expectedFulfillmentCount = 2;
    
    [self.controller handleNotification:nil];
    [self.controller handleNotification:nil];
    
    [self waitForExpectations:@[self.mockReporter.reportScreenshotExpectation] timeout:1];
}

- (void)testScreenshotIfNotStarted
{
    self.mockReporter.reportScreenshotExpectation = [self expectationWithDescription:@"report screenshot"];
    self.mockReporter.reportScreenshotExpectation.inverted = YES;
    
    [self.notificationCenter postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    
    [self waitForExpectations:@[self.mockReporter.reportScreenshotExpectation] timeout:1];
}

- (void)testScreenshotIfStarted
{
    self.mockReporter.reportScreenshotExpectation = [self expectationWithDescription:@"report screenshot"];
    
    self.controller.isStarted = YES;
    [self.notificationCenter postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    
    [self waitForExpectations:@[self.mockReporter.reportScreenshotExpectation] timeout:1];
}

@end
