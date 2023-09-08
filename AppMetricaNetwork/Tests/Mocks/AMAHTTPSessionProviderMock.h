
#import <AppMetricaNetwork/AppMetricaNetwork.h>

typedef void(^AMAURLSessionDataTaskMockCallback)(NSData *data, NSURLResponse *response, NSError *error);

@interface AMAURLSessionDataTaskMock : NSObject

@property (nonatomic, copy, readonly) NSURLRequest *request;
@property (nonatomic, copy, readonly) AMAURLSessionDataTaskMockCallback callback;

@property (nonatomic, assign, readonly) BOOL started;
@property (nonatomic, assign, readonly) BOOL cancelled;

@end

@interface AMAURLSessionMock : NSObject

@property (nonatomic, strong, readonly) NSArray *createdTasks;

@end

@interface AMAHTTPSessionProviderMock : AMAHTTPSessionProvider

@property (nonatomic, strong, readonly) AMAURLSessionMock *sessionMock;

@end
