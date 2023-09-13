
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAUUIDProvider.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseFactory.h"
#import "AMACore.h"

SPEC_BEGIN(AMAUUIDProviderTests)

describe(@"AMAUUIDProvider", ^{

    NSString *oldUUIDDatabasePath = @"some/path";
    AMAUUIDProvider *__block provider;
    beforeEach(^{
        provider = [[AMAUUIDProvider alloc] init];
    });
    context(@"Shared instance", ^{
        beforeEach(^{
            provider = [AMAUUIDProvider sharedInstance];
        });
        it (@"Should not be nil", ^{
            [[provider shouldNot] beNil];
        });
        it (@"Should be the same for second time", ^{
            [[[AMAUUIDProvider sharedInstance] should] equal:provider];
        });
    });
    context(@"Retrieve UUID", ^{

        AMAInstantFeaturesConfiguration *__block instantConfiguration = nil;
        id __block uuidOldStorage = nil;
        AMAMetricaConfiguration *__block configuration;
        beforeEach(^{
            configuration = [AMAMetricaConfiguration nullMock];
            instantConfiguration = [AMAInstantFeaturesConfiguration nullMock];
            uuidOldStorage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
            [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
            [AMAInstantFeaturesConfiguration stub:@selector(sharedInstance) andReturn:instantConfiguration];
            [configuration stub:@selector(UUIDOldStorage) andReturn:uuidOldStorage];
            [AMADatabaseFactory stub:@selector(configurationDatabasePath) andReturn:oldUUIDDatabasePath];
        });

        context(@"Has cached UUID", ^{
            NSString *__block cachedUUID = nil;
            beforeEach(^{
                cachedUUID = provider.retrieveUUID;
            });
            it(@"Next uuid should be the same", ^{
                [[provider.retrieveUUID should] equal:cachedUUID];
            });
            it(@"Should not check old database existence", ^{
                [[AMADatabaseFactory shouldNot] receive:@selector(configurationDatabasePath)];
                [provider retrieveUUID];
            });
            it(@"Should not check old database", ^{
                [[configuration shouldNot] receive:@selector(UUIDOldStorage)];
                [[uuidOldStorage shouldNot] receive:@selector(stringForKey:error:)];
                [provider retrieveUUID];
            });
            it(@"Should not save", ^{
                [[instantConfiguration shouldNot] receive:@selector(setUUID:)];
                [provider retrieveUUID];
            });
        });
        context(@"No cached UUID", ^{
            context(@"Has UUID in instant configuration", ^{
                NSString *UUIDFromInstant = @"uuid from instant";
                beforeEach(^{
                    [instantConfiguration stub:@selector(UUID) andReturn:UUIDFromInstant];
                });
                it(@"Should return valid uuid", ^{
                    [[provider.retrieveUUID should] equal:UUIDFromInstant];
                });
                it(@"Should not check old database existence", ^{
                    [[AMADatabaseFactory shouldNot] receive:@selector(configurationDatabasePath)];
                    [provider retrieveUUID];
                });
                it(@"Should not check old database", ^{
                    [[configuration shouldNot] receive:@selector(UUIDOldStorage)];
                    [[uuidOldStorage shouldNot] receive:@selector(stringForKey:error:)];
                    [provider retrieveUUID];
                });
                it(@"Should not save", ^{
                    [[instantConfiguration shouldNot] receive:@selector(setUUID:)];
                    [provider retrieveUUID];
                });
            });
            context(@"No UUID in instant configuration", ^{
                beforeEach(^{
                    [instantConfiguration stub:@selector(UUID) andReturn:@""];
                });
                it(@"Should use right path", ^{
                    [[AMAFileUtility should] receive:@selector(fileExistsAtPath:) withArguments:oldUUIDDatabasePath];
                    [provider retrieveUUID];
                });
                context(@"Old database does not exist", ^{
                    beforeEach(^{
                        [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(NO)];
                    });
                    it(@"Should not check old database", ^{
                        [[configuration shouldNot] receive:@selector(UUIDOldStorage)];
                        [[uuidOldStorage shouldNot] receive:@selector(stringForKey:error:)];
                        [provider retrieveUUID];
                    });
                    it(@"Should return non empty UUID", ^{
                        [[theValue(provider.retrieveUUID.length) shouldNot] beZero];
                    });
                    it(@"Should save UUID", ^{
                        KWCaptureSpy *uuidSpy = [instantConfiguration captureArgument:@selector(setUUID:)
                                                                              atIndex:0];
                        NSString *uuid = provider.retrieveUUID;
                        [[uuidSpy.argument should] equal:uuid];
                    });
                });
                context(@"Old database exists", ^{
                    beforeEach(^{
                        [AMAFileUtility stub:@selector(fileExistsAtPath:) andReturn:theValue(YES)];
                    });
                    it(@"Should check old database", ^{
                        [[configuration should] receive:@selector(UUIDOldStorage)];
                        [[uuidOldStorage should] receive:@selector(stringForKey:error:) withArguments:@"uuid", kw_any()];
                        [provider retrieveUUID];
                    });
                    context(@"Has UUID in old storage", ^{
                        NSString *uuidFromOldStorage = @"uuid from old storage";
                        beforeEach(^{
                            [uuidOldStorage stub:@selector(stringForKey:error:) andReturn:uuidFromOldStorage];
                        });
                        it(@"Should return valid UUID", ^{
                            [[provider.retrieveUUID should] equal:uuidFromOldStorage];
                        });
                        it(@"Should save UUID", ^{
                            KWCaptureSpy *uuidSpy = [instantConfiguration captureArgument:@selector(setUUID:)
                                                                                  atIndex:0];
                            [provider retrieveUUID];
                            [[uuidSpy.argument should] equal:uuidFromOldStorage];
                        });
                    });
                    context(@"No UUID in old storage", ^{
                        beforeEach(^{
                            [uuidOldStorage stub:@selector(stringForKey:error:) andReturn:@""];
                        });
                        it(@"Should return non empty UUID", ^{
                            [[theValue(provider.retrieveUUID.length) shouldNot] beZero];
                        });
                        it(@"Should save UUID", ^{
                            KWCaptureSpy *uuidSpy = [instantConfiguration captureArgument:@selector(setUUID:)
                                                                                  atIndex:0];
                            NSString *uuid = provider.retrieveUUID;
                            [[uuidSpy.argument should] equal:uuid];
                        });
                    });
                });
            });
        });
    });

});

SPEC_END
