
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAReportRequestModel.h"
#import "AMAReportEventsBatch.h"
#import "AMARequestModelSplitter.h"
#import "AMASession.h"
#import "AMAEvent.h"

SPEC_BEGIN(AMARequestModelSplitterTests)

describe(@"AMARequestModelSplitter", ^{

    AMAReportRequestModel __block *requestModel = nil;
    NSArray<NSArray <AMAEvent *> *> __block *expectedSplit = nil;
    NSArray<AMAReportRequestModel *> __block *splittedUpModels = nil;
    NSArray *const additionalAPIKeys = @[@"additional_api_key_1", @"additional_api_key_2"];

    context(@"Request of 2 EventsBatches of 3 Events split into 3 parts", ^{

        AMAReportEventsBatch __block *firstEventBatch = nil;
        AMAReportEventsBatch __block *secondEventBatch = nil;

        beforeAll(^{
            NSArray *events = @[
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
            ];

            firstEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"first": @1 }
                                                       events:[events subarrayWithRange:NSMakeRange(0, 3)]];
            secondEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"second": @2 }
                                                       events:[events subarrayWithRange:NSMakeRange(3, 3)]];

            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[ firstEventBatch, secondEventBatch ]];

            splittedUpModels = [AMARequestModelSplitter splitRequestModel:requestModel
                                                                  inParts:3];
            expectedSplit = @[
                [events subarrayWithRange:NSMakeRange(0, 2)],
                [events subarrayWithRange:NSMakeRange(2, 1)],
                [events subarrayWithRange:NSMakeRange(3, 1)],
                [events subarrayWithRange:NSMakeRange(4, 2)],
            ];
        });

        it(@"Should return 3 AMAReportRequestModel in the proper order", ^{
            NSArray *result = @[
                splittedUpModels[0].eventsBatches[0].events,
                splittedUpModels[1].eventsBatches[0].events,
                splittedUpModels[1].eventsBatches[1].events,
                splittedUpModels[2].eventsBatches[0].events,
            ];

            [[result should] equal:expectedSplit];
        });

        context(@"Session", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 2 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[1].session should] equal:secondEventBatch.session];
            });

            it(@"Should be correct for batch 1 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[0].session should] equal:secondEventBatch.session];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 2 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[1].appEnvironment should] equal:secondEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 1 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[0].appEnvironment should] equal:secondEventBatch.appEnvironment];
            });
        });

        context(@"API key", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].apiKey should] equal:requestModel.apiKey];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].apiKey should] equal:requestModel.apiKey];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].apiKey should] equal:requestModel.apiKey];
            });
        });

        context(@"Attribution ID", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].attributionID should] equal:requestModel.attributionID];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].attributionID should] equal:requestModel.attributionID];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].attributionID should] equal:requestModel.attributionID];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appEnvironment should] equal:requestModel.appEnvironment];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appEnvironment should] equal:requestModel.appEnvironment];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].appEnvironment should] equal:requestModel.appEnvironment];
            });
        });

        context(@"App state", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appState should] equal:requestModel.appState];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appState should] equal:requestModel.appState];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].appState should] equal:requestModel.appState];
            });
        });
    });

    context(@"Request of 2 EventsBatches of 1 Event and 4 Events respectively split into 2 parts", ^{

        AMAReportEventsBatch __block *firstEventBatch = nil;
        AMAReportEventsBatch __block *secondEventBatch = nil;

        beforeAll(^{
            NSArray *events = @[
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
            ];

            firstEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"first": @1 }
                                                       events:[events subarrayWithRange:NSMakeRange(0, 1)]];
            secondEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"second": @2 }
                                                       events:[events subarrayWithRange:NSMakeRange(1, 4)]];

            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[ firstEventBatch, secondEventBatch ]];

            splittedUpModels = [AMARequestModelSplitter splitRequestModel:requestModel
                                                                  inParts:2];
            expectedSplit = @[
                [events subarrayWithRange:NSMakeRange(0, 1)],
                [events subarrayWithRange:NSMakeRange(1, 1)],
                [events subarrayWithRange:NSMakeRange(2, 3)],
            ];
        });

        it(@"Should return 2 AMAReportRequestModel in the proper order", ^{

            NSArray *result = @[
                splittedUpModels[0].eventsBatches[0].events,
                splittedUpModels[0].eventsBatches[1].events,
                splittedUpModels[1].eventsBatches[0].events,
            ];

            [[result should] equal:expectedSplit];
        });

        context(@"Session", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 2 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[1].session should] equal:secondEventBatch.session];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].session should] equal:secondEventBatch.session];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 2 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[1].appEnvironment should] equal:secondEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].appEnvironment should] equal:secondEventBatch.appEnvironment];
            });
        });

        context(@"API key", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].apiKey should] equal:requestModel.apiKey];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].apiKey should] equal:requestModel.apiKey];
            });
        });

        context(@"Attribution ID", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].attributionID should] equal:requestModel.attributionID];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].attributionID should] equal:requestModel.attributionID];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appEnvironment should] equal:requestModel.appEnvironment];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appEnvironment should] equal:requestModel.appEnvironment];
            });
        });

        context(@"App state", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appState should] equal:requestModel.appState];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appState should] equal:requestModel.appState];
            });
        });
    });

    context(@"Request of 3 EventsBatches of 4 Events, 1 Event and 1 Event respectively split into 3 parts", ^{

        AMAReportEventsBatch __block *firstEventBatch = nil;
        AMAReportEventsBatch __block *secondEventBatch = nil;
        AMAReportEventsBatch __block *thirdEventBatch = nil;

        beforeAll(^{
            NSArray *events = @[
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
                [AMAEvent mock],
            ];

            firstEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"first": @1 }
                                                       events:[events subarrayWithRange:NSMakeRange(0, 6)]];
            secondEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"second": @2 }
                                                       events:[events subarrayWithRange:NSMakeRange(6, 1)]];
            thirdEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"third": @3 }
                                                       events:[events subarrayWithRange:NSMakeRange(7, 1)]];

            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[
                                                                     firstEventBatch,
                                                                     secondEventBatch,
                                                                     thirdEventBatch
                                                                 ]];

            splittedUpModels = [AMARequestModelSplitter splitRequestModel:requestModel
                                                                  inParts:3];
            expectedSplit = @[
                [events subarrayWithRange:NSMakeRange(0, 2)],
                [events subarrayWithRange:NSMakeRange(2, 2)],
                [events subarrayWithRange:NSMakeRange(4, 2)],
                [events subarrayWithRange:NSMakeRange(6, 1)],
                [events subarrayWithRange:NSMakeRange(7, 1)],
            ];
        });

        it(@"Should return proper AMAReportRequestModel", ^{
            NSArray *result = @[
                splittedUpModels[0].eventsBatches[0].events,
                splittedUpModels[1].eventsBatches[0].events,
                splittedUpModels[2].eventsBatches[0].events,
                splittedUpModels[2].eventsBatches[1].events,
                splittedUpModels[2].eventsBatches[2].events,
            ];
            [[result should] equal:expectedSplit];
        });

        context(@"Session", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 1 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

            it(@"Should be correct for batch 2 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[1].session should] equal:secondEventBatch.session];
            });

            it(@"Should be correct for batch 3 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[2].session should] equal:thirdEventBatch.session];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 1 of model 2", ^{
                [[splittedUpModels[1].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 1 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 2 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[1].appEnvironment should] equal:secondEventBatch.appEnvironment];
            });

            it(@"Should be correct for batch 3 of model 3", ^{
                [[splittedUpModels[2].eventsBatches[2].appEnvironment should] equal:thirdEventBatch.appEnvironment];
            });
        });

        context(@"API key", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].apiKey should] equal:requestModel.apiKey];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].apiKey should] equal:requestModel.apiKey];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].apiKey should] equal:requestModel.apiKey];
            });

        });

        context(@"Attribution ID", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].attributionID should] equal:requestModel.attributionID];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].attributionID should] equal:requestModel.attributionID];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].attributionID should] equal:requestModel.attributionID];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appEnvironment should] equal:requestModel.appEnvironment];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appEnvironment should] equal:requestModel.appEnvironment];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].appEnvironment should] equal:requestModel.appEnvironment];
            });
        });

        context(@"App state", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appState should] equal:requestModel.appState];
            });

            it(@"Should be correct for model 2", ^{
                [[splittedUpModels[1].appState should] equal:requestModel.appState];
            });

            it(@"Should be correct for model 3", ^{
                [[splittedUpModels[2].appState should] equal:requestModel.appState];
            });
        });
    });

    context(@"Request of 1 EventsBatches of 1 Events split into 3 parts", ^{

        AMAReportEventsBatch __block *firstEventBatch = nil;

        beforeAll(^{
            NSArray *events = @[
                [AMAEvent mock],
            ];

            firstEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"first": @1 }
                                                       events:events.copy];

            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[ firstEventBatch ]];

            splittedUpModels = [AMARequestModelSplitter splitRequestModel:requestModel
                                                                  inParts:3];
            expectedSplit = events.copy;
        });

        it(@"Should return proper AMAReportRequestModel", ^{
            NSArray *result = splittedUpModels[0].eventsBatches[0].events;
            [[result should] equal:expectedSplit];
        });

        it(@"Should return only 1 AMAReportRequestModel", ^{
            [[theValue(splittedUpModels.count) should] equal:theValue(1)];
        });

        context(@"Session", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].session should] equal:firstEventBatch.session];
            });

        });

        context(@"App environment", ^{

            it(@"Should be correct for batch 1 of model 1", ^{
                [[splittedUpModels[0].eventsBatches[0].appEnvironment should] equal:firstEventBatch.appEnvironment];
            });

        });

        context(@"API key", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].apiKey should] equal:requestModel.apiKey];
            });

        });

        context(@"Attribution ID", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].attributionID should] equal:requestModel.attributionID];
            });

        });

        context(@"App environment", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appEnvironment should] equal:requestModel.appEnvironment];
            });

        });

        context(@"App state", ^{

            it(@"Should be correct for model 1", ^{
                [[splittedUpModels[0].appState should] equal:requestModel.appState];
            });

        });
    });

    context(@"Request of 0 EventsBatches split into 2 parts", ^{

        beforeAll(^{
            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[]];

            splittedUpModels = [AMARequestModelSplitter splitRequestModel:requestModel
                                                                  inParts:2];
        });

        context(@"API key", ^{

            it(@"Should be correct", ^{
                [[splittedUpModels.firstObject.apiKey should] equal:requestModel.apiKey];
            });
        });

        context(@"Attribution ID", ^{

            it(@"Should be correct", ^{
                [[splittedUpModels.firstObject.attributionID should] equal:requestModel.attributionID];
            });
        });

        context(@"App environment", ^{

            it(@"Should be correct", ^{
                [[splittedUpModels.firstObject.appEnvironment should] equal:requestModel.appEnvironment];
            });
        });

        context(@"App state", ^{

            it(@"Should be correct", ^{
                [[splittedUpModels.firstObject.appState should] equal:requestModel.appState];
            });
        });
    });
    
    context(@"Extract tracking events", ^{
        NSArray *events = @[
            [AMAEvent mock],
            [AMAEvent mock],
            [AMAEvent mock],
            [AMAEvent mock],
            [AMAEvent mock],
            [AMAEvent mock],
        ];
        
        AMAReportEventsBatch __block *firstEventBatch = nil;
        AMAReportEventsBatch __block *secondEventBatch = nil;

        beforeEach(^{
            firstEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"first": @1 }
                                                       events:[events subarrayWithRange:NSMakeRange(0, 3)]];
            secondEventBatch =
                [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                               appEnvironment:@{ @"second": @2 }
                                                       events:[events subarrayWithRange:NSMakeRange(3, 3)]];

            requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:@"Yet another API key"
                                                                 attributionID:@"My cool attribution ID"
                                                                appEnvironment:@{ @"foo": @"bar" }
                                                                      appState:[AMAApplicationState new]
                                                              inMemoryDatabase:NO
                                                             additionalAPIKeys:additionalAPIKeys
                                                                 eventsBatches:@[ firstEventBatch, secondEventBatch ]];
        });
        
        context(@"Two event test", ^{
            NSMutableArray *expectedRegularEvents = [NSMutableArray array];
            NSMutableArray *expectedTrackingEvents = [NSMutableArray array];
            
            for (NSInteger i = 0; i < events.count; i++) {
                AMAEvent *event = events[i];
                BOOL isTracking = (i == 2 || i == 3);
                AMAEventType eventType = isTracking ? AMAEventTypeApplePrivacy : AMAEventTypeClient;
                [event stub:@selector(type) andReturn:theValue(eventType)];
                if (isTracking) {
                    [expectedTrackingEvents addObject:event];
                }
                else {
                    [expectedRegularEvents addObject:event];
                }
            }
            
            it(@"Should equal regular events", ^{
                AMAReportRequestModel *trackingModel = [AMARequestModelSplitter extractTrackingRequestModelFromModel:&requestModel];
                
                NSMutableArray *regularEvents = [NSMutableArray array];
                for (AMAReportEventsBatch *batch in requestModel.eventsBatches) {
                    [regularEvents addObjectsFromArray:batch.events];
                }
                
                [[regularEvents should] equal:expectedRegularEvents];
            });
            
            it(@"Should equal tracking events", ^{
                AMAReportRequestModel *trackingModel = [AMARequestModelSplitter extractTrackingRequestModelFromModel:&requestModel];
                
                
                NSMutableArray *trackingEvents = [NSMutableArray array];
                for (AMAReportEventsBatch *batch in trackingModel.eventsBatches) {
                    [trackingEvents addObjectsFromArray:batch.events];
                }
                
                [[trackingEvents should] equal: expectedTrackingEvents];
            });
            
        });
        
        
        
    });
});

SPEC_END
