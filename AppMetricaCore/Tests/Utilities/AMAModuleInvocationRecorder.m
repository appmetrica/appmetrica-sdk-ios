#import "AMAModuleInvocationRecorder.h"

@interface AMAModuleInvocationRecorder ()

@property (nonatomic, strong) NSMutableArray<NSString *> *mutableInvocations;

@end


@implementation AMAModuleInvocationRecorder

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _mutableInvocations = [NSMutableArray array];
    }
    return self;
}

+ (NSString *)invocationNameForClass:(Class)sourceClass selector:(SEL)selector
{
    return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(sourceClass), NSStringFromSelector(selector)];
}

- (NSArray<NSString *> *)invocations
{
    @synchronized (self) {
        return [self.mutableInvocations copy];
    }
}

- (void)recordInvocationFromClass:(Class)sourceClass selector:(SEL)selector
{
    [self recordInvocationWithName:[self.class invocationNameForClass:sourceClass selector:selector]];
}

- (void)recordInvocationWithName:(NSString *)name
{
    @synchronized (self) {
        [self.mutableInvocations addObject:[name copy]];
    }
}

- (void)reset
{
    @synchronized (self) {
        [self.mutableInvocations removeAllObjects];
    }
}

@end
