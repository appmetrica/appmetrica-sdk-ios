#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import <AppMetricaCore/AppMetricaCore.h>

#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAStartupItemsChangedNotifier.h"
#import "AMAStartupItemsChangedNotifier+Tests.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAStartupController.h"
#import "AMAIdentifierProviderMock.h"

SPEC_BEGIN(AMAStartupItemsChangedNotifierTests)

describe(@"AMAStartupItemsChangedNotifier", ^{
    
    NSArray *const allIdentifiersKeys = @[
        @"appmetrica_uuid",
        @"appmetrica_deviceID",
        @"appmetrica_deviceIDHash",
    ];

    NSArray *const allKeys = allIdentifiersKeys;

    AMAStartupItemsChangedNotifier *__block notifier = nil;
    AMAMetricaConfiguration *__block configMock = nil;
    AMAIdentifierProviderMock *__block idMock;
    
    NSDictionary *__block receivedIdentifiers = nil;
    NSError *__block receivedError = nil;
    BOOL __block defaultBlockIsCalled = NO;
    AMAIdentifiersCompletionBlock const defaultBlock = ^(NSDictionary *identifiers, NSError *error) {
        defaultBlockIsCalled = YES;
        receivedIdentifiers = identifiers;
        receivedError = error;
    };

    beforeEach(^{
        defaultBlockIsCalled = NO;
        receivedIdentifiers = nil;
        receivedError = nil;

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configMock = [AMAMetricaConfiguration sharedInstance];
        idMock = [[AMAIdentifierProviderMock alloc] init];
        [configMock stub:@selector(identifierProvider) andReturn:idMock];
        [configMock stub:@selector(appMetricaUUID) withBlock:^id(NSArray *params) {
            return idMock.appMetricaUUID;
        }];
        [configMock stub:@selector(deviceID) withBlock:^id(NSArray *params) {
            return idMock.deviceID;
        }];
        [configMock stub:@selector(deviceIDHash) withBlock:^id(NSArray *params) {
            return idMock.deviceIDHash;
        }];
        
        notifier = [[AMAStartupItemsChangedNotifier alloc] initWithMetricaConfiguration:configMock];
        [notifier stub:@selector(dispatchBlock:withAvailableFields:toQueue:error:)
             withBlock:^id(NSArray *params) {
                 AMAIdentifiersCompletionBlock block = params[0];
                 block(params[1] == [NSNull null] ? nil : params[1], params[3] == [NSNull null] ? nil : params[3]);
                 return nil;
             }];
    });
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAMetricaConfiguration.sharedInstance clearStubs];
        [AMAMetricaConfiguration.sharedInstance.persistent clearStubs];
        [AMAMetricaConfiguration.sharedInstance.startup clearStubs];
    });

    it(@"Should have proper identifier keys", ^{
        [[[AMAStartupItemsChangedNotifier allIdentifiersKeys] should] equal:allIdentifiersKeys];
    });

    context(@"Notifies when requested data is unavailable", ^{
        it(@"Should notify because startup has allready been loaded", ^{
            [notifier startupUpdateCompletedWithConfiguration:nil];
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:nil
                                            queue:nil
                                       completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beYes];
            [[theValue(receivedIdentifiers.count) should] beZero];
            [[receivedError should] beNil];
        });

        it(@"Should not notify because startup has not been loaded", ^{
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:nil
                                            queue:nil
                                       completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should not notify with error", ^{
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:nil
                                            queue:nil
                                       completion:defaultBlock];
            NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
            [notifier startupUpdateFailedWithError:error];

            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should stay pending when keys unavailable and notifyOnError NO", ^{
            idMock.mockMetricaUUID = @"uuid";
            idMock.mockDeviceID = @"deviceID";
            NSDictionary *options = @{ kAMARequestIdentifiersOptionCallbackModeKey :
                                           kAMARequestIdentifiersOptionCallbackOnSuccess };
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:options
                                            queue:nil
                                       completion:defaultBlock];
            NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
            [notifier startupUpdateFailedWithError:error];

            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should notify with error", ^{
            NSString *callbackMode = kAMARequestIdentifiersOptionCallbackInAnyCase;
            NSDictionary *options = @{kAMARequestIdentifiersOptionCallbackModeKey : callbackMode};
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:options
                                            queue:nil
                                       completion:defaultBlock];
            NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
            [notifier startupUpdateFailedWithError:error];

            [[receivedError should] equal:error];
        });
        
        it(@"Should not notify with error if startup loaded", ^{
            [notifier stub:@selector(startupLoaded) andReturn:theValue(YES)];
            
            NSString *callbackMode = kAMARequestIdentifiersOptionCallbackInAnyCase;
            NSDictionary *options = @{kAMARequestIdentifiersOptionCallbackModeKey : callbackMode};
            [notifier requestStartupItemsWithKeys:allKeys
                                          options:options
                                            queue:nil
                                       completion:defaultBlock];
            NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
            
            [notifier startupUpdateFailedWithError:error];

            [[receivedError should] beNil];
        });
    });
    context(@"Notifies when deviceIDHash is available or not", ^{
        it(@"Should notify because deviceIDHash has been stored", ^{
            idMock.mockMetricaUUID = @"uuid";
            idMock.mockDeviceID = @"deviceID";
            idMock.mockDeviceHashID = @"deviceIDHash";
            
            NSString *adHost = @"https://https://mobile-ads-beta.appmetrica.io:4443";
            NSDictionary *extendedParametersMock = @{@"get_ad" : adHost,
                                                     @"report_ad" : adHost};
            [configMock.startup stub:@selector(extendedParameters) andReturn:extendedParametersMock];
            
            [configMock.startup stub:@selector(SDKsCustomHosts) andReturn:@{ @"arbitraryKey" : @[ @"host" ] }];
            
            [notifier requestStartupItemsWithKeys:[allKeys arrayByAddingObjectsFromArray:@[@"arbitraryKey", @"get_ad", @"report_ad"]]
                                          options:nil
                                            queue:nil
                                       completion:defaultBlock];
            [[receivedIdentifiers should] equal:@{
                kAMAUUIDKey: @"uuid",
                kAMADeviceIDKey: @"deviceID",
                kAMADeviceIDHashKey: @"deviceIDHash",
                @"get_ad": adHost,
                @"report_ad": adHost,
                @"arbitraryKey": @[ @"host" ],
            }];
        });

        it(@"Should notify if required arbitrary keys are ready", ^{
            NSDictionary *expectedDict = @{
                @"arbitraryKey1" : @[ @"host1", @"host2" ],
                @"arbitraryKey2" : @[ @"host3", @"host4" ],
            };

            [configMock.startup stub:@selector(SDKsCustomHosts) andReturn:expectedDict];

            [notifier requestStartupItemsWithKeys:@[ @"arbitraryKey1", @"arbitraryKey2" ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[receivedIdentifiers should] equal:expectedDict];
        });

        it(@"Should notify if required keys are ready", ^{
            idMock.mockMetricaUUID = @"uuid";
            idMock.mockDeviceID = @"deviceID";
            
            
            [notifier requestStartupItemsWithKeys:@[ kAMAUUIDKey, kAMADeviceIDKey ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[receivedIdentifiers should] equal:@{
                kAMAUUIDKey: @"uuid",
                kAMADeviceIDKey: @"deviceID",
            }];
        });

        it(@"Should not notify because deviceIDHash has not been stored", ^{
            idMock.mockMetricaUUID = @"uuid";
            
            [configMock.startup stub:@selector(SDKsCustomHosts) andReturn:@{ @"arbitraryKey" : @[ @"host" ] }];

            [notifier requestStartupItemsWithKeys:[allKeys arrayByAddingObject:@"arbitraryKey"]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should not notify because deviceID is empty", ^{
            idMock.mockMetricaUUID = @"uuid";
            idMock.mockDeviceID = @"";
            

            [notifier requestStartupItemsWithKeys:@[ kAMAUUIDKey, kAMADeviceIDKey ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should not notify because UUID is empty", ^{
            idMock.mockMetricaUUID = @"";
            idMock.mockDeviceID = @"deviceID";

            [notifier requestStartupItemsWithKeys:@[ kAMAUUIDKey, kAMADeviceIDKey ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beNo];
        });

        it(@"Should notify without UUID key when UUID empty and startup loaded", ^{
            idMock.mockMetricaUUID = @"";
            idMock.mockDeviceID = @"deviceID";
            [notifier startupUpdateCompletedWithConfiguration:nil];

            [notifier requestStartupItemsWithKeys:@[ kAMAUUIDKey, kAMADeviceIDKey ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beYes];
            [[receivedIdentifiers should] equal:@{ kAMADeviceIDKey: @"deviceID" }];
            [[receivedIdentifiers[kAMAUUIDKey] should] beNil];
        });

        it(@"Should not contain empty UUID value in callback", ^{
            idMock.mockMetricaUUID = @"";
            [notifier startupUpdateCompletedWithConfiguration:nil];

            [notifier requestStartupItemsWithKeys:@[ kAMAUUIDKey ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beYes];
            [[receivedIdentifiers[kAMAUUIDKey] should] beNil];
        });

        it(@"Should notify with UUID when UUID is non-empty", ^{
            idMock.mockMetricaUUID = @"uuid";
            idMock.mockDeviceID = @"deviceID";
            idMock.mockDeviceHashID = @"hash";

            [notifier requestStartupItemsWithKeys:allKeys
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[receivedIdentifiers should] equal:@{
                kAMAUUIDKey: @"uuid",
                kAMADeviceIDKey: @"deviceID",
                kAMADeviceIDHashKey: @"hash",
            }];
        });

        it(@"Should not notify if not all required arbitrary keys are ready", ^{
            NSDictionary *expectedDict = @{
                @"arbitraryKey1" : @[ @"host1", @"host2" ],
                @"arbitraryKey2" : @[ @"host3", @"host4" ],
            };

            [configMock.startup stub:@selector(SDKsCustomHosts) andReturn:expectedDict];

            [notifier requestStartupItemsWithKeys:@[ @"arbitraryKey1", @"arbitraryKey2", @"arbitraryKey3" ]
                                                options:nil
                                                  queue:nil
                                             completion:defaultBlock];
            [[theValue(defaultBlockIsCalled) should] beNo];
        });
    });
    
    it(@"Should conform to AMAStartupCompletionObserving", ^{
        [[notifier should] conformToProtocol:@protocol(AMAStartupCompletionObserving)];
    });
});

SPEC_END
