#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAAppMetricaConfigurationStorageFactory.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppGroupIdentifierProvider.h"

SPEC_BEGIN(AMAAppMetricaConfigurationStorageFactoryTests)

describe(@"AMAAppMetricaConfigurationStorageFactory", ^{

    NSString *const kPrivatePath = @"/private/persistent/path";
    NSString *const kGroupPath   = @"/group/persistent/path";
    NSString *const kAppGroupID  = @"group.io.appmetrica.test";
    NSString *const kFileName    = @"configuration.json";

    AMAAppGroupIdentifierProvider *__block providerMock = nil;

    AMAAppMetricaConfigurationStorageCoordinator *__block coordinatorMock    = nil;

    beforeEach(^{
        // Stub AMAAppGroupIdentifierProvider.sharedInstance
        providerMock = [AMAAppGroupIdentifierProvider nullMock];
        [AMAAppGroupIdentifierProvider stub:@selector(sharedInstance) andReturn:providerMock];

        // Stub AMAFileUtility paths
        [AMAFileUtility stub:@selector(persistentPath) andReturn:kPrivatePath];
        [AMAFileUtility stub:@selector(persistentPathForApplicationGroup:) andReturn:kGroupPath];

        // Capture coordinator alloc/init so we can inspect arguments
        coordinatorMock = [AMAAppMetricaConfigurationStorageCoordinator stubbedNullMockForInit:@selector(initWithPrivateStorage:groupStorage:)];
    });

    afterEach(^{
        [AMAAppGroupIdentifierProvider clearStubs];
        [AMAFileUtility clearStubs];
        [AMAAppMetricaConfigurationStorageCoordinator clearStubs];
    });

    // MARK: - Return type
    
    context(@"creating", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];
        });
        
        it(@"should return an object conforming to AMAAppMetricaConfigurationStoring", ^{
            id<AMAAppMetricaConfigurationStoring> storage = [AMAAppMetricaConfigurationStorageFactory configurationStorage];

            [[(NSObject *)storage shouldNot] beNil];
            [[(NSObject *)storage should] conformToProtocol:@protocol(AMAAppMetricaConfigurationStoring)];
        });

        it(@"should return AMAAppMetricaConfigurationStorageCoordinator", ^{
            id result = [AMAAppMetricaConfigurationStorageFactory configurationStorage];

            [[(NSObject *)result should] equal:coordinatorMock];
        });
    });

    // MARK: - Private storage path

    it(@"should build private storage with the correct file path", ^{
        [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];

        NSString *expectedPath = [NSString stringWithFormat:@"%@/%@", kPrivatePath, kFileName];

        AMADiskFileStorage *capturedStorage = nil;
        [[coordinatorMock should] receive:@selector(initWithPrivateStorage:groupStorage:)
                            withArguments:kw_any(), kw_any()];

        // Capture via a block stub on AMADiskFileStorage
        AMADiskFileStorage *diskStorageMock = [AMADiskFileStorage stubbedNullMockForInit:@selector(diskFileStorageWithPath:options:)];
        
        [[AMADiskFileStorage should] receive:@selector(diskFileStorageWithPath:options:)
                               withArguments:expectedPath, theValue(AMADiskFileStorageOptionNoBackup)];

        [AMAAppMetricaConfigurationStorageFactory configurationStorage];
    });

    // MARK: - Without app group

    context(@"when appGroupIdentifier is nil", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];
        });

        it(@"should pass nil as groupStorage to coordinator", ^{
            [[coordinatorMock should] receive:@selector(initWithPrivateStorage:groupStorage:)
                                withArguments:kw_any(), nil];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should not call persistentPathForApplicationGroup:", ^{
            [[AMAFileUtility shouldNot] receive:@selector(persistentPathForApplicationGroup:)];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });
    });

    // MARK: - With app group

    context(@"when appGroupIdentifier is set", ^{
        beforeEach(^{
            [providerMock stub:@selector(appGroupIdentifier) andReturn:kAppGroupID];
        });

        it(@"should call persistentPathForApplicationGroup: with the group identifier", ^{
            [[AMAFileUtility should] receive:@selector(persistentPathForApplicationGroup:)
                               withArguments:kAppGroupID];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should build group storage with the correct file path", ^{
            NSString *expectedPath = [NSString stringWithFormat:@"%@/%@", kGroupPath, kFileName];

            [[AMADiskFileStorage should] receive:@selector(diskFileStorageWithPath:options:)
                                   withArguments:expectedPath, theValue(AMADiskFileStorageOptionNoBackup)];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should pass non-nil groupStorage to coordinator", ^{
            [[coordinatorMock should] receive:@selector(initWithPrivateStorage:groupStorage:)
                                withArguments:kw_any(), kw_any()];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];
        });

        it(@"should pass an AMAAppMetricaConfigurationFileStorage as groupStorage", ^{
            __block id capturedGroupStorage = nil;

            [coordinatorMock stub:@selector(initWithPrivateStorage:groupStorage:)
                        withBlock:^id(NSArray *params) {
                capturedGroupStorage = params[1];
                return coordinatorMock;
            }];

            [AMAAppMetricaConfigurationStorageFactory configurationStorage];

            [[(NSObject *)capturedGroupStorage should] beKindOfClass:[AMAAppMetricaConfigurationFileStorage class]];
        });
    });

    // MARK: - Private storage type

    it(@"should pass an AMAAppMetricaConfigurationFileStorage as privateStorage", ^{
        [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];

        __block id capturedPrivateStorage = nil;

        [coordinatorMock stub:@selector(initWithPrivateStorage:groupStorage:)
                    withBlock:^id(NSArray *params) {
            capturedPrivateStorage = params[0];
            return coordinatorMock;
        }];

        [AMAAppMetricaConfigurationStorageFactory configurationStorage];

        [[(NSObject *)capturedPrivateStorage should] beKindOfClass:[AMAAppMetricaConfigurationFileStorage class]];
    });

    // MARK: - Private storage options

    it(@"should create private disk storage with NoBackup option", ^{
        [providerMock stub:@selector(appGroupIdentifier) andReturn:nil];

        [[AMADiskFileStorage should] receive:@selector(diskFileStorageWithPath:options:)
                               withArguments:kw_any(), theValue(AMADiskFileStorageOptionNoBackup)];

        [AMAAppMetricaConfigurationStorageFactory configurationStorage];
    });
});

SPEC_END
