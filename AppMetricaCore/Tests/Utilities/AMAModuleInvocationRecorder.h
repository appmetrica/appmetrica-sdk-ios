#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleInvocationRecorder : NSObject

@property (nonatomic, copy, readonly) NSArray<NSString *> *invocations;

+ (NSString *)invocationNameForClass:(Class)sourceClass selector:(SEL)selector;

- (void)recordInvocationFromClass:(Class)sourceClass selector:(SEL)selector;
- (void)recordInvocationWithName:(NSString *)name;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
