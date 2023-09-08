
#import <Kiwi/Kiwi.h>
#import "AMAEnvironmentContainerActionRedoManager.h"
#import "AMAEnvironmentContainerActionHistory.h"
#import "AMAEnvironmentContainer.h"

SPEC_BEGIN(AMAEnvironmentContainerActionRedoManagerTests)

describe(@"AMAEnvironmentContainerActionRedoManager", ^{
    let(manager, ^{
        return [AMAEnvironmentContainerActionRedoManager new];
    });

    let(container, ^{
       return [AMAEnvironmentContainer new];
    });

    let(history, ^{
        AMAEnvironmentContainerActionHistory *history = [AMAEnvironmentContainerActionHistory new];
        [history trackAddValue:@"foo" forKey:@"bar"];
        [history trackClearEnvironment];
        [history trackAddValue:@"buzz" forKey:@"qux"];
        return history;
    });

    it(@"should redo action history in container", ^{
        [manager redoHistory:history inContainer:container];

        NSDictionary *environment = container.dictionaryEnvironment;
        [[environment should] equal:@{@"qux" : @"buzz"}];
    });

    it(@"should redo history in batch updates", ^{
        __block NS_VALID_UNTIL_END_OF_SCOPE id observer = [KWMock nullMock];
        __block NSUInteger notifyCounter = 0;
        [container addObserver:observer withBlock:^(id o, AMAEnvironmentContainer *environment) {
            ++notifyCounter;
        }];

        [manager redoHistory:history inContainer:container];

        [[theValue(notifyCounter) should] equal:@(1)];
    });
});

SPEC_END
