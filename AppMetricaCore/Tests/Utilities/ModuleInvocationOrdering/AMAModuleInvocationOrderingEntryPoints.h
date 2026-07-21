#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AMAModuleEntryPoint.h>

@class AMAModuleInvocationRecorder;
@protocol AMAAdProviding;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kAMAModuleStartupForwardInvocation;
FOUNDATION_EXPORT NSString *const kAMAModuleAdProviderInvocation;

FOUNDATION_EXPORT NSString *AMAModuleInvocation(Class sourceClass, SEL selector);
FOUNDATION_EXPORT void AMAModuleInvocationOrderingConfigureRecorder(
    AMAModuleInvocationRecorder *recorder
);
FOUNDATION_EXPORT void AMAModuleInvocationOrderingReset(void);
FOUNDATION_EXPORT AMAModuleInvocationRecorder *AMAModuleInvocationOrderingRecorder(void);
FOUNDATION_EXPORT id<AMAAdProviding> _Nullable AMAModuleInvocationOrderingAdProvider(void);

@interface AMAModuleInvocationOrderingEntryPoint : NSObject <AMAModuleEntryPoint>
@end

@interface AMAModuleInvocationOrderingSecondEntryPoint : NSObject <AMAModuleEntryPoint>
@end

@interface AMAModuleInvocationOrderingPublicActivationEntryPoint : NSObject <AMAModuleEntryPoint>
@end

NS_ASSUME_NONNULL_END
