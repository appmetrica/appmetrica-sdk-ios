
#import <Kiwi/Kiwi.h>
#import "AMAEnvironmentContainer.h"
#import "AMAEnvironmentContainerAction.h"

SPEC_BEGIN(AMAEnvironmentContainerActionTests)

describe(@"AMAEnvironmentContainerAction", ^{

    context(@"Clear action", ^{
        let(action, ^{
            return [AMAEnvironmentContainerClearAction new];
        });

        it(@"should clear container", ^{
            AMAEnvironmentContainer *container = [AMAEnvironmentContainer new];
            [container addValue:@"foo" forKey:@"bar"];
            [action applyToContainer:container];
            NSDictionary *environment = container.dictionaryEnvironment;
            [[environment should] haveCountOf:0];
        });
    });

    context(@"Add value action", ^{
        context(@"with non-nil value", ^{
            let(action, ^{
                return [[AMAEnvironmentContainerAddValueAction alloc] initWithValue:@"foo" forKey:@"bar"];
            });

            it(@"should add value to container", ^{
                AMAEnvironmentContainer *container = [AMAEnvironmentContainer new];
                [action applyToContainer:container];
                NSDictionary *environment = container.dictionaryEnvironment;
                [[environment should] equal:@{@"bar" : @"foo"}];
            });
        });

        context(@"with nil value", ^{
            let(action, ^{
                return [[AMAEnvironmentContainerAddValueAction alloc] initWithValue:nil forKey:@"bar"];
            });

            it(@"should delete value from container", ^{
                AMAEnvironmentContainer *container = [AMAEnvironmentContainer new];
                [container addValue:@"foo" forKey:@"bar"];
                [action applyToContainer:container];
                NSDictionary *environment = container.dictionaryEnvironment;
                [[environment should] haveCountOf:0];
            });
        });
    });
});

SPEC_END
