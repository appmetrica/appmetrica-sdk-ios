
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMABoundMappingChecker.h"
#import "AMAEventSumBoundBasedModelHelper.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMABoundMapping.h"

SPEC_BEGIN(AMAEventBoundBasedModelHelperTests)

describe(@"AMAEventBoundBasedModelHelper", ^{

    AMABoundMappingChecker *__block boundMappingChecker = nil;
    AMAEventSumBoundBasedModelHelper *__block helper = nil;
    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    beforeEach(^{
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
        [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
        boundMappingChecker = [AMABoundMappingChecker nullMock];
        helper = [[AMAEventSumBoundBasedModelHelper alloc] initWithBoundMappingChecker:boundMappingChecker];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });

    context(@"Should update sum", ^{
        it(@"Was zero", ^{
            [persistentConfiguration stub:@selector(eventSum) andReturn:[NSDecimalNumber zero]];
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [[persistentConfiguration should] receive:@selector(setEventSum:) withArguments:addition];
            [helper calculateNewConversionValue:addition boundMappings:@[]];
        });
        it(@"Was non-zero", ^{
            [persistentConfiguration stub:@selector(eventSum) andReturn:[NSDecimalNumber decimalNumberWithString:@"22"]];
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [[persistentConfiguration should] receive:@selector(setEventSum:) withArguments:[NSDecimalNumber decimalNumberWithString:@"77"]];
            [helper calculateNewConversionValue:addition boundMappings:@[]];
        });
        it(@"Should use safe adding", ^{
            NSDecimalNumber *oldSum = [NSDecimalNumber decimalNumberWithString:@"22"];
            [persistentConfiguration stub:@selector(eventSum) andReturn:oldSum];
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyAdding:or:) withArguments:oldSum, addition, oldSum];
            [helper calculateNewConversionValue:addition boundMappings:@[]];
        });
    });
    context(@"Return value", ^{
        NSArray *boundMappings = @[ [AMABoundMapping nullMock] ];
        it(@"Should ask bound mapping checker with right arguments", ^{
            [persistentConfiguration stub:@selector(eventSum) andReturn:[NSDecimalNumber decimalNumberWithString:@"22"]];
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [[boundMappingChecker should] receive:@selector(check:mappings:)
                                    withArguments:[NSDecimalNumber decimalNumberWithString:@"77"], boundMappings];
            [helper calculateNewConversionValue:addition boundMappings:boundMappings];
        });
        it(@"Should return nil", ^{
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [boundMappingChecker stub:@selector(check:mappings:) andReturn:nil];
            [[[helper calculateNewConversionValue:addition boundMappings:boundMappings] should] beNil];
        });
        it(@"Should return non nil", ^{
            NSDecimalNumber *result = [NSDecimalNumber decimalNumberWithString:@"88"];
            NSDecimalNumber *addition = [NSDecimalNumber decimalNumberWithString:@"55"];
            [boundMappingChecker stub:@selector(check:mappings:) andReturn:result];
            [[[helper calculateNewConversionValue:addition boundMappings:boundMappings] should] equal:result];

        });
    });
});

SPEC_END
