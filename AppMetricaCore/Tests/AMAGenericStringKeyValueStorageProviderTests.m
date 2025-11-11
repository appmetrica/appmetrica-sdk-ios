
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAGenericStringKeyValueStorageProvider.h"
#import "AMAJSONFileKVSDataProvider.h"
#import "AMAKeyValueStorageConverting.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAGenericStringKeyValueStorageProviderTests)

describe(@"AMAGenericStringKeyValueStorageProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    AMAGenericStringKeyValueStorageProvider *__block provider = nil;

    context(@"JSON File", ^{
        NSString *__block filePath = nil;
        NSObject<AMAFileStorage> *__block fileStorage = nil;

        beforeEach(^{
            filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
            fileStorage = [[AMADiskFileStorage alloc] initWithPath:filePath options:0];
            __auto_type dataProvider = [[AMAJSONFileKVSDataProvider alloc] initWithFileStorage:fileStorage];
            provider = [[AMAGenericStringKeyValueStorageProvider alloc] initWithDataProvider:dataProvider];
        });

        afterEach(^{
            [fileStorage deleteFileWithError:NULL];
        });

        void (^addValues)(void) = ^{
            [fileStorage writeData:[@"{\"KEY\":\"VALUE\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
        };

        NSString *(^existingValue)(void) = ^{
            NSData *data = [fileStorage readDataWithError:NULL];
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            return dictionary[key];
        };

        context(@"Sync storage", ^{
            id<AMAKeyValueStoring> __block storage = nil;
            beforeEach(^{
                storage = provider.syncStorage;
            });
            it(@"Should return nil", ^{
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return value if exists", ^{
                addValues();
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should write value", ^{
                [storage saveString:value forKey:key error:nil];
                [[existingValue() should] equal:value];
            });
        });

        context(@"Caching storage", ^{
            NSObject<AMAKeyValueStoring> *__block storage = nil;
            beforeEach(^{
                storage = (NSObject<AMAKeyValueStoring> *)provider.cachingStorage;
            });
            it(@"Should return nil", ^{
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return value if exists", ^{
                addValues();
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should write value first time", ^{
                [[fileStorage should] receive:@selector(writeData:error:)];
                [storage saveString:value forKey:key error:nil];
            });
        });

        context(@"In storage", ^{
            it(@"Should return value", ^{
                addValues();
                NSString *__block result = nil;
                [provider inStorage:^(id<AMAKeyValueStoring> storage) {
                    result = [storage stringForKey:key error:nil];
                }];
                [[result should] equal:value];
            });
        });

        context(@"Non-persistent storage", ^{
            it(@"Should return add values via empty storage", ^{
                id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
                [storage saveString:value forKey:key error:nil];
                [provider saveStorage:storage error:nil];
                [[[provider.syncStorage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should return remove values via empty storage", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
                [storage saveString:nil forKey:key error:nil];
                [provider saveStorage:storage error:nil];
                [[[provider.syncStorage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return storage for keys", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should return storage copy for storage", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
                id<AMAKeyValueStoring> storageCopy = [provider nonPersistentStorageForStorage:storage error:nil];
                [[[storageCopy stringForKey:key error:nil] should] equal:value];
            });
            context(@"Error", ^{
                it(@"Should return NO for wrong type storage", ^{
                    [AMATestUtilities stubAssertions];
                    id<AMAKeyValueStoring> storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
                    [[theValue([provider saveStorage:storage error:nil]) should] beNo];
                });
                it(@"Should return NO for wrong type converter", ^{
                    [AMATestUtilities stubAssertions];
                    NSObject<AMAKeyValueStoring> *storage =
                        (NSObject<AMAKeyValueStoring> *)[provider emptyNonPersistentStorage];
                    [storage stub:@selector(converter) andReturn:[KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageConverting)]];
                    [[theValue([provider saveStorage:storage error:nil]) should] beNo];
                });
            });
        });
    });


    context(@"User Defaults", ^{
        NSString *__block suiteName = nil;
        NSUserDefaults *__block defaults = nil;

        beforeEach(^{
            suiteName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
            defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
            __auto_type dataProvider = [[AMAUserDefaultsKVSDataProvider alloc] initWithUserDefaults:defaults];
            provider = [[AMAGenericStringKeyValueStorageProvider alloc] initWithDataProvider:dataProvider];
        });

        afterEach(^{
            [defaults removeSuiteNamed:suiteName];
        });

        void (^addValues)(void) = ^{
            [defaults setObject:value forKey:key];
        };

        NSString *(^existingValue)(void) = ^{
            return [defaults objectForKey:key];
        };

        context(@"Sync storage", ^{
            id<AMAKeyValueStoring> __block storage = nil;
            beforeEach(^{
                storage = provider.syncStorage;
            });
            it(@"Should return nil", ^{
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return value if exists", ^{
                addValues();
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should write value", ^{
                [storage saveString:value forKey:key error:nil];
                [[existingValue() should] equal:value];
            });
        });

        context(@"Caching storage", ^{
            NSObject<AMAKeyValueStoring> *__block storage = nil;
            beforeEach(^{
                storage = (NSObject<AMAKeyValueStoring> *)provider.cachingStorage;
            });
            it(@"Should return nil", ^{
                [[[storage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return value if exists", ^{
                addValues();
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should write value first time", ^{
                [[defaults should] receive:@selector(setObject:forKey:)];
                [storage saveString:value forKey:key error:nil];
            });
        });

        context(@"In storage", ^{
            it(@"Should return value", ^{
                addValues();
                NSString *__block result = nil;
                [provider inStorage:^(id<AMAKeyValueStoring> storage) {
                    result = [storage stringForKey:key error:nil];
                }];
                [[result should] equal:value];
            });
        });

        context(@"Non-persistent storage", ^{
            it(@"Should return add values via empty storage", ^{
                id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
                [storage saveString:value forKey:key error:nil];
                [provider saveStorage:storage error:nil];
                [[[provider.syncStorage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should return remove values via empty storage", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
                [storage saveString:nil forKey:key error:nil];
                [provider saveStorage:storage error:nil];
                [[[provider.syncStorage stringForKey:key error:nil] should] beNil];
            });
            it(@"Should return storage for keys", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            it(@"Should return storage copy for storage", ^{
                addValues();
                id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
                id<AMAKeyValueStoring> storageCopy = [provider nonPersistentStorageForStorage:storage error:nil];
                [[[storageCopy stringForKey:key error:nil] should] equal:value];
            });
            context(@"Error", ^{
                it(@"Should return NO for wrong type storage", ^{
                    [AMATestUtilities stubAssertions];
                    id<AMAKeyValueStoring> storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
                    [[theValue([provider saveStorage:storage error:nil]) should] beNo];
                });
                it(@"Should return NO for wrong type converter", ^{
                    [AMATestUtilities stubAssertions];
                    NSObject<AMAKeyValueStoring> *storage =
                        (NSObject<AMAKeyValueStoring> *)[provider emptyNonPersistentStorage];
                    [storage stub:@selector(converter) andReturn:[KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageConverting)]];
                    [[theValue([provider saveStorage:storage error:nil]) should] beNo];
                });
            });
        });
    });
    
    it(@"Should conform to AMAKeyValueStorageProviding", ^{
        [[provider should] conformToProtocol:@protocol(AMAKeyValueStorageProviding)];
    });
});

SPEC_END
