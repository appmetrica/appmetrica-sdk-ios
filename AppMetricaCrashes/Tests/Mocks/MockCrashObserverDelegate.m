
#import "MockCrashObserverDelegate.h"
#import <XCTest/XCTest.h>

@implementation MockCrashObserverDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

#pragma mark - AMACrashObserving

- (void)didDetectCrash:(AMACrashEvent *)crashEvent
{
    self.lastCrashEvent = crashEvent;
    [self.didDetectCrashExpectation fulfill];
}

- (void)didDetectANR:(AMACrashEvent *)crashEvent
{
    self.lastCrashEvent = crashEvent;
    [self.didDetectANRExpectation fulfill];
}

- (void)didDetectProbableUnhandledCrash:(NSString *)errorMessage
{
    self.lastErrorMessage = errorMessage;
    [self.didDetectProbableUnhandledCrashExpectation fulfill];
}

#pragma mark - Public Methods

- (void)reset
{
    self.didDetectCrashExpectation = nil;
    self.didDetectANRExpectation = nil;
    self.didDetectProbableUnhandledCrashExpectation = nil;
    self.lastCrashEvent = nil;
    self.lastErrorMessage = nil;
}

@end
