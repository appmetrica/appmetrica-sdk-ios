#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAAppMetricaConfigurationStorageFactory.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppGroupIdentifierProvider.h"

@import AppMetricaSynchronization;

SPEC_BEGIN(AMAAppMetricaConfigurationStorageFactoryTests)

describe(@"AMAAppMetricaConfigurationStorageFactory", ^{

    NSString *const kPrivatePath = @"/private/persistent/path";
    NSString *const kGroupPath   = @"/group/persistent/path";
    NSString *const kAppGroupID  = @"group.io.appmetrica.test";
    NSString *const kFileName    = @"configuration.json";
    NSString *const kLockFileName = @"configuration.lock";
    AMADiskFileStorageOptions const kExpectedOptions =
        AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;

    AMAAppGroupIdentifierProvider *__block providerMock = nil;
    AMAAppMetricaConfigurationStorageCoordinator *__block coordinatorMock = nil;
    AMAFileLockExecutor *__block lockMock = nil;

    beforeEach(^{
        providerMock = [AMAAppGroupIdentifierProvider nullMock];
        [AMAAppGroupIdentifierProvider stub:@selector(sharedInstance) andReturn:providerMock];

        [AMAFileUtility stub:@selector(persistentPath) andReturn:kPrivatePath];
        [AMAFileUtility stub:@selector(persistentPathForApplicationGroup:) andReturn:kGroupPath];

        coordinatorMock = [AMAAppMetricaConfigurationStorageCoordinator
            stubbedNullMockForInit:@selector(initWithPrivateStorage:groupStorage:lock:)];
        lockMock = [AMAFileLockExecutor stubbedNullMockForInit:@selector(initWithFilePath:)];
    });

    afterEach(^{
        [AMAAppGroupIdentifierProvider clearStubs];
        [AMAFileUtility clearStubs];
        [AMAAppMetricaConfigurationStorageCoordinator clearStubs];
        [AMAFileLockExecutor clearStubs];
    });

    context(@"creating", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];
        });

        it(@"should return an object conforming to AMAAppMetricaConfigurationStoring", ^{
            id<AMAAppMetricaConfigurationStoring> storage =
                [AMAAppMetricaConfigurationStorageFactory configurationStorage];

            [[(NSObject *)storage shouldNot] beNil];
            [[(NSObject *)storage should] conformToProtocol:@protocol(AMAAppMetricaConfigurationStoring)];
        });

        it(@"should return AMAAppMetricaConfigurationStorageCoordinator", ^{
            id result = [AMAAppMetricaConfigurationStorageFactory configurationStorage];
            [[(NSObject *)result should] equal:coordinatorMock];
        });
    });

    it(@"should build private storage with the correct file path", ^{
        [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];

        NSString *expectedPath = [NSString stringWithFormat:@"%@/%@", kPrivatePath, kFileName];
        [[AMADiskFileStorage should] receive:@selector(diskFileStorageWithPath:options:)
                               withArguments:expectedPath, theValue(kExpectedOptions)];

        [AMAAppMetricaConfigurationStorageFactory configurationStorage];
    });

    context(@"when appGroupIdentifier is nil", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];
        });

        it(@"should pass nil as groupStorage to coordinator", ^{
            [[coordinatorMock should] receive:@selector(initWithPrivateStorage:groupStorage:lock:)
                                withArguments:kw_any(), nil, kw_any()];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should create lock in private directory", ^{
            NSString *expectedLockPath = [NSString stringWithFormat:@"%@/%@", kPrivatePath, kLockFileName];
            [[lockMock should] receive:@selector(initWithFilePath:) withArguments:expectedLockPath];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });
    });

    context(@"when appGroupIdentifier is set", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:kAppGroupID];
        });

        it(@"should build group storage with the correct file path", ^{
            NSString *expectedPath = [NSString stringWithFormat:@"%@/%@", kGroupPath, kFileName];
            [[AMADiskFileStorage should] receive:@selector(diskFileStorageWithPath:options:)
                                   withArguments:expectedPath, theValue(kExpectedOptions)];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should create lock in group directory", ^{
            NSString *expectedLockPath = [NSString stringWithFormat:@"%@/%@", kGroupPath, kLockFileName];
            [[lockMock should] receive:@selector(initWithFilePath:) withArguments:expectedLockPath];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should pass non-nil groupStorage to coordinator", ^{
            [[coordinatorMock should] receive:@selector(initWithPrivateStorage:groupStorage:lock:)
                                withArguments:kw_any(), kw_any(), kw_any()];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });
    });

    it(@"should pass an AMAAppMetricaConfigurationFileStorage as privateStorage", ^{
        [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];

        __block id capturedPrivateStorage = nil;
        [coordinatorMock stub:@selector(initWithPrivateStorage:groupStorage:lock:)
                    withBlock:^id(NSArray *params) {
            capturedPrivateStorage = params[0];
            return coordinatorMock;
        }];

        [AMAAppMetricaConfigurationStorageFactory configurationStorage];

        [[(NSObject *)capturedPrivateStorage should] beKindOfClass:[AMAAppMetricaConfigurationFileStorage class]];
    });
});

SPEC_END
