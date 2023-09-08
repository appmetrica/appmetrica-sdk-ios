
#import "AMACrashLogging.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMASymbolsManager.h"
#import "AMASymbolsCollection.h"
#import "AMASymbolsExtractor.h"
#import "AMACrashMatchingRule.h"
#import "AMASymbolsCollectionSerializer.h"

static NSString *const kAMASymbolsManagerFileNameSeparator = @"_";

static NSUInteger const kAMADiskCacheFilesPerKeyLimit = 2;
static NSString *const kAMASymbolsFileExtension = @"symbols";

@implementation AMASymbolsManager

+ (void)registerSymbolsForApiKey:(NSString *)apiKey rule:(AMACrashMatchingRule *)rule
{
    if ([self isApiKeyValid:apiKey] == NO) {
        return;
    }

    //TODO: Crashes fixing
    AMABuildUID *builID = [AMABuildUID buildUID];
    
//    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
    AMASymbolsCollection *collection = [[self class] cachedSymbolsCollectionForKey:apiKey
                                                                          buildUID:builID];//configuration.inMemory.appBuildUID];
    if (collection == nil) {
        collection = [AMASymbolsExtractor symbolsCollectionForRule:rule];
        [[self class] cacheSymbolsCollection:collection withKey:apiKey];
    }
}

+ (AMASymbolsCollection *)symbolsCollectionForApiKey:(NSString *)apiKey buildUID:(AMABuildUID *)buildUID
{
    if ([self isApiKeyValid:apiKey] == NO || [self isBuildUIDValid:buildUID] == NO) {
        return nil;
    }

    return [self cachedSymbolsCollectionForKey:apiKey buildUID:buildUID];
}

+ (NSArray *)registeredApiKeys
{
    NSMutableSet *apiKeys = [NSMutableSet set];
    [[self class] enumerateCacheFilesWithBlock:^(NSString *apiKey, AMABuildUID *buildUID, NSString *path) {
        [apiKeys addObject:apiKey];
    }];
    return apiKeys.allObjects;
}

+ (void)cacheSymbolsCollection:(AMASymbolsCollection *)collection withKey:(NSString *)key
{
    BOOL success = NO;

    if (collection != nil) {
        
        //TODO: Crashes fixing
        AMABuildUID *builID = [AMABuildUID buildUID];
//        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
        
        NSString *cacheFile = [[self class] cacheFilePathForKey:key
                                                       buildUID:builID];// configuration.inMemory.appBuildUID];

        if (cacheFile != nil) {
            NSData *data = [AMASymbolsCollectionSerializer dataForCollection:collection];
            success = data != nil;
            if (success) {
                NSData *gzipedData = [[[AMAGZipDataEncoder alloc] init] encodeData:data error:NULL];
                success = [gzipedData writeToFile:cacheFile atomically:YES];
            }
        }
    }

    if (success == NO) {
        AMALogError(@"Failed to cache symbols with key %@", key);
    }
}

+ (void)cleanup
{
    NSDictionary *buildsByUID = [self buildsByUID];
    if (buildsByUID.count > kAMADiskCacheFilesPerKeyLimit) {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSArray *buildUIDs = [buildsByUID.allKeys sortedArrayUsingDescriptors:@[ descriptor ]];
        for (NSUInteger index = kAMADiskCacheFilesPerKeyLimit; index < buildUIDs.count; ++index) {
            NSArray *buildPaths = buildsByUID[buildUIDs[index]];
            for (NSString *filePath in buildPaths) {
                [AMAFileUtility deleteFileAtPath:filePath];
            }
        }
    }
}

+ (NSDictionary *)buildsByUID
{
    NSMutableDictionary *buildsByUID = [NSMutableDictionary dictionary];
    [self enumerateCacheFilesWithBlock:^(NSString *apiKey, AMABuildUID *buildUID, NSString *path) {
        NSMutableArray *buildPaths = buildsByUID[buildUID];
        if (buildPaths == nil) {
            buildPaths = [NSMutableArray array];
        }
        [buildPaths addObject:path];
        buildsByUID[buildUID] = buildPaths;
    }];
    return [buildsByUID copy];
}

+ (void)enumerateCacheFilesWithBlock:(void(^)(NSString *apiKey, AMABuildUID *buildUID, NSString *path))block
{
    if (block == nil) {
        return;
    }

    NSArray *cachedSymbolsFiles = [AMAFileUtility pathsForFilesWithExtension:kAMASymbolsFileExtension];
    for (NSString *filePath in cachedSymbolsFiles) {
        NSString *fileName = filePath.lastPathComponent.stringByDeletingPathExtension;
        NSArray *fileNameComponents =
            [fileName componentsSeparatedByString:kAMASymbolsManagerFileNameSeparator];

        NSString *apiKey = fileNameComponents.firstObject;
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithString:fileNameComponents.lastObject];
        if ([self isApiKeyValid:apiKey] && [self isBuildUIDValid:buildUID]) {
            block(apiKey, buildUID, filePath);
        }
    }
}

+ (AMASymbolsCollection *)cachedSymbolsCollectionForKey:(NSString *)key buildUID:(AMABuildUID *)buildUID
{
    AMASymbolsCollection *collection = nil;
    NSString *cacheFile = [[self class] cacheFilePathForKey:key buildUID:buildUID];

    if (cacheFile != nil) {
        NSData *gzipedData = [NSData dataWithContentsOfFile:cacheFile];
        if (gzipedData != nil) {
            BOOL shouldDelete = NO;
            @try {
                NSData *data = [[[AMAGZipDataEncoder alloc] init] decodeData:gzipedData error:NULL];
                collection = [AMASymbolsCollectionSerializer collectionForData:data];
                if (collection == nil) {
                    shouldDelete = YES;
                }
            }
            @catch (NSException *exception) {
                AMALogError(@"Exception during symbols cache reading: %@", exception.description);
            }
            if (shouldDelete) {
                AMALogError(@"Symbols cache for key %@ is broken and will be deleted", key);
                [AMAFileUtility deleteFileAtPath:cacheFile];
            }
        }
    }

    return collection;
}

+ (NSString *)cacheFilePathForKey:(NSString *)key buildUID:(AMABuildUID *)buildUID
{
    NSString *fileName = [NSString stringWithFormat:@"%@%@%@",
                          key, kAMASymbolsManagerFileNameSeparator, buildUID.stringValue];
    return [AMAFileUtility pathForFileName:fileName withExtension:kAMASymbolsFileExtension];
}

+ (BOOL)isApiKeyValid:(NSString *)apiKey
{
    return [AMAIdentifierValidator isValidUUIDKey:apiKey];
}

+ (BOOL)isBuildUIDValid:(AMABuildUID *)buildUID
{
    return buildUID != nil;
}

@end
