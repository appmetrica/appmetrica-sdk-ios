
#import "AMAIDSyncLoader.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncStartupRequestParameters.h"
#import "AMAIDSyncStartupResponseParser.h"
#import "AMAIDSyncStartupResponse.h"
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncManager.h"

@interface AMAIDSyncLoader ()

@property (nonatomic, strong) AMAIDSyncManager *idSyncManager;

@end

@implementation AMAIDSyncLoader

- (instancetype)init
{
    self = [super init];
    if (self) {
        _idSyncManager = [[AMAIDSyncManager alloc] init];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static AMAIDSyncLoader *idSyncLoader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        idSyncLoader = [AMAIDSyncLoader new];
    });
    return idSyncLoader;
}

+ (void)load
{
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
                                       initWithStartupObserver:[AMAIDSyncStartupController sharedInstance]
                                       reporterStorageController:[AMAIDSyncStartupController sharedInstance]
    ];
    [AMAAppMetrica registerExternalService:config];
}

// TODO: Refactor startup update handling later
- (void)start
{
    [self.idSyncManager startupUpdatedWithConfiguration:[AMAIDSyncStartupController sharedInstance].startup];
}

@end
