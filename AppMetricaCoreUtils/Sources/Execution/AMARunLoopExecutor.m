#import "AMARunLoopExecutor.h"
#import "AMARunLoopThread.h"
#import "AMACoreUtilsDomain.h"

@interface AMARunLoopExecutor ()

@property (atomic, assign) BOOL isStarted;
@property (nonatomic, strong, nonnull) AMARunLoopThread *thread;

@end

@implementation AMARunLoopExecutor

+ (NSString *)runLoopNameWithDomain:(NSString *)domain identifier:(NSString *)identifier
{
    NSArray *queueNameComponents = @[
        domain,
        identifier
    ];
    
    return [queueNameComponents componentsJoinedByString:@"."];
}

- (instancetype)init
{
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _thread = [AMARunLoopThread new];
        _thread.name = name ?: [self.class runLoopNameWithDomain:kAppMetricaCoreUtilsDomain identifier:NSStringFromClass(self.class)];
    }
    return self;
}

- (void)dealloc
{
    if (self.isStarted) {
        dispatch_block_t internalBlock = ^{ };
        [self performSelector:@selector(executeInThread:) onThread:self.thread withObject:internalBlock waitUntilDone:YES];
        [self.thread cancel];
    }
}

- (void)execute:(dispatch_block_t)block
{
    if (block == nil) {
        return;
    }
    
    if (NSThread.currentThread == self.thread) {
        block();
    } else {
        [self startIfNeeded];
        [self performSelector:@selector(executeInThread:) onThread:self.thread withObject:[block copy] waitUntilDone:NO];
    }
}

- (id)syncExecute:(id  _Nullable (^)(void))block
{
    if (block == nil) {
        return nil;
    }
    
    id __block returnValue = nil;
    if (NSThread.currentThread == self.thread) {
        returnValue = block();
    } else {
        [self startIfNeeded];
        dispatch_block_t internalBlock = ^{
            returnValue = block();
        };
        [self performSelector:@selector(executeInThread:) onThread:self.thread withObject:internalBlock waitUntilDone:YES];
    }
    
    return returnValue;
}

- (void)startIfNeeded
{
    if (self.isStarted == NO) {
        @synchronized (self) {
            if (self.isStarted == NO) {
                self.isStarted = YES;
                [self.thread start];
            }
        }
    }
}

- (void)executeInThread:(dispatch_block_t)block
{
    NSAssert(self.thread == NSThread.currentThread, @"invalid thread");
    block();
}

@end
