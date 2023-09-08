
#import "AMAHTTPSessionProviderMock.h"

@interface AMAURLSessionDataTaskMock ()

@property (nonatomic, assign, readwrite) BOOL started;
@property (nonatomic, assign, readwrite) BOOL cancelled;

@end

@implementation AMAURLSessionDataTaskMock

- (instancetype)initWithRequest:(NSURLRequest *)request callback:(AMAURLSessionDataTaskMockCallback)callback
{
    self = [super init];
    if (self != nil) {
        _request = [request copy];
        _callback = [callback copy];
    }
    return self;
}

- (void)resume
{
    self.started = YES;
}

- (void)cancel
{
    self.cancelled = YES;
}

@end

@interface AMAURLSessionMock ()

@property (nonatomic, strong) NSMutableArray *mutableCreatedTasks;

@end

@implementation AMAURLSessionMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _mutableCreatedTasks = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)createdTasks
{
    return [self.mutableCreatedTasks copy];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler
{
    AMAURLSessionDataTaskMock *taskMock = [[AMAURLSessionDataTaskMock alloc] initWithRequest:request
                                                                                    callback:completionHandler];
    [self.mutableCreatedTasks addObject:taskMock];
    return (NSURLSessionDataTask *)taskMock;
}

@end

@implementation AMAHTTPSessionProviderMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _sessionMock = [[AMAURLSessionMock alloc] init];
    }
    return self;
}

- (NSURLSession *)session
{
    return (NSURLSession *)self.sessionMock;
}

@end
