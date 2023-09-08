
#import <Kiwi/Kiwi.h>
#import "AMARevenueInfoProcessor.h"
#import "AMARevenueInfoModelFormatter.h"
#import "AMARevenueInfoModelValidator.h"
#import "AMARevenueInfoModelSerializer.h"
#import "AMARevenueInfo.h"
#import "AMARevenueInfoModel.h"
#import "AMATruncatedDataProcessingResult.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMARevenueInfoProcessorTests)

describe(@"AMARevenueInfoProcessor", ^{

    NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger const bytesTruncated = 23;

    AMARevenueInfoModel *__block revenueModel = nil;
    AMARevenueInfoModel *__block formattedRevenueModel = nil;
    AMARevenueInfoModelFormatter *__block formatter = nil;
    AMARevenueInfoModelValidator *__block validator = nil;
    AMARevenueInfoModelSerializer *__block serializer = nil;
    AMARevenueInfoProcessor *__block processor = nil;

    beforeEach(^{
        revenueModel = [AMARevenueInfoModel nullMock];
        formattedRevenueModel = [AMARevenueInfoModel nullMock];
        [formattedRevenueModel stub:@selector(bytesTruncated) andReturn:theValue(bytesTruncated)];

        formatter = [AMARevenueInfoModelFormatter nullMock];
        [formatter stub:@selector(formattedRevenueModel:error:) andReturn:formattedRevenueModel];

        validator = [AMARevenueInfoModelValidator nullMock];
        [validator stub:@selector(validateRevenueInfoModel:error:) andReturn:theValue(YES)];

        serializer = [AMARevenueInfoModelSerializer nullMock];
        [serializer stub:@selector(dataWithRevenueInfoModel:) andReturn:data];

        processor = [[AMARevenueInfoProcessor alloc] initWithFormatter:formatter
                                                             validator:validator
                                                            serializer:serializer];
    });
    context(@"Valid", ^{
        it(@"Should format model", ^{
            [[formatter should] receive:@selector(formattedRevenueModel:error:)
                          withArguments:revenueModel, kw_any()];
            [processor processRevenueModel:revenueModel error:nil];
        });
        it(@"Should validate model", ^{
            [[validator should] receive:@selector(validateRevenueInfoModel:error:) withArguments:formattedRevenueModel, kw_any()];
            [processor processRevenueModel:revenueModel error:nil];
        });
        it(@"Should serialize model", ^{
            [[serializer should] receive:@selector(dataWithRevenueInfoModel:) withArguments:formattedRevenueModel];
            [processor processRevenueModel:revenueModel error:nil];
        });
        it(@"Should return valid data", ^{
            [[[processor processRevenueModel:revenueModel error:nil].data should] equal:data];
        });
        it(@"Should return valid truncated bytes count", ^{
            NSUInteger returnedBytesTruncated = [processor processRevenueModel:revenueModel error:nil].bytesTruncated;
            [[theValue(returnedBytesTruncated) should] equal:theValue(bytesTruncated)];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [processor processRevenueModel:revenueModel error:&error];
            [[error should] beNil];
        });
    });
    context(@"Format error", ^{
        NSError *__block expectedError = nil;
        beforeEach(^{
            expectedError = [NSError nullMock];
            [formatter stub:@selector(formattedRevenueModel:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                return nil;
            }];
        });
        it(@"Should return nil", ^{
            [[[processor processRevenueModel:revenueModel error:nil] should] beNil];
        });
        it(@"Should return nil if nil model was passed", ^{
            [[[processor processRevenueModel:nil error:nil] should] beNil];
        });
        it(@"Should fill error", ^{
            NSError *error = nil;
            [processor processRevenueModel:revenueModel error:&error];
            [[error should] equal:expectedError];
        });
    });
    context(@"Validation error", ^{
        NSError *__block expectedError = nil;
        beforeEach(^{
            expectedError = [NSError nullMock];
            [formatter stub:@selector(formattedRevenueModel:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                return nil;
            }];
        });
        it(@"Should return nil", ^{
            [[[processor processRevenueModel:revenueModel error:nil] should] beNil];
        });
        it(@"Should fill error", ^{
            NSError *error = nil;
            [processor processRevenueModel:revenueModel error:&error];
            [[error should] equal:expectedError];
        });
    });

});

SPEC_END
