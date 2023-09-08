
#import "AMACore.h"
#import "AMARequestModelSplitter.h"
#import "AMAReportRequestModel.h"
#import "AMAReportEventsBatch.h"

@implementation AMARequestModelSplitter

#pragma mark - Public -

+ (NSArray<AMAReportRequestModel *> *)splitRequestModel:(AMAReportRequestModel *)requestModel
                                                inParts:(NSUInteger)numberOfParts
{
    if (requestModel.eventsBatches.count == 0) {
        return @[ [self reportRequestModelWithModel:requestModel eventsBatches:@[]] ];
    }

    NSMutableArray<AMAReportEventsBatch *> *batchesQueue = requestModel.eventsBatches.mutableCopy;

    NSUInteger eventsCount = requestModel.events.count;
    NSUInteger eventsInPayload = MAX(eventsCount / numberOfParts, 1U);

    NSMutableArray<AMAReportRequestModel *> *splittedUpModels = [NSMutableArray array];

    for (NSUInteger i = 0; i < numberOfParts && batchesQueue.count > 0; ++i) {
        NSUInteger tempEventsCount = 0;
        NSUInteger tempEventsInPayload = eventsInPayload;
        NSMutableArray<AMAReportEventsBatch *> *tempBatches = [NSMutableArray array];

        while (tempEventsCount < tempEventsInPayload) {
            NSUInteger needed = 0;
            if (i == numberOfParts - 1) {
                needed = eventsCount;
                tempEventsInPayload = eventsCount;
            }
            else {
                needed = eventsInPayload - tempEventsCount;
            }
            NSArray<AMAReportEventsBatch *> *splittedBatches = [self splitBatch:batchesQueue.firstObject
                                                                eventsInPayload:needed];
            [batchesQueue removeObjectAtIndex:0];

            [tempBatches addObject:splittedBatches.firstObject];
            if (splittedBatches.count == 2) {
                [batchesQueue insertObject:splittedBatches.lastObject atIndex:0];
            }

            tempEventsCount += splittedBatches.firstObject.events.count;
        }

        eventsCount -= tempEventsCount;
        [splittedUpModels addObject:[self reportRequestModelWithModel:requestModel
                                                        eventsBatches:tempBatches.copy]];
    }

    return [splittedUpModels copy];
}

#pragma mark - Private -

+ (AMAReportRequestModel *)reportRequestModelWithModel:(AMAReportRequestModel *)requestModel
                                         eventsBatches:(NSArray<AMAReportEventsBatch *> *)eventsBatches
{
    return [requestModel copyWithEventsBatches:eventsBatches];
}

+ (AMAReportEventsBatch *)eventsBatchWithBatch:(AMAReportEventsBatch *)eventsBatch events:(NSArray<AMAEvent *> *)events
{
    return [[AMAReportEventsBatch alloc] initWithSession:eventsBatch.session
                                          appEnvironment:eventsBatch.appEnvironment
                                                  events:events];
}

+ (NSArray<AMAReportEventsBatch *> *)splitBatch:(AMAReportEventsBatch *)eventsBatch
                                eventsInPayload:(NSUInteger)eventsInPayload
{
    NSArray<AMAEvent *> *events = eventsBatch.events;
    if (eventsBatch.events.count <= eventsInPayload) {
        return @[ [self eventsBatchWithBatch:eventsBatch events:events] ];
    }
    else {
        NSRange firstRange = NSMakeRange(0, eventsInPayload);
        NSRange secondRange = NSMakeRange(eventsInPayload, events.count - eventsInPayload);
        return @[
            [self eventsBatchWithBatch:eventsBatch events:[events subarrayWithRange:firstRange]],
            [self eventsBatchWithBatch:eventsBatch events:[events subarrayWithRange:secondRange]]
        ];
    }
}


@end
