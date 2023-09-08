
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAJSONFileKVSDataProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAJSONFileKeyValueStorageDataProviderTests)

describe(@"AMAJSONFileKeyValueStorageDataProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    NSString *__block filePath = nil;
    NSObject<AMAFileStorage> *__block fileStorage = nil;
    AMAJSONFileKVSDataProvider *__block provider = nil;

    beforeEach(^{
        filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        fileStorage = [[AMADiskFileStorage alloc] initWithPath:filePath options:0];
        provider = [[AMAJSONFileKVSDataProvider alloc] initWithFileStorage:fileStorage];
    });

    afterEach(^{
        [fileStorage deleteFileWithError:NULL];
    });

    it(@"Should store value", ^{
        [provider saveObject:value forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] equal:value];
    });
    it(@"Should store nil", ^{
        [provider saveObject:nil forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should overwrite with value", ^{
        [provider saveObject:nil forKey:key error:nil];
        [provider saveObject:value forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] equal:value];
    });
    it(@"Should overwrite with nil", ^{
        [provider saveObject:@"SOME" forKey:key error:nil];
        [provider saveObject:nil forKey:key error:nil];
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should return nil if no value", ^{
        [[[provider objectForKey:key error:nil] should] beNil];
    });
    it(@"Should return empty array if no keys", ^{
        [[[provider allKeysWithError:nil] should] beEmpty];
    });
    it(@"Should return all keys", ^{
        [provider saveObject:@"A" forKey:@"a" error:nil];
        [provider saveObject:@"B" forKey:@"b" error:nil];
        [provider saveObject:@"C" forKey:@"c" error:nil];
        [[[provider allKeysWithError:nil] should] containObjectsInArray:@[ @"a", @"b", @"c" ]];
    });
    it(@"Should return values for keys", ^{
        [provider saveObject:@"A" forKey:@"a" error:nil];
        [provider saveObject:@"B" forKey:@"b" error:nil];
        [provider saveObject:@"C" forKey:@"c" error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
    });
    it(@"Should store values for keys", ^{
        [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
    });
    it(@"Should allow removing when storing values for keys", ^{
        [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
        [provider saveObjectsDictionary:@{ @"a": @"AA", @"c": [NSNull null], @"d": @"D" } error:nil];
        [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"AA", @"d": @"D" }];
    });

    it(@"Should write data if value changed", ^{
        [provider saveObject:value forKey:key error:NULL];
        [[fileStorage should] receive:@selector(writeData:error:)];
        [provider saveObject:@"foo" forKey:key error:NULL];
    });
    it(@"Should not write data if value not changed", ^{
        [provider saveObject:value forKey:key error:NULL];
        [[fileStorage shouldNot] receive:@selector(writeData:error:)];
        [provider saveObject:value forKey:key error:NULL];
    });

    context(@"Existing data", ^{
        beforeEach(^{
            [fileStorage writeData:[@"{\"KEY\":\"VALUE\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
        });
        it(@"Should return existing value", ^{
            [[[provider objectForKey:key error:nil] should] equal:value];
        });
        context(@"Append new value", ^{
            NSString *const newKey = @"NEW_KEY";
            NSString *const newValue = @"NEW_VALUE";
            beforeEach(^{
                [provider saveObject:newValue forKey:newKey error:NULL];
            });
            it(@"Should return previous value", ^{
                [[[provider objectForKey:key error:NULL] should] equal:value];
            });
            it(@"Should return new value", ^{
                [[[provider objectForKey:newKey error:NULL] should] equal:newValue];
            });
            it(@"Should write file", ^{
                NSData *data = [fileStorage readDataWithError:NULL];
                NSDictionary *current = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                [[current should] equal:@{ key: value, newKey: newValue }];
            });
        });
        context(@"Remove value", ^{
            beforeEach(^{
                [provider removeKey:key error:NULL];
            });
            it(@"Should not return value", ^{
                [[[provider objectForKey:key error:NULL] should] beNil];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider objectForKey:key error:&error];
                [[error should] beNil];
            });
            it(@"Should write file", ^{
                NSString *current =
                    [[NSString alloc] initWithData:[fileStorage readDataWithError:NULL] encoding:NSUTF8StringEncoding];
                [[current should] equal:@"{}"];
            });
        });
    });

    context(@"Error handling", ^{
        NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:1 userInfo:nil];
        NSError *__block error = nil;

        beforeEach(^{
            error = nil;
        });

        context(@"Read file error", ^{
            beforeEach(^{
                [fileStorage stub:@selector(fileExists) andReturn:theValue(YES)];
                [fileStorage stub:@selector(readDataWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0] withValue:expectedError];
                    return nil;
                }];
            });
            context(@"Getter", ^{
                it(@"Should return nil", ^{
                    [[[provider objectForKey:key error:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider objectForKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Setter", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObject:value forKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObject:value forKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Remove key", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider removeKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider removeKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get all keys", ^{
                it(@"Should return nil", ^{
                    [[[provider allKeysWithError:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider allKeysWithError:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get multiple values", ^{
                it(@"Should return nil", ^{
                    [[[provider objectsForKeys:@[ key ] error:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider objectsForKeys:@[ key ] error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Save multiple values", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObjectsDictionary:@{ key: value } error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObjectsDictionary:@{ key: value } error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });

        context(@"Write file error", ^{
            NSString *const originalValue = @"ORIGINAL_VALUE";
            beforeEach(^{
                [fileStorage writeData:[@"{\"KEY\": \"ORIGINAL_VALUE\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
                [fileStorage stub:@selector(writeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return theValue(NO);
                }];
            });
            context(@"Getter", ^{
                it(@"Should return value", ^{
                    [[[provider objectForKey:key error:&error] should] equal:originalValue];
                });
                it(@"Should not fill error", ^{
                    [provider objectForKey:key error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Setter", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObject:value forKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObject:value forKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Setter with same value", ^{
                it(@"Should return YES", ^{
                    [[theValue([provider saveObject:originalValue forKey:key error:&error]) should] beYes];
                });
                it(@"Should not fill error", ^{
                    [provider saveObject:originalValue forKey:key error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Remove key", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider removeKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider removeKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get all keys", ^{
                it(@"Should return value", ^{
                    [[[provider allKeysWithError:&error] should] equal:@[ key ]];
                });
                it(@"Should not fill error", ^{
                    [provider allKeysWithError:&error];
                    [[error should] beNil];
                });
            });
            context(@"Get multiple values", ^{
                it(@"Should return values", ^{
                    [[[provider objectsForKeys:@[ key ] error:&error] should] equal:@{ key: originalValue }];
                });
                it(@"Should fill error", ^{
                    [provider objectsForKeys:@[ key ] error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Save multiple values", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObjectsDictionary:@{ key: value } error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObjectsDictionary:@{ key: value } error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });

        context(@"Corruptted JSON", ^{
            beforeEach(^{
                [fileStorage writeData:[@"NOT_A_JSON" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
                [AMAJSONSerialization stub:@selector(dictionaryWithJSONData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            context(@"Getter", ^{
                it(@"Should return nil", ^{
                    [[[provider objectForKey:key error:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider objectForKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Setter", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObject:value forKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObject:value forKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Remove key", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider removeKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider removeKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get all keys", ^{
                it(@"Should return nil", ^{
                    [[[provider allKeysWithError:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider allKeysWithError:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get multiple values", ^{
                it(@"Should return nil", ^{
                    [[[provider objectsForKeys:@[ key ] error:&error] should] beNil];
                });
                it(@"Should fill error", ^{
                    [provider objectsForKeys:@[ key ] error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Save multiple values", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObjectsDictionary:@{ key: value } error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObjectsDictionary:@{ key: value } error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });

        context(@"Write file error", ^{
            NSString *const originalValue = @"ORIGINAL_VALUE";
            beforeEach(^{
                [fileStorage writeData:[@"{\"KEY\": \"ORIGINAL_VALUE\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
                [AMAJSONSerialization stub:@selector(dataWithJSONObject:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            context(@"Getter", ^{
                it(@"Should return value", ^{
                    [[[provider objectForKey:key error:&error] should] equal:originalValue];
                });
                it(@"Should not fill error", ^{
                    [provider objectForKey:key error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Setter", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObject:value forKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObject:value forKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Setter with same value", ^{
                it(@"Should return YES", ^{
                    [[theValue([provider saveObject:originalValue forKey:key error:&error]) should] beYes];
                });
                it(@"Should not fill error", ^{
                    [provider saveObject:originalValue forKey:key error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Remove key", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider removeKey:key error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider removeKey:key error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Get all keys", ^{
                it(@"Should return value", ^{
                    [[[provider allKeysWithError:&error] should] equal:@[ key ]];
                });
                it(@"Should not fill error", ^{
                    [provider allKeysWithError:&error];
                    [[error should] beNil];
                });
            });
            context(@"Get multiple values", ^{
                it(@"Should return values", ^{
                    [[[provider objectsForKeys:@[ key ] error:&error] should] equal:@{ key: originalValue }];
                });
                it(@"Should fill error", ^{
                    [provider objectsForKeys:@[ key ] error:&error];
                    [[error should] beNil];
                });
            });
            context(@"Save multiple values", ^{
                it(@"Should return NO", ^{
                    [[theValue([provider saveObjectsDictionary:@{ key: value } error:&error]) should] beNo];
                });
                it(@"Should fill error", ^{
                    [provider saveObjectsDictionary:@{ key: value } error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });
    });
    
});

SPEC_END
