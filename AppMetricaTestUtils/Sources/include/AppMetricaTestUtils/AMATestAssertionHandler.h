
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define AMAIgnoreAssert(block) \
do {\
    AMATestAssertionHandler *ignoreHandler = [AMATestAssertionHandler new]; \
    [ignoreHandler beginAssertIgnoring]; \
    if (block != nil) \
    { \
        block(); \
    }; \
    [ignoreHandler endAssertIgnoring]; \
} while (0)


NS_SWIFT_NAME(TestAssertionHandler)
@interface AMATestAssertionHandler : NSAssertionHandler

- (void)beginAssertIgnoring;
- (void)endAssertIgnoring;

@end

NS_ASSUME_NONNULL_END
