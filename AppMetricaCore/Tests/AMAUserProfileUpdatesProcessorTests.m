
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAUserProfileUpdatesProcessor.h"
#import "AMAUserProfileModelSerializer.h"
#import "AMAAttributeUpdate.h"
#import "AMAAttributeUpdateValidating.h"
#import "AMAUserProfileUpdate.h"
#import "AMAUserProfileModel.h"
#import "AMAErrorsFactory.h"

SPEC_BEGIN(AMAUserProfileUpdatesProcessorTests)

describe(@"AMAUserProfileUpdatesProcessor", ^{

    NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];

    NSError *__block emptyUserProfileError = nil;
    NSArray *__block updates = nil;
    AMAUserProfileModel *__block model = nil;
    AMAUserProfileModelSerializer *__block serializer = nil;
    AMAUserProfileUpdatesProcessor *__block processor = nil;

    beforeEach(^{
        emptyUserProfileError = [NSError nullMock];
        [AMAErrorsFactory stub:@selector(emptyUserProfileError) andReturn:emptyUserProfileError];

        model = [AMAUserProfileModel stubbedNullMockForDefaultInit];

        serializer = [AMAUserProfileModelSerializer nullMock];
        [serializer stub:@selector(dataWithModel:) andReturn:data];

        processor = [[AMAUserProfileUpdatesProcessor alloc] initWithSerializer:serializer];
    });
    afterEach(^{
        [AMAErrorsFactory clearStubs];
        [AMAUserProfileModel clearStubs];
    });

    context(@"No updates", ^{
        beforeEach(^{
            updates = @[];
        });
        it(@"Should return no data", ^{
            [[[processor dataWithUpdates:updates error:nil] should] beNil];
        });
        it(@"Should provide error", ^{
            NSError *error = nil;
            [processor dataWithUpdates:updates error:&error];
            [[error should] equal:emptyUserProfileError];
        });
    });
    context(@"With updates", ^{
        NSObject<AMAAttributeUpdateValidating> *__block firstValidator = nil;
        NSObject<AMAAttributeUpdateValidating> *__block secondValidator = nil;
        AMAAttributeUpdate *__block firstAttributeUpdate = nil;
        AMAAttributeUpdate *__block secondAttributeUpdate = nil;

        beforeEach(^{
            firstAttributeUpdate = [AMAAttributeUpdate nullMock];
            secondAttributeUpdate = [AMAAttributeUpdate nullMock];
            firstValidator = [KWMock nullMockForProtocol:@protocol(AMAAttributeUpdateValidating)];
            [firstValidator stub:@selector(validateUpdate:model:) andReturn:theValue(YES)];
            secondValidator = [KWMock nullMockForProtocol:@protocol(AMAAttributeUpdateValidating)];
            [secondValidator stub:@selector(validateUpdate:model:) andReturn:theValue(YES)];

            AMAUserProfileUpdate *firstUpdate =
                [[AMAUserProfileUpdate alloc] initWithAttributeUpdate:firstAttributeUpdate
                                                           validators:@[firstValidator]];
            AMAUserProfileUpdate *secondUpdate =
                [[AMAUserProfileUpdate alloc] initWithAttributeUpdate:secondAttributeUpdate
                                                           validators:@[secondValidator]];
            updates = @[ firstUpdate, secondUpdate ];
        });
        it(@"Should apply first update", ^{
            [[firstAttributeUpdate should] receive:@selector(applyToModel:) withArguments:model];
            [processor dataWithUpdates:updates error:nil];
        });
        it(@"Should apply second update", ^{
            [[secondAttributeUpdate should] receive:@selector(applyToModel:) withArguments:model];
            [processor dataWithUpdates:updates error:nil];
        });
        context(@"Invalid first update", ^{
            it(@"Should not apply first update", ^{
                [firstValidator stub:@selector(validateUpdate:model:) andReturn:theValue(NO)];
                [[firstAttributeUpdate shouldNot] receive:@selector(applyToModel:) withArguments:model];
                [processor dataWithUpdates:updates error:nil];
            });
            it(@"Should apply second update", ^{
                [[secondAttributeUpdate should] receive:@selector(applyToModel:) withArguments:model];
                [processor dataWithUpdates:updates error:nil];
            });
        });
        it(@"Should apply all updates before serialization", ^{
            BOOL __block applied = NO;
            [secondAttributeUpdate stub:@selector(applyToModel:) withBlock:^id(NSArray *params) {
                applied = YES;
                return nil;
            }];
            [serializer stub:@selector(dataWithModel:) withBlock:^id(NSArray *params) {
                [[theValue(applied) should] beYes];
                return data;
            }];
            [processor dataWithUpdates:updates error:nil];
        });
        it(@"Should serialize data", ^{
            [[serializer should] receive:@selector(dataWithModel:) withArguments:model];
            [processor dataWithUpdates:updates error:nil];
        });
        it(@"Should return serialized data", ^{
            [[[processor dataWithUpdates:updates error:nil] should] equal:data];
        });
    });

});

SPEC_END
