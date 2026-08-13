
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAModulesStatusReportState.h"

SPEC_BEGIN(AMAModulesStatusReportStateTests)

describe(@"AMAModulesStatusReportState", ^{

    NSString *const kLastSentKey = @"last_sent";
    NSString *const kModulesKey = @"modules";

    NSDate *const lastSentDate = [NSDate dateWithTimeIntervalSince1970:1700000000];
    NSDictionary<NSString *, NSNumber *> *const modules = @{
        @"AppMetricaAdSupport": @YES,
        @"AppMetricaScreenshot": @NO,
    };

    context(@"Initialization", ^{
        it(@"Should keep both values", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate
                moduleStatuses:modules];
            [[state.lastSentDate should] equal:lastSentDate];
            [[state.moduleStatuses should] equal:modules];
        });

        it(@"Should allow nil fields", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:nil
                moduleStatuses:nil];
            [[state.lastSentDate should] beNil];
            [[state.moduleStatuses should] beNil];
        });
    });

    context(@"JSON serialization", ^{
        it(@"Should serialize both fields", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate
                moduleStatuses:modules];
            NSDictionary *json = [state JSON];
            [[json[kLastSentKey] should] equal:@([lastSentDate timeIntervalSince1970])];
            [[json[kModulesKey] should] equal:modules];
        });

        it(@"Should skip nil fields", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:nil
                moduleStatuses:nil];
            NSDictionary *json = [state JSON];
            [[json should] equal:@{}];
        });

        it(@"Should round-trip", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate
                moduleStatuses:modules];
            AMAModulesStatusReportState *restored = [[AMAModulesStatusReportState alloc] initWithJSON:[state JSON]];
            [[restored.lastSentDate should] equal:lastSentDate];
            [[restored.moduleStatuses should] equal:modules];
        });

        it(@"Should return nil for non-dictionary input", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithJSON:(NSDictionary *)@"not a dict"];
            [[state should] beNil];
        });

        it(@"Should ignore wrong types in modules dictionary", ^{
            NSDictionary *json = @{
                kLastSentKey: @1700000000,
                kModulesKey: @{
                    @"GoodModule": @YES,
                    @"BadValueModule": @"string-instead-of-number",
                    @123: @NO,
                },
            };
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc] initWithJSON:json];
            [[state.moduleStatuses should] equal:@{ @"GoodModule": @YES }];
        });

        it(@"Should ignore non-number lastSentDate", ^{
            NSDictionary *json = @{
                kLastSentKey: @"not a number",
                kModulesKey: modules,
            };
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc] initWithJSON:json];
            [[state.lastSentDate should] beNil];
            [[state.moduleStatuses should] equal:modules];
        });
    });

    context(@"NSCopying", ^{
        it(@"Should produce equal copy", ^{
            AMAModulesStatusReportState *state = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate
                moduleStatuses:modules];
            AMAModulesStatusReportState *copy = [state copy];
            [[copy should] equal:state];
        });
    });

    context(@"Equality", ^{
        it(@"Should be equal for same fields", ^{
            AMAModulesStatusReportState *a = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate moduleStatuses:modules];
            AMAModulesStatusReportState *b = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate moduleStatuses:modules];
            [[a should] equal:b];
            [[theValue([a hash]) should] equal:theValue([b hash])];
        });

        it(@"Should not be equal when modules differ", ^{
            AMAModulesStatusReportState *a = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate moduleStatuses:modules];
            AMAModulesStatusReportState *b = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate moduleStatuses:@{ @"X": @YES }];
            [[a shouldNot] equal:b];
        });

        it(@"Should not be equal when lastSentDate differs", ^{
            AMAModulesStatusReportState *a = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:lastSentDate moduleStatuses:modules];
            AMAModulesStatusReportState *b = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:[NSDate dateWithTimeIntervalSince1970:0] moduleStatuses:modules];
            [[a shouldNot] equal:b];
        });

        it(@"Should handle nil fields in equality", ^{
            AMAModulesStatusReportState *a = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:nil moduleStatuses:nil];
            AMAModulesStatusReportState *b = [[AMAModulesStatusReportState alloc]
                initWithLastSentDate:nil moduleStatuses:nil];
            [[a should] equal:b];
        });
    });
});

SPEC_END
