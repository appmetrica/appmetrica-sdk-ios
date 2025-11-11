
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAErrorLogger.h"

SPEC_BEGIN(AMAReporterConfigurationTests)

describe(@"AMAReporterConfiguration", ^{

    NSString *const apiKey = @"API_KEY";
    NSUInteger const defaultSessionTimeout = 10;
    NSUInteger const defaultDispatchPeriod = 90;
    NSUInteger const defaultMaxReportsCount = 1;
    NSUInteger const defaultMaxReportsInDatabaseCount = 1000;

    context(@"No API key", ^{
        context(@"Immutable", ^{
            AMAReporterConfiguration *__block configuration = nil;
            beforeEach(^{
                configuration = [[AMAReporterConfiguration alloc] initWithoutAPIKey];
            });
            it(@"Should have nil API key", ^{
                [[configuration.APIKey should] beNil];
            });
            it(@"Should have valid session timeout", ^{
                [[theValue(configuration.sessionTimeout) should] equal:theValue(defaultSessionTimeout)];
            });
            it(@"Should have valid dispatch period", ^{
                [[theValue(configuration.dispatchPeriod) should] equal:theValue(defaultDispatchPeriod)];
            });
            it(@"Should have valid max reports count", ^{
                [[theValue(configuration.maxReportsCount) should] equal:theValue(defaultMaxReportsCount)];
            });
            it(@"Should have valid max reports in database count", ^{
                [[theValue(configuration.maxReportsInDatabaseCount) should] equal:theValue(defaultMaxReportsInDatabaseCount)];
            });
            it(@"Should have valid user profile ID", ^{
                [[configuration.userProfileID should] beNil];
            });
        });
        context(@"Mutable", ^{
            AMAMutableReporterConfiguration *__block configuration = nil;
            beforeEach(^{
                configuration = [[AMAMutableReporterConfiguration alloc] initWithoutAPIKey];
            });
            it(@"Should have nil API key", ^{
                [[configuration.APIKey should] beNil];
            });
            it(@"Should have valid session timeout", ^{
                [[theValue(configuration.sessionTimeout) should] equal:theValue(defaultSessionTimeout)];
            });
            it(@"Should have valid dispatch period", ^{
                [[theValue(configuration.dispatchPeriod) should] equal:theValue(defaultDispatchPeriod)];
            });
            it(@"Should have valid max reports count", ^{
                [[theValue(configuration.maxReportsCount) should] equal:theValue(defaultMaxReportsCount)];
            });
            it(@"Should have valid max reports in database count", ^{
                [[theValue(configuration.maxReportsInDatabaseCount) should] equal:theValue(defaultMaxReportsInDatabaseCount)];
            });
            it(@"Should have user profile ID", ^{
                [[configuration.userProfileID should] beNil];
            });
        });
    });
    context(@"Invalid API key", ^{
        beforeEach(^{
            [AMAErrorLogger stub:@selector(logInvalidApiKeyError:)];
            [AMAIdentifierValidator stub:@selector(isValidUUIDKey:) andReturn:theValue(NO)];
        });
        context(@"Immutable", ^{
            it(@"Should log", ^{
                [[AMAErrorLogger should] receive:@selector(logInvalidApiKeyError:) withArguments:apiKey];
                id some __unused = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
            });
            it(@"Should return nil", ^{
                [[[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey] should] beNil];
            });
        });
        context(@"Mutable", ^{
            it(@"Should log", ^{
                [[AMAErrorLogger should] receive:@selector(logInvalidApiKeyError:) withArguments:apiKey];
                id some __unused = [[AMAMutableReporterConfiguration alloc] initWithAPIKey:apiKey];
            });
            it(@"Should return nil", ^{
                [[[[AMAMutableReporterConfiguration alloc] initWithAPIKey:apiKey] should] beNil];
            });
        });
    });
    context(@"Valid API key", ^{
        beforeEach(^{
            [AMAIdentifierValidator stub:@selector(isValidUUIDKey:) andReturn:theValue(YES)];
        });
        context(@"Immutable", ^{
            AMAReporterConfiguration *__block configuration = nil;
            beforeEach(^{
                configuration = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
            });
            it(@"Should have valid API key", ^{
                [[configuration.APIKey should] equal:apiKey];
            });
            it(@"Should have valid session timeout", ^{
                [[theValue(configuration.sessionTimeout) should] equal:theValue(defaultSessionTimeout)];
            });
            it(@"Should have valid dispatch period", ^{
                [[theValue(configuration.dispatchPeriod) should] equal:theValue(defaultDispatchPeriod)];
            });
            it(@"Should have valid max reports count", ^{
                [[theValue(configuration.maxReportsCount) should] equal:theValue(defaultMaxReportsCount)];
            });
            it(@"Should have valid max reports in database count", ^{
                [[theValue(configuration.maxReportsInDatabaseCount) should] equal:theValue(defaultMaxReportsInDatabaseCount)];
            });
            it(@"Should have user profile ID", ^{
                [[configuration.userProfileID should] beNil];
            });
            context(@"Immutable copy", ^{
                it(@"Should return self", ^{
                    [[[configuration copy] should] equal:configuration];
                });
            });
            context(@"Mutable copy", ^{
                AMAMutableReporterConfiguration *__block mutableCopy = nil;
                beforeEach(^{
                    mutableCopy = [configuration mutableCopy];
                });
                it(@"Should have valid API key", ^{
                    [[configuration.APIKey should] equal:apiKey];
                });
                it(@"Should have valid session timeout", ^{
                    [[theValue(mutableCopy.sessionTimeout) should] equal:theValue(defaultSessionTimeout)];
                });
                it(@"Should have valid dispatch period", ^{
                    [[theValue(mutableCopy.dispatchPeriod) should] equal:theValue(defaultDispatchPeriod)];
                });
                it(@"Should have valid max reports count", ^{
                    [[theValue(mutableCopy.maxReportsCount) should] equal:theValue(defaultMaxReportsCount)];
                });
                it(@"Should have valid max reports in database count", ^{
                    [[theValue(mutableCopy.maxReportsInDatabaseCount) should] equal:theValue(defaultMaxReportsInDatabaseCount)];
                });
                it(@"Should have user profile ID", ^{
                    [[mutableCopy.userProfileID should] beNil];
                });
            });
        });
        context(@"Mutable", ^{
            AMAMutableReporterConfiguration *__block configuration = nil;
            beforeEach(^{
                configuration = [[AMAMutableReporterConfiguration alloc] initWithAPIKey:apiKey];
            });
            it(@"Should have valid API key", ^{
                [[configuration.APIKey should] equal:apiKey];
            });
            it(@"Should have valid session timeout", ^{
                [[theValue(configuration.sessionTimeout) should] equal:theValue(defaultSessionTimeout)];
            });
            it(@"Should have valid dispatch period", ^{
                [[theValue(configuration.dispatchPeriod) should] equal:theValue(defaultDispatchPeriod)];
            });
            it(@"Should have valid max reports count", ^{
                [[theValue(configuration.maxReportsCount) should] equal:theValue(defaultMaxReportsCount)];
            });
            it(@"Should have valid max reports in database count", ^{
                [[theValue(configuration.maxReportsInDatabaseCount) should] equal:theValue(defaultMaxReportsInDatabaseCount)];
            });
            it(@"Should have user profile ID", ^{
                [[configuration.userProfileID should] beNil];
            });
            context(@"Changed values", ^{
                NSString *const newAPIKey = @"ANOTHER_API_KEY";
                NSUInteger const newSessionTimeout = 10;
                NSUInteger const newDispatchPeriod = 90;
                NSUInteger const newMaxReportsCount = 1;
                NSUInteger const newMaxReportsInDatabaseCount = 10000;
                NSString *const newUserProfileID = @"profile id";
                beforeEach(^{
                    configuration.APIKey = newAPIKey;
                    configuration.sessionTimeout = newSessionTimeout;
                    configuration.dispatchPeriod = newDispatchPeriod;
                    configuration.maxReportsCount = newMaxReportsCount;
                    configuration.maxReportsInDatabaseCount = newMaxReportsInDatabaseCount;
                    configuration.userProfileID = newUserProfileID;
                });
                context(@"Immutable copy", ^{
                    AMAReporterConfiguration *__block immutableCopy = nil;
                    beforeEach(^{
                        immutableCopy = [configuration copy];
                    });
                    it(@"Should have valid API key", ^{
                        [[immutableCopy.APIKey should] equal:newAPIKey];
                    });
                    it(@"Should have valid session timeout", ^{
                        [[theValue(immutableCopy.sessionTimeout) should] equal:theValue(newSessionTimeout)];
                    });
                    it(@"Should have valid dispatch period", ^{
                        [[theValue(immutableCopy.dispatchPeriod) should] equal:theValue(newDispatchPeriod)];
                    });
                    it(@"Should have valid max reports count", ^{
                        [[theValue(immutableCopy.maxReportsCount) should] equal:theValue(newMaxReportsCount)];
                    });
                    it(@"Should have valid max reports in database count", ^{
                        [[theValue(immutableCopy.maxReportsInDatabaseCount) should] equal:theValue(newMaxReportsInDatabaseCount)];
                    });
                    it(@"Should have valid user profile ID", ^{
                        [[immutableCopy.userProfileID should] equal:newUserProfileID];
                    });
                });
                context(@"Mutable copy", ^{
                    AMAMutableReporterConfiguration *__block mutableCopy = nil;
                    beforeEach(^{
                        mutableCopy = [configuration copy];
                    });
                    it(@"Should have valid API key", ^{
                        [[mutableCopy.APIKey should] equal:newAPIKey];
                    });
                    it(@"Should have valid session timeout", ^{
                        [[theValue(mutableCopy.sessionTimeout) should] equal:theValue(newSessionTimeout)];
                    });
                    it(@"Should have valid dispatch period", ^{
                        [[theValue(mutableCopy.dispatchPeriod) should] equal:theValue(newDispatchPeriod)];
                    });
                    it(@"Should have valid max reports count", ^{
                        [[theValue(mutableCopy.maxReportsCount) should] equal:theValue(newMaxReportsCount)];
                    });
                    it(@"Should have valid max reports in database count", ^{
                        [[theValue(mutableCopy.maxReportsInDatabaseCount) should] equal:theValue(newMaxReportsInDatabaseCount)];
                    });
                    it(@"Should have valid user profile ID", ^{
                        [[mutableCopy.userProfileID should] equal:newUserProfileID];
                    });
                    context(@"Original configuration values changed", ^{
                        beforeEach(^{
                            configuration.APIKey = apiKey;
                            configuration.sessionTimeout = defaultSessionTimeout;
                            configuration.dispatchPeriod = defaultDispatchPeriod;
                            configuration.maxReportsCount = defaultMaxReportsCount;
                            configuration.maxReportsInDatabaseCount = defaultMaxReportsInDatabaseCount;
                            configuration.userProfileID = nil;
                        });
                        it(@"Should have valid API key", ^{
                            [[mutableCopy.APIKey should] equal:newAPIKey];
                        });
                        it(@"Should have valid session timeout", ^{
                            [[theValue(mutableCopy.sessionTimeout) should] equal:theValue(newSessionTimeout)];
                        });
                        it(@"Should have valid dispatch period", ^{
                            [[theValue(mutableCopy.dispatchPeriod) should] equal:theValue(newDispatchPeriod)];
                        });
                        it(@"Should have valid max reports count", ^{
                            [[theValue(mutableCopy.maxReportsCount) should] equal:theValue(newMaxReportsCount)];
                        });
                        it(@"Should have valid max reports in database count", ^{
                            [[theValue(mutableCopy.maxReportsInDatabaseCount) should] equal:theValue(newMaxReportsInDatabaseCount)];
                        });
                        it(@"Should have valid user profile ID", ^{
                            [[mutableCopy.userProfileID should] equal:newUserProfileID];
                        });
                    });
                });
            });
        });
    });

});

SPEC_END
