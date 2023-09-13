
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMATestAssertionHandler ()

@property (nonatomic, strong) NSAssertionHandler *currentHandler;
@property (nonatomic, strong) NSThread *currentThread;

@end

@implementation AMATestAssertionHandler

- (void)dealloc
{
    [self endAssertIgnoring];
}

- (void)beginAssertIgnoring
{
    @synchronized (self) {
        BOOL isAssertionAlreadyIgnored = self.currentHandler != nil;
        if (isAssertionAlreadyIgnored) {
            return;
        }

        self.currentHandler = [NSAssertionHandler currentHandler];
        self.currentThread = [NSThread currentThread];
        [[self.currentThread threadDictionary] setValue:self forKey:NSAssertionHandlerKey];
    }
}

- (void)endAssertIgnoring
{
    @synchronized (self) {
        BOOL ignoringAssertions = self.currentHandler != nil;
        if (ignoringAssertions) {
            [[self.currentThread threadDictionary] setValue:self.currentHandler forKey:NSAssertionHandlerKey];
            self.currentHandler = nil;
        }
    }
}

-(void)handleFailureInMethod:(SEL)selector object:(id)object
                        file:(NSString *)fileName
                  lineNumber:(NSInteger)line
                 description:(NSString *)format, ...
{
    //ignore assert
}

-(void)handleFailureInFunction:(NSString *)functionName
                          file:(NSString *)fileName
                    lineNumber:(NSInteger)line
                   description:(NSString *)format, ...
{
    //ignore assert
}

@end
