
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMACrashProviding.h"
#import "AMACrashProviderDelegate.h"
#import "AMACrashLoaderDelegate.h"

@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Mock Pull Provider

@interface AMAExternalLoaderMockPullProvider : NSObject <AMACrashProviding>
@property (nonatomic, copy, nullable) NSArray<AMACrashEvent *> *reports;
@property (nonatomic, copy, nullable) NSArray<AMACrashEvent *> *processedEvents;
@end

#pragma mark - Mock Push Provider

@interface AMAExternalLoaderMockPushProvider : NSObject <AMACrashProviding>
@property (nonatomic, weak, nullable) id<AMACrashProviderDelegate> delegate;
@property (nonatomic, copy, nullable) NSArray<AMACrashEvent *> *processedEvents;
@end

#pragma mark - Mock Delegate

@interface AMAExternalLoaderMockDelegate : NSObject <AMACrashLoaderDelegate>

@property (nonatomic, strong) NSMutableArray<AMADecodedCrash *> *receivedCrashes;
@property (nonatomic, strong) NSMutableArray<AMADecodedCrash *> *receivedANRs;
@property (nonatomic, strong) NSMutableArray<id<AMACrashLoading>> *receivedLoaders;

@property (nonatomic, strong, nullable) XCTestExpectation *didLoadCrashExpectation;
@property (nonatomic, strong, nullable) XCTestExpectation *didLoadANRExpectation;

@end

NS_ASSUME_NONNULL_END
