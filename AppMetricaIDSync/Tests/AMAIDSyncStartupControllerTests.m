
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncLoader.h"
#import "AMAIDSyncStartupRequestParameters.h"
#import "AMAIDSyncStartupResponseParser.h"
#import "AMAIDSyncStartupResponse.h"

SPEC_BEGIN(AMAIDSyncStartupControllerTests)

describe(@"AMAIDSyncStartupController", ^{
    
    AMAIDSyncStartupController *__block controller = nil;
    NSObject<AMAKeyValueStoring> *__block storage = nil;
    NSObject<AMAStartupStorageProviding> *__block startupStorageProvider = nil;
    NSObject<AMACachingStorageProviding> *__block cachingStorageProvider = nil;
    AMAIDSyncStartupConfiguration *__block startup = nil;
    
    beforeEach(^{
        startup = [AMAIDSyncStartupConfiguration nullMock];
        
        storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        
        startupStorageProvider = [KWMock nullMockForProtocol:@protocol(AMAStartupStorageProviding)];
        cachingStorageProvider = [KWMock nullMockForProtocol:@protocol(AMACachingStorageProviding)];
        
        controller = [[AMAIDSyncStartupController alloc] init];
        [controller stub:@selector(startup) andReturn:startup];
    });
    
    context(@"Storage", ^{
        context(@"Setup storage providers", ^{
            beforeEach(^{
                [controller setupStartupProvider:startupStorageProvider
                          cachingStorageProvider:cachingStorageProvider];
            });
            it(@"Should return startup storage", ^{
                [startupStorageProvider stub:@selector(startupStorageForKeys:)
                                   andReturn:storage
                               withArguments:[AMAIDSyncStartupConfiguration allKeys]];
                
                [[(NSObject *)[controller storage] should] equal:storage];
            });
            it(@"Should save storage", ^{
                [startup stub:@selector(storage) andReturn:storage];
                [[startupStorageProvider should] receive:@selector(saveStorage:)
                                           withArguments:storage];
                
                [controller saveStorage];
            });
        });
        it(@"Should return nil if storage provider is nil", ^{
            [[(NSObject *)[controller storage] should] beNil];
        });
    });
    
    context(@"Extended startup observing", ^{
        AMAIDSyncLoader *__block loader = nil;
        beforeEach(^{
            loader = [AMAIDSyncLoader nullMock];
            [AMAIDSyncLoader stub:@selector(sharedInstance) andReturn:loader];
        });
        afterEach(^{
            [AMAIDSyncLoader clearStubs];
        });
        
        it(@"Should return startup request parameters", ^{
            [[[controller startupParameters] should] equal:@{@"request" : [AMAIDSyncStartupRequestParameters parameters]}];
        });
        it(@"Shoulde notify about startup on setup", ^{
            [[loader should] receive:@selector(start)];
            
            [controller setupStartupProvider:startupStorageProvider
                      cachingStorageProvider:cachingStorageProvider];
        });
        context(@"Parsing startup", ^{
            AMAIDSyncStartupResponseParser *__block parser = nil;
            beforeEach(^{
                parser = [AMAIDSyncStartupResponseParser stubbedNullMockForDefaultInit];
                controller = [[AMAIDSyncStartupController alloc] init];
            });
            afterEach(^{
                [AMAIDSyncStartupResponseParser clearStubs];
            });
            it(@"Should parse startup response", ^{
                NSDictionary *response = [NSDictionary dictionary];
                
                [[parser should] receive:@selector(parseStartupResponse:) withArguments:response];
                
                [controller startupUpdatedWithParameters:response];
            });
            it(@"Should update startup configuration", ^{
                NSDictionary *response = [NSDictionary dictionary];
                AMAIDSyncStartupResponse *parsed = [AMAIDSyncStartupResponse nullMock];
                [parsed stub:@selector(configuration) andReturn:startup];
                [parser stub:@selector(parseStartupResponse:) andReturn:parsed withArguments:response];
                
                [[controller should] receive:@selector(updateStartupConfiguration:)
                               withArguments:startup];
                
                [controller startupUpdatedWithParameters:response];
            });
            it(@"Should save startup configuration", ^{
                [[controller should] receive:@selector(saveStorage)];
                
                [controller startupUpdatedWithParameters:[NSDictionary dictionary]];
            });
            it(@"Should notify about startup", ^{
                [[loader should] receive:@selector(start)];
                
                [controller startupUpdatedWithParameters:[NSDictionary dictionary]];
            });
        });
    });
    it(@"Should comform to AMAExtendedStartupObserving", ^{
        [[controller should] conformToProtocol:@protocol(AMAExtendedStartupObserving)];
    });
});

SPEC_END
