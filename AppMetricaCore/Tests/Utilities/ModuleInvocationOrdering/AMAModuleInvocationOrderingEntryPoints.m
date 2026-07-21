#import "AMAModuleInvocationOrderingEntryPoints.h"
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "../AMAEventPollingDelegateMock.h"
#import "../AMAModuleInvocationRecorder.h"
#import "../../Mocks/AMAAdProvidingMock.h"
#import "../../Mocks/AMAModuleRegistrarMocks.h"

NSString *const kAMAModuleStartupForwardInvocation = @"startup.forward";
NSString *const kAMAModuleAdProviderInvocation = @"adProvider.resolve";

static __weak AMAModuleInvocationRecorder *sModuleInvocationRecorder;
static id<AMAAdProviding> sModuleInvocationOrderingAdProvider;

NSString *AMAModuleInvocation(Class sourceClass, SEL selector)
{
    return [AMAModuleInvocationRecorder invocationNameForClass:sourceClass selector:selector];
}

void AMAModuleInvocationOrderingConfigureRecorder(AMAModuleInvocationRecorder *recorder)
{
    sModuleInvocationRecorder = recorder;
}

void AMAModuleInvocationOrderingReset(void)
{
    sModuleInvocationRecorder = nil;
    sModuleInvocationOrderingAdProvider = nil;
}

AMAModuleInvocationRecorder *AMAModuleInvocationOrderingRecorder(void)
{
    return sModuleInvocationRecorder;
}

id<AMAAdProviding> AMAModuleInvocationOrderingAdProvider(void)
{
    return sModuleInvocationOrderingAdProvider;
}

@implementation AMAModuleInvocationOrderingEntryPoint

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [sModuleInvocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    [registrar registerEventPollingDelegate:AMAEventPollingDelegateMock.class];
    [registrar registerEventFlushableDelegate:AMAEventFlushableDelegateMock.class];

    sModuleInvocationOrderingAdProvider = [AMAAdProvidingMock new];
    [registrar registerAdProvider:sModuleInvocationOrderingAdProvider];

    AMAExtendedStartupObservingMock *startupObserver = [AMAExtendedStartupObservingMock new];
    startupObserver.stubbedStartupParameters = @{ @"test" : @"value" };
    startupObserver.invocationRecorder = sModuleInvocationRecorder;
    AMAReporterStorageControllingMock *storageController = [AMAReporterStorageControllingMock new];
    storageController.invocationRecorder = sModuleInvocationRecorder;
    AMAServiceConfiguration *service = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:startupObserver
        reporterStorageController:storageController];
    [registrar registerServiceConfiguration:service];
}

@end

@implementation AMAModuleInvocationOrderingSecondEntryPoint

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [sModuleInvocationRecorder recordInvocationFromClass:self.class selector:_cmd];
}

@end

@implementation AMAModuleInvocationOrderingPublicActivationEntryPoint

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [sModuleInvocationRecorder recordInvocationFromClass:self.class selector:_cmd];
    [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
}

@end
