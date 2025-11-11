
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAHostStateControllerFactory.h"
#import "AMAExtensionHostStateProvider.h"
#import "AMAApplicationHostStateProvider.h"

SPEC_BEGIN(AMAHostStateControllerFactoryTests)

describe(@"AMAHostStateControllerFactory", ^{

    AMAHostStateControllerFactory *__block factory = nil;
    NSBundle *__block bundle = [NSBundle mainBundle];
    
    it(@"App host state", ^{
        [bundle stub:@selector(executablePath) andReturn:@".app"];
        factory = [[AMAHostStateControllerFactory alloc] initWithBundle:bundle];
        
        id<AMAHostStateControlling> hostStateController = [factory hostStateController];
        
        [[hostStateController.class should] equal:AMAApplicationHostStateProvider.class];
    });
    
    it(@"Extension host state", ^{
        [bundle stub:@selector(executablePath) andReturn:@".appex"];
        factory = [[AMAHostStateControllerFactory alloc] initWithBundle:bundle];
        
        id<AMAHostStateControlling> hostStateController = [factory hostStateController];
        
        [[hostStateController.class should] equal:AMAExtensionHostStateProvider.class];
    });
});

SPEC_END
