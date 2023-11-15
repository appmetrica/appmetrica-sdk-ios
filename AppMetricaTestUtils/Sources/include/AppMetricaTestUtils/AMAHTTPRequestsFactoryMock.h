#import <Foundation/Foundation.h>

#import <AppMetricaNetwork/AppMetricaNetwork.h>

typedef NS_ENUM(NSUInteger, AMAHTTPRequestsMockResponseType) {
    AMAHTTPRequestsMockResponseTypeNoResponse,
    AMAHTTPRequestsMockResponseTypeSuccess,
    AMAHTTPRequestsMockResponseTypeFailure,
} NS_SWIFT_NAME(HTTPRequestsMockResponseType);

NS_SWIFT_NAME(HTTPRequestResponseStub)
@interface AMAHTTPRequestResponseStub : NSObject

@property (nonatomic, assign, readonly) AMAHTTPRequestsMockResponseType responseType;

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, copy, readonly) NSData *result;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

- (instancetype)initWithReponseType:(AMAHTTPRequestsMockResponseType)responseType
                           response:(NSHTTPURLResponse *)response
                         statusCode:(NSInteger)statusCode
                              error:(NSError *)error
                             result:(NSData *)result;

+ (instancetype)noResponse;
+ (instancetype)successWithCode:(NSInteger)code data:(NSData *)data;
+ (instancetype)successWithCode:(NSInteger)code data:(NSData *)data headers:(NSDictionary *)headers;
+ (instancetype)failureWithCode:(NSInteger)code error:(NSError *)error;

@end

typedef AMAHTTPRequestResponseStub *(^AMAHTTPRequestResponseBlock)(NSURL *url, NSDictionary *headers)
    NS_SWIFT_UNAVAILABLE("Use Swift closures.");

NS_SWIFT_NAME(HTTPRequestsFactoryMock)
@interface AMAHTTPRequestsFactoryMock : AMAHTTPRequestsFactory

- (void)stub:(AMAHTTPRequestResponseStub *)stub forHost:(NSString *)host;
- (void)stubAll:(AMAHTTPRequestResponseStub *)stub;

- (void)stubHost:(NSString *)host withBlock:(AMAHTTPRequestResponseBlock)block;
- (void)stubAllWithBlock:(AMAHTTPRequestResponseBlock)block;

- (NSUInteger)countOfRequestsForHost:(NSString *)host;

@end
