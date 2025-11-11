
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppIdentifierProvider.h"
#import "AMASecItemOperationResult.h"

@interface AMAAppIdentifierProvider ()

+ (NSDictionary *)query;
+ (AMASecItemOperationResult *)resultForAddQuery:(NSDictionary *)query;
+ (AMASecItemOperationResult *)resultForCopyQuery:(NSDictionary *)query;

@end

SPEC_BEGIN(AMAAppIdentifierProviderTests)

describe(@"AMAAppIdentifierProvider", ^{
    
    NSString *const queryAttrAccount = @"AMAAppIdentifierPrefix";
    NSString *const queryAttrService = @"AMADeviceDescription";
    
    context(@"Provides application identifier prefix", ^{
        NSString *prefix = @"X9DCYK36Q2.";
        NSString *accessGroup = [prefix stringByAppendingString:@"io.appmetrica.shared-device-id"];

        AMASecItemOperationResult *(^resultWithStatus)(OSStatus) = ^AMASecItemOperationResult *(OSStatus status) {
            NSDictionary *attributes = @{ (__bridge id)kSecAttrAccessGroup : accessGroup };
            AMASecItemOperationResult *result = [[AMASecItemOperationResult alloc] initWithStatus:status attributes:attributes];
            return result;
        };
        it(@"Should provide application identifier prefix if copy operation succeeded", ^{
            [AMAAppIdentifierProvider stub:@selector(resultForCopyQuery:) andReturn:resultWithStatus(errSecSuccess)];
            NSString *appIdentifierPrefix = [AMAAppIdentifierProvider appIdentifierPrefix];
            [[appIdentifierPrefix should] equal:prefix];
        });
        it(@"Should provide nil if copy operation failed with any code other than errSecItemNotFound", ^{
            [AMAAppIdentifierProvider stub:@selector(resultForCopyQuery:)
                                andReturn:resultWithStatus(errSecNotAvailable)];
            NSString *appIdentifierPrefix = [AMAAppIdentifierProvider appIdentifierPrefix];
            [[appIdentifierPrefix should] beNil];
        });
        context(@"Adds item to keychain if copy operation failed with errSecItemNotFound", ^{
            BOOL __block addItemCalled = NO;
            void (^stubQueriesWithAddStatus)(OSStatus) = ^(OSStatus addStatus) {
                [AMAAppIdentifierProvider stub:@selector(resultForCopyQuery:)
                                    andReturn:resultWithStatus(errSecItemNotFound)];
                [AMAAppIdentifierProvider stub:@selector(resultForAddQuery:) withBlock:^id(NSArray *params) {
                    addItemCalled = YES;
                    return resultWithStatus(addStatus);
                }];
            };
            it(@"Should call resultForAddQuery", ^{
                stubQueriesWithAddStatus(errSecSuccess);
                NSString * __unused appIdentifierPrefix = [AMAAppIdentifierProvider appIdentifierPrefix];
                [[theValue(addItemCalled) should] beYes];
            });
            it(@"Should add item to keychain if copy operation failed with errSecItemNotFound", ^{
                stubQueriesWithAddStatus(errSecSuccess);
                NSString *appIdentifierPrefix = [AMAAppIdentifierProvider appIdentifierPrefix];
                [[appIdentifierPrefix should] equal:prefix];
            });
            it(@"Should return nil if add operation failed with error", ^{
                stubQueriesWithAddStatus(errSecInteractionNotAllowed);
                NSString *appIdentifierPrefix = [AMAAppIdentifierProvider appIdentifierPrefix];
                [[appIdentifierPrefix should] beNil];
            });
        });
        context(@"Removes incorrect legacy record", ^{
            context(@"Adds record with correct query", ^{
                it(@"Should add record with correct query", ^{
                    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                            (__bridge id)kSecAttrAccount: queryAttrAccount,
                                            (__bridge id)kSecAttrService: queryAttrService,
                                            (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
                                            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock};
                    [[[AMAAppIdentifierProvider query] should] equal:query];
                });
            });
        });
    });
});

SPEC_END
