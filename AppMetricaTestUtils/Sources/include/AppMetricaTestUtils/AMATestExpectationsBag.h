#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMATestExpectationsBag : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTestCase:(XCTestCase*)testCase;
+ (instancetype)expectationBagWithTestCase:(XCTestCase*)testCase;

@property (nonatomic) NSTimeInterval defaultTimeout;

@property (readonly, nonnull) NSArray<XCTestExpectation *> *expectations;
- (XCTestExpectation*)expectationWithDescription:(NSString*)description;
- (XCTestExpectation*)expectationWithDescription:(NSString*)description inverted:(BOOL)inverted;
- (XCTestExpectation*)expectationWithDescription:(NSString*)description inverted:(BOOL)inverted count:(NSUInteger)count;

- (void)waitForExpectations;
- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeInterval;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
