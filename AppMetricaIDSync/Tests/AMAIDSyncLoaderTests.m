
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAIDSyncLoader.h"
#import "AMAIDSyncManager.h"
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncStartupConfiguration.h"

@interface AMAIDSyncLoader ()
@property (nonatomic, strong) AMAIDSyncManager *idSyncManager;
@end

SPEC_BEGIN(AMAIDSyncLoaderTests)

describe(@"AMAIDSyncLoader", ^{
    
    AMAIDSyncLoader *__block loader = nil;
    AMAIDSyncManager *__block manager = nil;
    AMAIDSyncStartupController *__block startupController = nil;
    
    beforeEach(^{
        loader = [[AMAIDSyncLoader alloc] init];
        manager = [AMAIDSyncManager nullMock];
        startupController = [AMAIDSyncStartupController nullMock];
        
        [AMAIDSyncStartupController stub:@selector(sharedInstance) andReturn:startupController];
        [loader stub:@selector(idSyncManager) andReturn:manager];
    });

    
    context(@"Load", ^{
        AMAServiceConfiguration *__block moduleConfiguration = nil;
        
        beforeEach(^{
            moduleConfiguration = [AMAServiceConfiguration stubbedNullMockForInit:@selector(initWithStartupObserver:
                                                                                            reporterStorageController:)];
        });
        
        it(@"Should register on load", ^{
            [[AMAAppMetrica should] receive:@selector(registerExternalService:) withArguments:moduleConfiguration];
            [[moduleConfiguration should] receive:@selector(initWithStartupObserver:reporterStorageController:)
                                    withArguments:startupController, startupController];
            
            [AMAIDSyncLoader load];
        });
    });
    
    context(@"id sync", ^{
        AMAIDSyncStartupConfiguration *__block startupConfiguration = nil;
        
        beforeEach(^{
            [startupController stub:@selector(startup)];
        });
        
        it(@"Should start with configuration", ^{
            [[manager should] receive:@selector(startupUpdatedWithConfiguration:) withArguments:startupConfiguration];
            
            [loader start];
        });
    });
});

SPEC_END
