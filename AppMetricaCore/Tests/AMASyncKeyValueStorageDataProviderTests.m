
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMASyncKeyValueStorageDataProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMASyncKeyValueStorageDataProviderTests)

describe(@"AMASyncKeyValueStorageDataProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";
    NSArray *const keys = @[ @"foo", @"bar" ];
    NSDictionary *const values = @{ @"foo": @"bar" };
    NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];

    NSObject<AMAKeyValueStorageDataProviding> *__block underlyingProvider = nil;
    AMASyncKeyValueStorageDataProvider *__block provider = nil;

    beforeEach(^{
        underlyingProvider = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageDataProviding)];
        provider = [[AMASyncKeyValueStorageDataProvider alloc] initWithUnderlyingProviderSource:^(AMAKVSWithProviderBlock block) {
            block(underlyingProvider);
        }];
    });

    context(@"All keys", ^{
        NSArray *const allKeys = @[ @"foo", @"bar" ];
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(allKeysWithError:) andReturn:allKeys];
            });
            it(@"Should return valid value", ^{
                [[[provider allKeysWithError:nil] should] equal:allKeys];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider allKeysWithError:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(allKeysWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[provider allKeysWithError:nil] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider allKeysWithError:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Remove key", ^{
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(removeKey:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([provider removeKey:key error:nil]) should] beYes];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider removeKey:key error:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(removeKey:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([provider removeKey:key error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider removeKey:key error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Object for key", ^{
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(objectForKey:error:) andReturn:value];
            });
            it(@"Should return valid value", ^{
                [[[provider objectForKey:key error:nil] should] equal:value];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider objectForKey:key error:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(objectForKey:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[provider objectForKey:key error:nil] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider objectForKey:key error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Save object for key", ^{
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(saveObject:forKey:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([provider saveObject:value forKey:key error:nil]) should] beYes];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider saveObject:value forKey:key error:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(saveObject:forKey:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([provider saveObject:value forKey:key error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider saveObject:value forKey:key error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Objects for keys", ^{
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(objectsForKeys:error:) andReturn:values];
            });
            it(@"Should return YES", ^{
                [[[provider objectsForKeys:keys error:nil] should] equal:values];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider objectsForKeys:keys error:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(objectsForKeys:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return NO", ^{
                [[[provider objectsForKeys:keys error:nil] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider objectsForKeys:keys error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Save objects dictionary", ^{
        context(@"Success", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(saveObjectsDictionary:error:) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([provider saveObjectsDictionary:values error:nil]) should] beYes];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [provider saveObjectsDictionary:values error:&error];
                [[error should] beNil];
            });
        });
        context(@"Error", ^{
            beforeEach(^{
                [underlyingProvider stub:@selector(saveObjectsDictionary:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return theValue(NO);
                }];
            });
            it(@"Should return NO", ^{
                [[theValue([provider saveObjectsDictionary:values error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [provider saveObjectsDictionary:values error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

});

SPEC_END

