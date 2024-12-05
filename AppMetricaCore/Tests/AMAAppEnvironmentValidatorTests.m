
#import <Kiwi/Kiwi.h>
#import "AMAAppEnvironmentValidator.h"
#import "AMAInternalEventsReporter.h"

SPEC_BEGIN(AMAAppEnvironmentValidatorTests)

describe(@"AMAAppEnvironmentValidator", ^{

    __block AMAAppEnvironmentValidator *validator = nil;
    __block AMAInternalEventsReporter *mockReporter = nil;

    beforeEach(^{
        mockReporter = [AMAInternalEventsReporter nullMock];
        validator = [[AMAAppEnvironmentValidator alloc] initWithInternalReporter:mockReporter];
    });

    context(@"Validate key", ^{

        it(@"should return YES for valid key", ^{
            NSString *validKey = @"validKey";
            
            BOOL result = [validator validateAppEnvironmentKey:validKey];
            [[theValue(result) should] beYes];
        });

        it(@"should return NO and report error for nil key", ^{
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"error": @"null" }, @"key"];
            
            BOOL result = [validator validateAppEnvironmentKey:nil];
            [[theValue(result) should] beNo];
        });

        it(@"should return NO and report error for key longer than 30 characters", ^{
            NSString *longKey = [@"" stringByPaddingToLength:51 withString:@"a" startingAtIndex:0];
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"limit_exceeded": longKey }, @"key"];
            
            BOOL result = [validator validateAppEnvironmentKey:longKey];
            [[theValue(result) should] beNo];
        });

        it(@"should return NO and report error for key that is a dictionary", ^{
            NSDictionary *invalidKey = @{ @"key": @"value" };
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"invalid_dictionary": invalidKey }, @"key"];
            
            BOOL result = [validator validateAppEnvironmentKey:invalidKey];
            [[theValue(result) should] beNo];
        });

        it(@"should return NO and report error for key with invalid type", ^{
            NSNumber *invalidKey = @(123);
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"invalid_type": @"__NSCFNumber" }, @"key"];
            
            BOOL result = [validator validateAppEnvironmentKey:invalidKey];
            [[theValue(result) should] beNo];
        });
    });

    context(@"Validate value", ^{

        it(@"should return YES for valid value", ^{
            NSString *validValue = @"validValue";
            
            BOOL result = [validator validateAppEnvironmentValue:validValue];
            [[theValue(result) should] beYes];
        });

        it(@"should return NO and report error for nil value", ^{
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"error": @"null" }, @"value"];
            
            BOOL result = [validator validateAppEnvironmentValue:nil];
            [[theValue(result) should] beNo];
        });

        it(@"should return NO and report error for value longer than 4000 characters", ^{
            NSString *longValue = [@"" stringByPaddingToLength:4001 withString:@"a" startingAtIndex:0];
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"limit_exceeded": longValue }, @"value"];
            
            BOOL result = [validator validateAppEnvironmentValue:longValue];
            [[theValue(result) should] beNo];
        });
        
        it(@"should return NO and report error for value that is a dictionary", ^{
            NSDictionary *invalidValue = @{ @"key": @"value" };
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"invalid_dictionary": invalidValue }, @"value"];
            
            BOOL result = [validator validateAppEnvironmentValue:invalidValue];
            [[theValue(result) should] beNo];
        });

        it(@"should return NO and report error for value with invalid type", ^{
            NSArray *invalidValue = @[ @"value1", @"value2" ];
            
            [[mockReporter should] receive:@selector(reportAppEnvironmentError:type:)
                               withArguments:@{ @"invalid_type": @"__NSArrayI" }, @"value"];
            
            BOOL result = [validator validateAppEnvironmentValue:invalidValue];
            [[theValue(result) should] beNo];
        });
    });
});

SPEC_END
