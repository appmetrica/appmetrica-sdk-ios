
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAFileUtilityTests)

describe(@"AMAFileUtility", ^{

    NSString *const basePath = @"/tmp/path";

    NSFileManager *__block fileManager = nil;
    NSFileManager *__block originalFileManager = nil;

    beforeEach(^{
        fileManager = [NSFileManager nullMock];
        originalFileManager = [NSFileManager defaultManager];
        [NSFileManager stub:@selector(defaultManager) andReturn:fileManager];
    });
    afterEach(^{
        [NSFileManager clearStubs];
    });

    context(@"Paths for files with extension", ^{

        NSString *extension = @"txt";

        NSArray *validFiles = @[ @"a.txt", @"b.txt" ];
        NSArray *files = [validFiles arrayByAddingObjectsFromArray:@[ @"c.xml", @"d" ]];
        NSArray *fileURLs = [AMACollectionUtilities mapArray:files withBlock:^id(NSString *fileName) {
            NSString *filePath = [basePath stringByAppendingPathComponent:fileName];
            return [NSURL fileURLWithPath:filePath];
        }];

        beforeEach(^{
            [AMAFileUtility stub:@selector(cacheDirectoryPath) andReturn:basePath];
            NSArray *fileURLsMock = [NSArray nullMock];
            [fileURLsMock stub:@selector(sortedArrayUsingComparator:) andReturn:fileURLs];
            [fileManager stub:@selector(contentsOfDirectoryAtURL:includingPropertiesForKeys:options:error:)
                    andReturn:fileURLsMock];
        });
        afterEach(^{
            [AMAFileUtility clearStubs];
        });

        it(@"Should return valid paths", ^{
            NSArray *paths = [AMAFileUtility pathsForFilesWithExtension:extension];

            NSArray *validPaths = [AMACollectionUtilities mapArray:validFiles withBlock:^id(NSString *fileName) {
                return [basePath stringByAppendingPathComponent:fileName];
            }];
            [[paths should] containObjectsInArray:validPaths];
        });

        it(@"Should return absolute paths", ^{
            NSArray *paths = [AMAFileUtility pathsForFilesWithExtension:extension];

            [[theValue([paths.firstObject hasPrefix:basePath]) should] beYes];
        });

    });

    context(@"File exists", ^{
        it(@"Should pass path", ^{
            [[fileManager should] receive:@selector(fileExistsAtPath:) withArguments:basePath];
            [AMAFileUtility fileExistsAtPath:basePath];
        });
        it(@"Should return YES if so", ^{
            [fileManager stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
            [[theValue([AMAFileUtility fileExistsAtPath:basePath]) should] beYes];
        });
        it(@"Should return NO if so", ^{
            [fileManager stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
            [[theValue([AMAFileUtility fileExistsAtPath:basePath]) should] beNo];
        });
    });

    context(@"Skip backup flag", ^{
        NSString *const excludeItemKey = @"com.apple.metadata:com_apple_backup_excludeItem";
        NSData *const excludeItemData = [@"com.apple.MobileBackup" dataUsingEncoding:NSASCIIStringEncoding];
        NSDictionary *const expectedExtendedAttributes = @{ excludeItemKey : excludeItemData };

        NSString *__block tempFilePath = nil;
        beforeEach(^{
            fileManager = nil;
            [NSFileManager clearStubs];

            tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
            [originalFileManager removeItemAtPath:tempFilePath error:NULL];
            
            [[@"DATA" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tempFilePath atomically:YES];
        });
        afterEach(^{
            [originalFileManager removeItemAtPath:tempFilePath error:NULL];
        });

        it(@"Should not have attribute before", ^{
            NSDictionary *attributes = [originalFileManager attributesOfItemAtPath:tempFilePath error:NULL];
            NSDictionary *extendedAttributes = attributes[@"NSFileExtendedAttributes"];
            
            [[extendedAttributes[excludeItemKey] should] beNil];
        });

        it(@"Should have valid attribute", ^{
            [AMAFileUtility setSkipBackupAttributesOnPath:tempFilePath];
            NSDictionary *attributes = [originalFileManager attributesOfItemAtPath:tempFilePath error:NULL];
            NSDictionary *extendedAttributes = attributes[@"NSFileExtendedAttributes"];
            
            [[extendedAttributes[excludeItemKey] should] equal:excludeItemData];
        });
        
        it(@"Should preserve attributes while writing files", ^{
            [AMAFileUtility setSkipBackupAttributesOnPath:tempFilePath];
            NSDictionary *attributesBefore = [originalFileManager attributesOfItemAtPath:tempFilePath error:NULL];
            [AMAFileUtility writeString:@"Test" filePath:tempFilePath error:NULL];
            NSDictionary *attributesAfter = [originalFileManager attributesOfItemAtPath:tempFilePath error:NULL];
            
            [[attributesBefore[@"NSFileExtendedAttributes"] should] equal:attributesAfter[@"NSFileExtendedAttributes"]];
        });
    });
    
    context(@"Shared Group", ^{
        NSURL *containerURL = [NSURL fileURLWithPath:@"/test/container"];
        beforeEach(^{
            [fileManager stub:@selector(containerURLForSecurityApplicationGroupIdentifier:) andReturn:containerURL];
        });
        
        it(@"Should return path to group container", ^{
            NSString *groupIDPath = [AMAFileUtility persistentPathForApplicationGroup:@"group.io.appmetrica.test"];
            [[groupIDPath should] equal:@"/test/container/io.appmetrica"];
        });
    });

});

SPEC_END
