
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "AMALocationManagerState.h"

@interface AMALocationManagerStateTests : XCTestCase

@end

@implementation AMALocationManagerStateTests

- (void)testCopy
{
    AMALocationManagerMutableState *initialState = [AMALocationManagerMutableState new];
    initialState.authorizationStatus = @(1);
    initialState.currentTrackLocationEnabled = YES;
    initialState.currentAccurateLocationEnabled = YES;
    initialState.currentAllowsBackgroundLocationUpdates = YES;
    initialState.externalLocation = [[CLLocation alloc] initWithLatitude:1.0 longitude:2.0];
    
    AMALocationManagerState *copiedState = [initialState copy];
    
    XCTAssertEqualObjects(initialState.authorizationStatus, copiedState.authorizationStatus);
    XCTAssertEqual(initialState.currentTrackLocationEnabled, copiedState.currentTrackLocationEnabled);
    XCTAssertEqual(initialState.currentAccurateLocationEnabled, copiedState.currentAccurateLocationEnabled);
    XCTAssertEqual(initialState.currentAllowsBackgroundLocationUpdates, copiedState.currentAllowsBackgroundLocationUpdates);
    
    XCTAssertEqualObjects(initialState.externalLocation, copiedState.externalLocation);
    
    AMALocationManagerState *yetAnotherCopiedState = [copiedState copy];
    XCTAssertEqual(copiedState, yetAnotherCopiedState);
}

- (void)testMutableCopy
{
    AMALocationManagerMutableState *initialState = [AMALocationManagerMutableState new];
    initialState.authorizationStatus = @(1);
    initialState.currentTrackLocationEnabled = YES;
    initialState.currentAccurateLocationEnabled = YES;
    initialState.currentAllowsBackgroundLocationUpdates = YES;
    initialState.externalLocation = [[CLLocation alloc] initWithLatitude:1.0 longitude:2.0];
    
    AMALocationManagerState *copiedState = [initialState copy];
    
    XCTAssertEqualObjects(initialState.authorizationStatus, copiedState.authorizationStatus);
    XCTAssertEqual(initialState.currentTrackLocationEnabled, copiedState.currentTrackLocationEnabled);
    XCTAssertEqual(initialState.currentAccurateLocationEnabled, copiedState.currentAccurateLocationEnabled);
    XCTAssertEqual(initialState.currentAllowsBackgroundLocationUpdates, copiedState.currentAllowsBackgroundLocationUpdates);
    
    XCTAssertEqualObjects(initialState.externalLocation, copiedState.externalLocation);
    
    AMALocationManagerState *yetAnotherCopiedState = [copiedState mutableCopy];
    
    XCTAssertEqualObjects(initialState.authorizationStatus, yetAnotherCopiedState.authorizationStatus);
    XCTAssertEqual(initialState.currentTrackLocationEnabled, yetAnotherCopiedState.currentTrackLocationEnabled);
    XCTAssertEqual(initialState.currentAccurateLocationEnabled, yetAnotherCopiedState.currentAccurateLocationEnabled);
    XCTAssertEqual(yetAnotherCopiedState.currentAllowsBackgroundLocationUpdates, copiedState.currentAllowsBackgroundLocationUpdates);
    XCTAssertEqualObjects(initialState.externalLocation, yetAnotherCopiedState.externalLocation);
}

- (void)testMutableStateMutableCopy
{
    AMALocationManagerMutableState *initialState = [AMALocationManagerMutableState new];
    initialState.authorizationStatus = @(1);
    initialState.currentTrackLocationEnabled = YES;
    initialState.currentAccurateLocationEnabled = YES;
    initialState.currentAllowsBackgroundLocationUpdates = YES;
    initialState.externalLocation = [[CLLocation alloc] initWithLatitude:1.0 longitude:2.0];
    
    AMALocationManagerMutableState *copiedState = [initialState mutableCopy];
    
    XCTAssertEqualObjects(initialState.authorizationStatus, copiedState.authorizationStatus);
    XCTAssertEqual(initialState.currentTrackLocationEnabled, copiedState.currentTrackLocationEnabled);
    XCTAssertEqual(initialState.currentAccurateLocationEnabled, copiedState.currentAccurateLocationEnabled);
    XCTAssertEqual(initialState.currentAllowsBackgroundLocationUpdates, copiedState.currentAllowsBackgroundLocationUpdates);
    
    XCTAssertEqualObjects(initialState.externalLocation, copiedState.externalLocation);
}

@end
