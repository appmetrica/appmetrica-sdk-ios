
#import <Kiwi/Kiwi.h>
#import "AMASymbolsManager.h"
#import "AMASymbol.h"
#import "AMASymbolsCollection.h"
#import "AMASymbolsExtractor.h"
#import "AMACrashMatchingRule.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMASymbolsCollectionSerializer.h"

@interface AMASymbolsCollection (Tests)

@property (nonatomic, copy) NSArray *symbols;

@end

SPEC_BEGIN(AMASymbolsManagerTests)

describe(@"AMASymbolsManager", ^{

    AMAGZipDataEncoder *__block gzipEncoder = nil;
    AMASymbolsCollection *__block cachedCollection = nil;

    beforeEach(^{
        cachedCollection = nil;
        gzipEncoder = [AMAGZipDataEncoder stubbedNullMockForDefaultInit];

        NSData *unarchivedDataMock = [NSData nullMock];
        [NSData stub:@selector(dataWithContentsOfFile:) andReturn:unarchivedDataMock];
        [gzipEncoder stub:@selector(decodeData:error:)];
        [AMASymbolsCollectionSerializer stub:@selector(collectionForData:) withBlock:^id(NSArray *params) {
            return cachedCollection;
        }];

        [AMASymbolsCollectionSerializer stub:@selector(dataForCollection:) withBlock:^id(NSArray *params) {
            cachedCollection = params[0];
            return [NSData nullMock];
        }];
        NSData *archivedDataMock = [NSData nullMock];
        [archivedDataMock stub:@selector(writeToFile:atomically:) andReturn:theValue(YES)];
        [gzipEncoder stub:@selector(encodeData:error:) andReturn:archivedDataMock];
    });

    context(@"Register symbols", ^{

        NSString *apiKey = @"d75e6650-ed1f-4acf-ac66-370f1ad77068";
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithDate:[NSDate date]];
        AMACrashMatchingRule *__block matchingRule = nil;

        beforeEach(^{
            [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
            [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appBuildUID) andReturn:buildUID];
            matchingRule = [AMACrashMatchingRule nullMock];
        });

        it(@"Should extract not cached symbols", ^{
            KWCaptureSpy *spy = [AMASymbolsExtractor captureArgument:@selector(symbolsCollectionForRule:)
                                                             atIndex:0];

            [AMASymbolsManager registerSymbolsForApiKey:apiKey rule:matchingRule];
            [[spy.argument should] equal:matchingRule];
        });

        it(@"Should not extract symbols with invalid API key", ^{
            [[AMASymbolsExtractor shouldNot] receive:@selector(symbolsCollectionForRule:)];
            [AMASymbolsManager registerSymbolsForApiKey:@"12345" rule:matchingRule];
        });

        it(@"Should not extract cached symbols", ^{
            cachedCollection = [KWMock nullMockForClass:[AMASymbolsCollection class]];

            [[AMASymbolsExtractor shouldNot] receive:@selector(symbolsCollectionForRule:)];
            [AMASymbolsManager registerSymbolsForApiKey:apiKey rule:matchingRule];
        });

        it(@"Should return nil collection for nil buildUID", ^{
            AMASymbolsCollection *collection = [AMASymbolsManager symbolsCollectionForApiKey:apiKey buildUID:nil];
            [[collection should] beNil];
        });

        it(@"Should return nil collection for nil key", ^{
            AMASymbolsCollection *collection = [AMASymbolsManager symbolsCollectionForApiKey:nil buildUID:buildUID];
            [[collection should] beNil];
        });

        it(@"Should cleanup old disk cache", ^{
            NSArray *oldFiles = @[
                [NSString stringWithFormat:@"%@_1", apiKey],
                [NSString stringWithFormat:@"%@_2", apiKey],
                @"0161f3ee-93c8-465e-8665-29723d5ab02b_1",
                @"0161f3ee-93c8-465e-8665-29723d5ab02b_2"
            ];
            NSArray *actualFiles = @[
                [NSString stringWithFormat:@"%@_3", apiKey],
                [NSString stringWithFormat:@"%@_4", apiKey],
            ];
            NSMutableArray *files = [NSMutableArray array];
            [files addObjectsFromArray:oldFiles];
            [files addObjectsFromArray:actualFiles];
            [AMAFileUtility stub:@selector(pathsForFilesWithExtension:) andReturn:[files copy]];

            NSMutableArray *deletedFiles = [NSMutableArray array];
            [AMAFileUtility stub:@selector(deleteFileAtPath:) withBlock:^id(NSArray *params) {
                NSString *filePath = params.firstObject;
                if (filePath != nil) {
                    [deletedFiles addObject:filePath];
                }
                return nil;
            }];

            [AMASymbolsManager cleanup];
            [[[deletedFiles copy] should] containObjectsInArray:oldFiles];
        });

        it(@"Should list only valid API keys", ^{
            NSArray *invalidFiles = @[
                @"1234_1",
                @"_2"
            ];
            NSArray *validFiles = @[
                [NSString stringWithFormat:@"%@_3", apiKey],
            ];
            NSMutableArray *files = [NSMutableArray array];
            [files addObjectsFromArray:invalidFiles];
            [files addObjectsFromArray:validFiles];
            [AMAFileUtility stub:@selector(pathsForFilesWithExtension:) andReturn:[files copy]];
            
            NSArray *apiKeys = [AMASymbolsManager registeredApiKeys];
            [[apiKeys should] equal:@[ apiKey ]];
        });

        context(@"After symbols registered", ^{
            NSArray *symbols = @[ [AMASymbol nullMock] ];
            NSString *apiKey = @"d75e6650-ed1f-4acf-ac66-370f1ad77068";

            beforeEach(^{
                AMACrashMatchingRule *rule = [AMACrashMatchingRule nullMock];
                AMASymbolsCollection *collection = [[AMASymbolsCollection alloc] initWithSymbols:symbols
                                                                                          images:nil
                                                                              dynamicBinaryNames:nil];
                [AMASymbolsExtractor stub:@selector(symbolsCollectionForRule:)
                                andReturn:collection
                            withArguments:rule];

                [AMASymbolsManager registerSymbolsForApiKey:apiKey rule:rule];
            });

            it(@"Should return extracted symbols", ^{
                AMASymbolsCollection *collection = [AMASymbolsManager symbolsCollectionForApiKey:apiKey
                                                                                        buildUID:buildUID];
                [[collection.symbols should] equal:symbols];
            });

            it(@"Should cache extracted symbols", ^{
                [[cachedCollection.symbols should] equal:symbols];
            });

        });

    });

});

SPEC_END
