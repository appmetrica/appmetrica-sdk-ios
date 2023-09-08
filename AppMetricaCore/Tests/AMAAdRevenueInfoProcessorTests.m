
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAdRevenueInfoProcessor.h"
#import "AMAAdRevenueInfoModelFormatter.h"
#import "AMAAdRevenueInfoModelValidator.h"
#import "AMAAdRevenueInfoModelSerializer.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAdRevenueInfoModel.h"
#import "AMATruncatedDataProcessingResult.h"

SPEC_BEGIN(AMAAdRevenueInfoProcessorTests)

describe(@"AMAAdRevenueInfoProcessor", ^{

    NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger const bytesTruncated = 28;

    AMAAdRevenueInfoModel *__block adRevenueModel = nil;
    AMAAdRevenueInfoModel *__block formattedAdRevenueModel = nil;
    AMAAdRevenueInfoModelFormatter *__block formatter = nil;
    AMAAdRevenueInfoModelValidator *__block validator = nil;
    AMAAdRevenueInfoModelSerializer *__block serializer = nil;
    AMAAdRevenueInfoProcessor *__block processor = nil;

    beforeEach(^{
        adRevenueModel = [AMAAdRevenueInfoModel nullMock];
        formattedAdRevenueModel = [AMAAdRevenueInfoModel nullMock];
        [formattedAdRevenueModel stub:@selector(bytesTruncated) andReturn:theValue(bytesTruncated)];

        formatter = [AMAAdRevenueInfoModelFormatter nullMock];
        [formatter stub:@selector(formattedAdRevenueModel:) andReturn:formattedAdRevenueModel];

        validator = [AMAAdRevenueInfoModelValidator nullMock];
        [validator stub:@selector(validateAdRevenueInfoModel:error:) andReturn:theValue(YES)];

        serializer = [AMAAdRevenueInfoModelSerializer nullMock];
        [serializer stub:@selector(dataWithAdRevenueInfoModel:) andReturn:data];

        processor = [[AMAAdRevenueInfoProcessor alloc] initWithFormatter:formatter
                                                               validator:validator
                                                              serializer:serializer];
    });
    context(@"Valid", ^{
        it(@"Should format model", ^{
            [[formatter should] receive:@selector(formattedAdRevenueModel:)
                          withArguments:adRevenueModel, kw_any()];
            [processor processAdRevenueModel:adRevenueModel error:nil];
        });
        it(@"Should validate model", ^{
            [[validator should] receive:@selector(validateAdRevenueInfoModel:error:)
                          withArguments:formattedAdRevenueModel, kw_any()];
            [processor processAdRevenueModel:adRevenueModel error:nil];
        });
        it(@"Should serialize model", ^{
            [[serializer should] receive:@selector(dataWithAdRevenueInfoModel:) withArguments:formattedAdRevenueModel];
            [processor processAdRevenueModel:adRevenueModel error:nil];
        });
        it(@"Should return valid data", ^{
            [[[processor processAdRevenueModel:adRevenueModel error:nil].data should] equal:data];
        });
        it(@"Should return valid truncated bytes count", ^{
            NSUInteger returnedBytesTruncated = [processor processAdRevenueModel:adRevenueModel error:nil].bytesTruncated;
            [[theValue(returnedBytesTruncated) should] equal:theValue(bytesTruncated)];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [processor processAdRevenueModel:adRevenueModel error:&error];
            [[error should] beNil];
        });
    });
    context(@"Process error", ^{
        NSError *__block expectedError = nil;
        beforeEach(^{
            expectedError = [NSError nullMock];
            [processor stub:@selector(processAdRevenueModel:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                return nil;
            }];
        });
        it(@"Should return nil", ^{
            [[[processor processAdRevenueModel:adRevenueModel error:nil] should] beNil];
        });
        it(@"Should return nil if nil model was passed", ^{
            [[[processor processAdRevenueModel:nil error:nil] should] beNil];
        });
        it(@"Should fill error", ^{
            NSError *error = nil;
            [processor processAdRevenueModel:adRevenueModel error:&error];
            [[error should] equal:expectedError];
        });
    });
    context(@"Formatting error", ^{
        beforeEach(^{
            [formatter stub:@selector(formattedAdRevenueModel:) andReturn:nil];
        });
        it(@"Should return nil", ^{
            [[[processor processAdRevenueModel:adRevenueModel error:nil] should] beNil];
        });
    });
    context(@"Validation error", ^{
        NSError *__block expectedError = nil;
        beforeEach(^{
            expectedError = [NSError nullMock];
            [validator stub:@selector(validateAdRevenueInfoModel:error:) withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                return nil;
            }];
        });
        it(@"Should return nil", ^{
            [[[processor processAdRevenueModel:adRevenueModel error:nil] should] beNil];
        });
        it(@"Should fill error", ^{
            NSError *error = nil;
            [processor processAdRevenueModel:adRevenueModel error:&error];
            [[error should] equal:expectedError];
        });
    });

});

SPEC_END
