
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventNameHashesStorageFactory.h"
#import "AMAEventNameHashesStorage.h"

SPEC_BEGIN(AMAEventNameHashesStorageFactoryTests)

describe(@"AMAEventNameHashesStorageFactory", ^{

    NSString *const basePath = @"/base/path";
    NSString *const apiKey = @"API_KEY";

    AMADiskFileStorage *__block fileStorage = nil;
    AMAEventNameHashesStorage *__block storage = nil;

    beforeEach(^{
        [AMAFileUtility stub:@selector(persistentPathForApiKey:) withBlock:^id(NSArray *params) {
            return [basePath stringByAppendingPathComponent:params.firstObject];
        }];
        [AMAFileUtility stub:@selector(createPathIfNeeded:)];

        fileStorage = [AMADiskFileStorage stubbedNullMockForInit:@selector(initWithPath:options:)];
        storage = [AMAEventNameHashesStorage stubbedNullMockForInit:@selector(initWithFileStorage:)];
    });

    it(@"Should create disk file storage", ^{
        AMADiskFileStorageOptions options = AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
        [[fileStorage should] receive:@selector(initWithPath:options:)
                        withArguments:@"/base/path/API_KEY/event_hashes.bin", theValue(options)];
        [AMAEventNameHashesStorageFactory storageForApiKey:apiKey];
    });
    it(@"Should create storage", ^{
        [[storage should] receive:@selector(initWithFileStorage:) withArguments:fileStorage];
        [AMAEventNameHashesStorageFactory storageForApiKey:apiKey];
    });
    it(@"Should return storage", ^{
        [[[AMAEventNameHashesStorageFactory storageForApiKey:apiKey] should] equal:storage];
    });

});

SPEC_END
