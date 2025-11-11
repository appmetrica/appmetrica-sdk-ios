
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMADispatchQueueTestHelper.h"

static NSString *const kAMAQueuesFactoryTestClassName = @"AMAQueuesFactoryTestClass";

@interface AMAQueuesFactoryTestClass : NSObject
@end

@implementation AMAQueuesFactoryTestClass
@end

SPEC_BEGIN(AMAQueuesFactoryTests)

describe(@"AMAQueuesFactory", ^{

    NSObject *__block identifier = nil;
    dispatch_queue_t __block queue = nil;

    beforeEach(^{
        identifier = [[AMAQueuesFactoryTestClass alloc] init];
        queue = nil;
    });

    it(@"Should return queue with correct name", ^{
        queue = [AMAQueuesFactory serialQueueForIdentifierObject:identifier domain:@"io.appmetrica.CoreUtils"];
        const char *label = dispatch_queue_get_label(queue);
        NSString *queueName = [NSString stringWithCString:label encoding:NSUTF8StringEncoding];
        [[queueName should] equal:@"io.appmetrica.CoreUtils.AMAQueuesFactoryTestClass.Queue"];
    });

    it(@"Should return serial queue", ^{
        queue = [AMAQueuesFactory serialQueueForIdentifierObject:identifier domain:@"io.appmetrica.CoreUtils"];
        [[theValue([AMADispatchQueueTestHelper isQueueSerial:queue]) should] beYes];
    });

});

SPEC_END

