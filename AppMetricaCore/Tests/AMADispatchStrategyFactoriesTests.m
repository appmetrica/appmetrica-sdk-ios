
#import <Kiwi/Kiwi.h>
#import "AMADispatchStrategiesFactory.h"
#import "AMAUrgentEventCountDispatchStrategy.h"
#import "AMAReporterStorage.h"
#import "AMAReportExecutionConditionChecker.h"

SPEC_BEGIN(AMADispatchStrategiesFactoryTestsSpec)

describe(@"AMADispatchStrategiesFactoryTests", ^{
    it(@"Test important strategy creation", ^{
        id reporterStorageMock = [KWMock nullMockForClass:[AMAReporterStorage class]];
        id delegateMock = [KWMock mockForProtocol:@protocol(AMADispatchStrategyDelegate)];
        id executionConditionChecker = [KWMock nullMockForProtocol:@protocol(AMAReportExecutionConditionChecker)];
        NSArray *strategies = [AMADispatchStrategiesFactory strategiesForStorage:reporterStorageMock
                                                                        typeMask:AMADispatchStrategyTypeUrgent
                                                                        delegate:delegateMock
                                                       executionConditionChecker:executionConditionChecker];
        [[[[strategies firstObject] class] should] equal:[AMAUrgentEventCountDispatchStrategy class]];
    });
});

SPEC_END
