
#import <Kiwi/Kiwi.h>
#import "AMAEnvironmentContainer.h"
#import "AMAEnvironmentLimiter.h"

@interface AMAEnvironmentContainer ()

- (instancetype)initWithDictionaryEnvironment:(nullable NSDictionary *)dictionaryEnvironment
                                      limiter:(AMAEnvironmentLimiter *)limiter;

@end

SPEC_BEGIN(AMAEnvironmentContainerTests)

describe(@"AMAEnvironmentContainer", ^{
    context(@"with appropriate limit", ^{
        let(container, ^{
            AMAEnvironmentLimiter *limiter = [AMAEnvironmentLimiter nullMock];
            [limiter stub:@selector(limitEnvironment:afterAddingValue:forKey:) withBlock:^id(NSArray *params) {
                NSMutableDictionary *environment = [(params[0] ?: @{}) mutableCopy];
                environment[params[2]] = params[1];
                return [environment copy];
            }];
            return [[AMAEnvironmentContainer alloc] initWithDictionaryEnvironment:nil limiter:limiter];
        });

        it(@"should store value", ^{
            [container addValue:@"fizz" forKey:@"buzz"];
            NSDictionary *environment = container.dictionaryEnvironment;
            [[environment[@"buzz"] should] equal:@"fizz"];
        });

        it(@"should remove stored value", ^{
            [container addValue:nil forKey:@"buzz"];
            NSDictionary *environment = container.dictionaryEnvironment;
            [environment[@"buzz"] shouldBeNil];
        });
        
        it(@"should add empty value", ^{
            [container addValue:@"" forKey:@"buzz"];
            NSDictionary *environment = container.dictionaryEnvironment;
            [[environment[@"buzz"] should] equal:@""];
        });

        it(@"should not throw on nil key", ^{
            [[theBlock(^{
                #pragma clang diagnostic push 
                #pragma clang diagnostic ignored "-Wnonnull" 
                [container addValue:@"fizz" forKey:nil];
                #pragma clang diagnostic pop
            }) shouldNot] raise];
        });
    });

    context(@"with off the limit", ^{
        let(container, ^{
            AMAEnvironmentLimiter *limiter = [AMAEnvironmentLimiter nullMock];
            [limiter stub:@selector(limitEnvironment:afterAddingValue:forKey:) andReturn:nil];
            return [[AMAEnvironmentContainer alloc] initWithDictionaryEnvironment:nil limiter:limiter];
        });

        it(@"shouldn't store value", ^{
            [container addValue:@"fizz" forKey:@"buzz"];
            NSDictionary *environment = container.dictionaryEnvironment;
            [environment[@"buzz"] shouldBeNil];
        });
    });

    context(@"by default", ^{
        let(container, ^{
            return [AMAEnvironmentContainer new];
        });

        it(@"should clean its storage", ^{
            [container addValue:@"fizz" forKey:@"buzz"];
            [container clearEnvironment];
            NSDictionary *environment = container.dictionaryEnvironment;
            [environment[@"buzz"] shouldBeNil];
        });
    });

    context(@"with observer", ^{
        __block AMAEnvironmentContainer *container = nil;
        __block id observer = nil;
        beforeEach(^{
            observer = [KWMock nullMock];
            container = [AMAEnvironmentContainer new];
        });

        it(@"should notify observer on change", ^{
            __block BOOL isNotified = NO;
            [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                isNotified = YES;
            }];
            [[theValue(isNotified) should] beNo];
            [container addValue:@"fizz" forKey:@"buzz"];
            [[theValue(isNotified) should] beYes];
        });

        it(@"should notify delegate on clean", ^{
            [container addValue:@"fizz" forKey:@"buzz"];

            __block BOOL isNotified = NO;
            [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                isNotified = YES;
            }];
            [[theValue(isNotified) should] beNo];
            [container clearEnvironment];
            [[theValue(isNotified) should] beYes];
        });

        it(@"should notify right delegate", ^{
            [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                [[o should] equal:observer];
            }];
            [container addValue:@"fizz" forKey:@"buzz"];
        });

        it(@"should unregister observer", ^{
            __block BOOL isNotified = NO;
            [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                isNotified = YES;
            }];
            [container removeObserver:observer];
            [container addValue:@"fizz" forKey:@"buzz"];
            [[theValue(isNotified) should] beNo];
        });

        context(@"in batch updates", ^{
            it(@"should notify delegate on change", ^{
                __block BOOL isNotified = NO;
                [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                    isNotified = YES;
                }];
                [container performBatchUpdates:^{
                    [container addValue:@"fizz" forKey:@"buzz"];
                }];
                [[theValue(isNotified) should] beYes];
            });

            it(@"should notify delegate only once", ^{
                __block NSUInteger notifyCounter = 0;
                [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                    ++notifyCounter;
                }];
                [container performBatchUpdates:^{
                    [container addValue:@"fizz" forKey:@"buzz"];
                    [container addValue:@"foo" forKey:@"bar"];
                }];
                [[theValue(notifyCounter) should] equal:@(1)];
            });

            it(@"shouldn't notify delegate if nothing changes", ^{
                __block BOOL isNotified = NO;
                [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                    isNotified = YES;
                }];
                [container performBatchUpdates:^{
                }];
                [[theValue(isNotified) should] beNo];
            });

            it(@"should keep notify observers after batch update", ^{
                __block BOOL isNotified = NO;
                [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
                    isNotified = YES;
                }];
                [container performBatchUpdates:^{
                }];
                [container addValue:@"foo" forKey:@"bar"];
                [[theValue(isNotified) should] beYes];
            });
        });
    });
});

SPEC_END
