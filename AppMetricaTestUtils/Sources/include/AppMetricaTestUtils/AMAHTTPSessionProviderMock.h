#import <Foundation/Foundation.h>

#import <AppMetricaNetwork/AppMetricaNetwork.h>

typedef void(^AMAURLSessionDataTaskMockCallback)(NSData *data, NSURLResponse *response, NSError *error)
    NS_SWIFT_UNAVAILABLE("Use Swift closures.");

NS_SWIFT_NAME(URLSessionDataTaskMock)
@interface AMAURLSessionDataTaskMock : NSObject

@property (nonatomic, copy, readonly) NSURLRequest *request;
@property (nonatomic, copy, readonly) AMAURLSessionDataTaskMockCallback callback;

@property (nonatomic, assign, readonly) BOOL started;
@property (nonatomic, assign, readonly) BOOL cancelled;

@end

NS_SWIFT_NAME(URLSessionMock)
@interface AMAURLSessionMock : NSObject

@property (nonatomic, strong, readonly) NSArray *createdTasks;

@end

NS_SWIFT_NAME(HTTPSessionProviderMock)
@interface AMAHTTPSessionProviderMock : AMAHTTPSessionProvider

@property (nonatomic, strong, readonly) AMAURLSessionMock *sessionMock;

@end
