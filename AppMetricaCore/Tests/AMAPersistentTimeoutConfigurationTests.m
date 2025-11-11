
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMAPersistentTimeoutConfiguration.h"
#import "AMATimeoutConfiguration.h"

SPEC_BEGIN(AMAPersistentTimeoutConfigurationTests)

describe(@"AMAPersistentTimeoutConfiguration", ^{
    
    NSObject<AMAKeyValueStoring> *__block storageMock = nil;
    AMAPersistentTimeoutConfiguration *__block configuration = nil;

    beforeEach(^{
        storageMock = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
        configuration = [[AMAPersistentTimeoutConfiguration alloc] initWithStorage:storageMock];
    });
        
    context(@"Fetching timeout configuration", ^{
    
        it(@"Should use provided timestamp storage key", ^{
            [[storageMock should] receive:@selector(dateForKey:error:)
                                        withArguments:@"testHost.timeout.date", kw_any()];
            [configuration timeoutConfigForHostType:@"testHost"];
        });
        it(@"Should use provided count storage key", ^{
            [[storageMock should] receive:@selector(longLongNumberForKey:error:)
                                        withArguments:@"testHost.timeout.count", kw_any()];
            [configuration timeoutConfigForHostType:@"testHost"];
        });
        it(@"Should create timeout configuration with data from storage", ^{
            NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:10000];
            NSNumber *expectedCount = @(10);
            [storageMock stub:@selector(dateForKey:error:) andReturn:expectedDate];
            [storageMock stub:@selector(longLongNumberForKey:error:) andReturn:expectedCount];
            AMATimeoutConfiguration *timeout = [configuration timeoutConfigForHostType:@"testHost"];
            
            [[timeout.limitDate should] equal:expectedDate];
            [[theValue(timeout.count) should] equal:expectedCount];
        });
    });
         
    context(@"Saving timeout configuration", ^{
    
        it(@"Should use provided timestamp storage key", ^{
            [[storageMock should] receive:@selector(saveDate:forKey:error:)
                            withArguments:kw_any(), @"testHost.timeout.date", kw_any()];
            [configuration saveTimeoutConfig:[AMATimeoutConfiguration nullMock] forHostType:@"testHost"];
        });
        it(@"Should use provided count storage key", ^{
            [[storageMock should] receive:@selector(saveLongLongNumber:forKey:error:)
                            withArguments:kw_any(), @"testHost.timeout.count", kw_any()];
            [configuration saveTimeoutConfig:[AMATimeoutConfiguration nullMock] forHostType:@"testHost"];
        });
        it(@"Shoould save data from timeout configuration", ^{
            NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:10000];
            NSUInteger expectedCount = 10;
            AMATimeoutConfiguration *timeout = [[AMATimeoutConfiguration alloc] initWithLimitDate:expectedDate
                                                                                            count:expectedCount];
            
            [[storageMock should] receive:@selector(saveDate:forKey:error:)
                            withArguments:expectedDate, kw_any(), kw_any()];
            [[storageMock should] receive:@selector(saveLongLongNumber:forKey:error:)
                            withArguments:theValue(expectedCount), kw_any(), kw_any()];
            [configuration saveTimeoutConfig:timeout forHostType:@"testHost"];
        });
    });
});

SPEC_END
