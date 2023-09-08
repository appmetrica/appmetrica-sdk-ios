#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAErrorUtilitiesTests : XCTestCase

@end

@implementation AMAErrorUtilitiesTests

- (void)testFillErrorWithError
{
    NSError *const sourceError = [NSError errorWithDomain:@"domain" code:0 userInfo:nil];
    
    NSError *result = nil;
    [AMAErrorUtilities fillError:&result withError:sourceError];

    XCTAssertEqualObjects(result, sourceError, @"Should fill error");
}

- (void)testFillErrorWithInternalErrorName
{
    NSString *const errorName = @"Internal error";
    
    NSError *result = nil;
    [AMAErrorUtilities fillError:&result withInternalErrorName:errorName];

    XCTAssertEqualObjects(result.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill internal error domain");
    XCTAssertEqual(result.code, AMAAppMetricaInternalEventErrorCodeNamedError, @"Should fill internal error code");
    XCTAssertEqualObjects(result.userInfo, @{ NSLocalizedDescriptionKey: errorName }, @"Should fill internal error userInfo");
}

- (void)testErrorByAddingUnderlyingError
{
    NSString *const errorKey = @"error";
    
    NSError *underlyingError = [NSError errorWithDomain:@"underlyingError" code:0 userInfo:@{errorKey: @"underlyingError"}];
    NSError *initialError = [NSError errorWithDomain:@"initialError" code:0 userInfo:@{errorKey: @"initialError"}];
    
    NSError *result = nil;
    result = [AMAErrorUtilities errorByAddingUnderlyingError:underlyingError toError:nil];
    
    XCTAssertEqualObjects(result, underlyingError, @"Should return underlyingError initial error is nil");
    
    result = nil;
    result = [AMAErrorUtilities errorByAddingUnderlyingError:underlyingError toError:initialError];
    
    XCTAssertEqualObjects(result.userInfo[NSUnderlyingErrorKey], underlyingError, @"Should add underlyingError to userInfo");
    XCTAssertEqualObjects(result.domain, initialError.domain, @"Should fill initialError domain");
    XCTAssertEqual(result.code, initialError.code, @"Should fill initialError code");
    XCTAssertEqualObjects(result.userInfo[errorKey], initialError.userInfo[errorKey], @"Should fill initialError userInfo");
}

- (void)testErrorWithDomain
{
    NSString *const domain = @"domain";
    NSInteger const code = 99;
    NSString *const description = @"error description";
    
    NSError *result = nil;
    result = [AMAErrorUtilities errorWithDomain:domain code:code description:description];
    
    XCTAssertEqualObjects(result.domain, domain, @"Should fill error domain");
    XCTAssertEqual(result.code, code, @"Should fill error code");
    XCTAssertEqualObjects(result.userInfo, @{ NSLocalizedDescriptionKey: description }, @"Should fill error userInfo");
}

- (void)testErrorWithCode
{
    NSInteger const code = 99;
    NSString *const description = @"error description";
    
    NSError *result = nil;
    result = [AMAErrorUtilities errorWithCode:code description:description];
    
    XCTAssertEqualObjects(result.domain, kAMAAppMetricaErrorDomain, @"Should fill error domain");
    XCTAssertEqual(result.code, code, @"Should fill error code");
    XCTAssertEqualObjects(result.userInfo, @{ NSLocalizedDescriptionKey: description }, @"Should fill error userInfo");
}

- (void)testInternalErrorWithCode
{
    NSInteger const code = 99;
    NSString *const description = @"error description";
    
    NSError *result = nil;
    result = [AMAErrorUtilities internalErrorWithCode:code description:description];
    
    XCTAssertEqualObjects(result.domain, kAMAAppMetricaInternalErrorDomain, @"Should fill internal error domain");
    XCTAssertEqual(result.code, code, @"Should fill error code");
    XCTAssertEqualObjects(result.userInfo, @{ NSLocalizedDescriptionKey: description }, @"Should fill error userInfo");
}

@end
