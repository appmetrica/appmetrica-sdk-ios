#import "AMALegacyModuleRegistrationCoordinator.h"
#import "AMAModuleRegistrarImpl.h"

typedef NS_ENUM(NSUInteger, AMALegacyModuleRegistrationCoordinatorState) {
    AMALegacyModuleRegistrationCoordinatorStateBuffering,
    AMALegacyModuleRegistrationCoordinatorStateRegistering,
    AMALegacyModuleRegistrationCoordinatorStateCompleted,
};

@interface AMALegacyModuleRegistrationCoordinator ()

@property (nonatomic) AMALegacyModuleRegistrationCoordinatorState state;
@property (nonatomic, strong) NSMutableOrderedSet<Class<AMAModuleActivationDelegate>> *pendingDelegates;
@property (nonatomic, strong) NSMutableArray<AMAServiceConfiguration *> *pendingServices;
@property (nonatomic, strong, nullable) AMAModuleRegistrarImpl *registrar;

@end

@implementation AMALegacyModuleRegistrationCoordinator

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _pendingDelegates = [NSMutableOrderedSet orderedSet];
        _pendingServices = [NSMutableArray array];
    }
    return self;
}

- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    @synchronized (self) {
        switch (self.state) {
            case AMALegacyModuleRegistrationCoordinatorStateBuffering:
                [self.pendingDelegates addObject:delegate];
                break;
            case AMALegacyModuleRegistrationCoordinatorStateRegistering:
                [self.registrar registerActivationDelegate:delegate];
                break;
            case AMALegacyModuleRegistrationCoordinatorStateCompleted:
                AMALogError(@"Ignoring legacy activation delegate registered after module registration completed: %@",
                            delegate);
                break;
        }
    }
}

- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration
{
    @synchronized (self) {
        switch (self.state) {
            case AMALegacyModuleRegistrationCoordinatorStateBuffering:
                [self.pendingServices addObject:configuration];
                break;
            case AMALegacyModuleRegistrationCoordinatorStateRegistering:
                [self.registrar registerServiceConfiguration:configuration];
                break;
            case AMALegacyModuleRegistrationCoordinatorStateCompleted:
                AMALogError(@"Ignoring legacy external service registered after module registration completed: %@",
                            configuration);
                break;
        }
    }
}

- (void)beginRegistrationWithRegistrar:(AMAModuleRegistrarImpl *)registrar
{
    @synchronized (self) {
        if (self.state != AMALegacyModuleRegistrationCoordinatorStateBuffering) {
            return;
        }
        self.state = AMALegacyModuleRegistrationCoordinatorStateRegistering;
        self.registrar = registrar;

        for (Class<AMAModuleActivationDelegate> delegate in self.pendingDelegates) {
            [registrar registerActivationDelegate:delegate];
        }
        for (AMAServiceConfiguration *configuration in self.pendingServices) {
            [registrar registerServiceConfiguration:configuration];
        }
        [self.pendingDelegates removeAllObjects];
        [self.pendingServices removeAllObjects];
    }
}

- (void)completeRegistrationWithRegistrar:(AMAModuleRegistrarImpl *)registrar
{
    @synchronized (self) {
        if (self.state == AMALegacyModuleRegistrationCoordinatorStateRegistering &&
            self.registrar == registrar) {
            self.state = AMALegacyModuleRegistrationCoordinatorStateCompleted;
            self.registrar = nil;
        }
    }
}

@end
