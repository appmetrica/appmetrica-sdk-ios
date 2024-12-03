
#import <Kiwi/Kiwi.h>
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMACore.h"
#import "AMAErrorsFactory.h"

SPEC_BEGIN(AMAErrorsFactoryTests)

describe(@"AMAErrorsFactory", ^{

    context(@"Constructed errors", ^{

        NSString *const domain = @"io.appmetrica";
        NSString *const internalDomain = @"AppMetricaInternalErrorDomain";
        NSError *__block error = nil;

        context(@"appMetricaNotStartedError", ^{
            beforeEach(^{
                error = [AMAErrorsFactory appMetricaNotStartedError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1000)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"activateWithApiKey: or activateWithConfiguration: aren't called";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"sessionNotLoadedError", ^{
            beforeEach(^{
                error = [AMAErrorsFactory sessionNotLoadedError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1000)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Session is not loaded";
                [[error.localizedDescription should] equal:description];
            });
        });
        
        context(@"internalInconsistencyError", ^{
            NSString *const errorMsg = @"Error msg";
            beforeEach(^{
                error = [AMAErrorsFactory internalInconsistencyError:errorMsg];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:internalDomain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(2003)];
            });
            it(@"Should use correct description", ^{
                NSString *description = [NSString stringWithFormat:@"Internal inconsistency error: %@", errorMsg];
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"badEventNameError:", ^{
            beforeEach(^{
                error = [AMAErrorsFactory badEventNameError:@"EVENT_NAME"];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Event name 'EVENT_NAME' is incorrect";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"badErrorMessageError:", ^{
            beforeEach(^{
                error = [AMAErrorsFactory badErrorMessageError:@"ERROR_MESSAGE"];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Error message 'ERROR_MESSAGE' is incorrect";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"deepLinkUrlOfUnknownTypeError:", ^{
            beforeEach(^{
                error = [AMAErrorsFactory deepLinkUrlOfUnknownTypeError:@"scheme://"];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"URL value 'scheme://' of unknown type";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"emptyDeepLinkUrlOfUnknownTypeError", ^{
            beforeEach(^{
                error = [AMAErrorsFactory emptyDeepLinkUrlOfUnknownTypeError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Empty URL value of unknown type";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"emptyDeepLinkUrlOfTypeError:", ^{
            beforeEach(^{
                error = [AMAErrorsFactory emptyDeepLinkUrlOfTypeError:@"TYPE"];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Empty 'TYPE' URL value";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"eventTypeReservedError:", ^{
            beforeEach(^{
                error = [AMAErrorsFactory eventTypeReservedError:7];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Event type with number '7' is reserved";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"reporterNotReadyError", ^{
            beforeEach(^{
                error = [AMAErrorsFactory reporterNotReadyError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:domain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1000)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Reporter is not ready yet";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"emptyUserProfileError", ^{
            beforeEach(^{
                error = [AMAErrorsFactory emptyUserProfileError];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(AMAAppMetricaEventErrorCodeEmptyUserProfile)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"User profile is empty. Attributes may have been ignored. See log.";
                [[error.localizedDescription should] equal:description];
            });
        });

        context(@"Revenue", ^{
            context(@"invalidRevenueCurrencyError", ^{
                beforeEach(^{
                    error = [AMAErrorsFactory invalidRevenueCurrencyError:@"USD"];
                });
                it(@"Should use correct code", ^{
                    [[theValue(error.code) should] equal:theValue(AMAAppMetricaEventErrorCodeInvalidRevenueInfo)];
                });
                it(@"Should use correct description", ^{
                    NSString *description = @"Invalid currency code 'USD'. Expected ISO 4217 format.";
                    [[error.localizedDescription should] equal:description];
                });
            });

            context(@"zeroRevenueQuantityError", ^{
                beforeEach(^{
                    error = [AMAErrorsFactory zeroRevenueQuantityError];
                });
                it(@"Should use correct code", ^{
                    [[theValue(error.code) should] equal:theValue(AMAAppMetricaEventErrorCodeInvalidRevenueInfo)];
                });
                it(@"Should use correct description", ^{
                    NSString *description = @"Quantity can't be zero.";
                    [[error.localizedDescription should] equal:description];
                });
            });
        });

        context(@"AdRevenue", ^{
            context(@"invalidAdRevenueCurrencyError", ^{
                beforeEach(^{
                    error = [AMAErrorsFactory invalidAdRevenueCurrencyError:@"USD"];
                });
                it(@"Should use correct code", ^{
                    [[theValue(error.code) should] equal:theValue(AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo)];
                });
                it(@"Should use correct description", ^{
                    NSString *description = @"Invalid currency code 'USD'. Expected ISO 4217 format.";
                    [[error.localizedDescription should] equal:description];
                });
            });
        });

    });

});

SPEC_END
