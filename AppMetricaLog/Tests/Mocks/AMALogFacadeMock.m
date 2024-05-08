
#import "AMALogOutput.h"
#import "AMALogFacadeMock.h"
#import "AMAASLLogMiddleware.h"
#import "AMAFileLogMiddleware.h"
#import "AMAOSLogMiddleware.h"
#import "AMATTYLogMiddleware.h"


@implementation AMALogFacadeMock

+ (instancetype)sharedLog
{
    return [[AMALogFacadeMock alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        self.outputs = NSMutableArray.array;
    }
    return self;
}

- (void)addOutput:(AMALogOutput *)output
{
    [self.outputs addObject:output];
}

- (void)removeOutput:(AMALogOutput *)output
{
    [self.outputs removeObject:output];
}

- (void)logMessageToChannel:(AMALogChannel)channel
                      level:(AMALogLevel)level
                       file:(const char *)file
                   function:(const char *)function
                       line:(NSUInteger)line
               addBacktrace:(BOOL)addBacktrace
                     format:(NSString *)format, ...
{
    // Do nothing
}

- (NSArray *)outputsWithChannel:(AMALogChannel)channel
{
    NSMutableArray *outputs = [NSMutableArray new];
    for (AMALogOutput *output in self.outputs) {
        if ([output isMatchingChannel:channel]) {
            [outputs addObject:output];
        }
    }
    return outputs;
}

- (NSArray<AMALogOutput *> *)outputsWithMiddlewareClass:(Class)middlewareClass
{
    NSIndexSet *indxs = [self.outputs indexesOfObjectsPassingTest:^BOOL(AMALogOutput *obj, NSUInteger idx, BOOL *stop) {
        return [((NSObject *)obj.middleware) isKindOfClass:middlewareClass];
    }];
    return [self.outputs objectsAtIndexes:indxs];
}



#pragma mark - Properties

- (NSArray<AMALogOutput *> *)OSOutputs
{
    return [self outputsWithMiddlewareClass:AMAOSLogMiddleware.class];
}

- (NSArray<AMALogOutput *> *)TTYOutputs
{
    return [self outputsWithMiddlewareClass:AMATTYLogMiddleware.class];
}

- (NSArray<AMALogOutput *> *)ASLOutputs
{
    return [self outputsWithMiddlewareClass:AMAASLLogMiddleware.class];
}

#ifdef AMA_ENABLE_FILE_LOG
- (NSArray<AMALogOutput *> *)fileOutputs
{
    return [self outputsWithMiddlewareClass:AMAFileLogMiddleware.class];
}
#endif // AMA_ENABLE_FILE_LOG

@end
