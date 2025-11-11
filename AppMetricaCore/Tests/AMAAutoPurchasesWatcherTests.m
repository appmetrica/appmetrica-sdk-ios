
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAutoPurchasesWatcher.h"
#import "AMAReporter.h"
#import "AMATransactionObserver.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMARevenueInfoModelFactory.h"
#import "AMARevenueInfoModel.h"

SPEC_BEGIN(AMAAutoPurchasesWatcherTests)

describe(@"AMAAutoPurchasesWatcher", ^{
    
    AMAAutoPurchasesWatcher *__block watcher = nil;
    
    AMAReporter *__block reporter = nil;
    AMATransactionObserver *__block observer = nil;
    AMAMetricaConfiguration *__block configuration = nil;
    AMARevenueInfoModelFactory *__block factory= nil;
    
    id<AMAAsyncExecuting> __block executor = nil;
    
    __auto_type createWatcher = ^void {
        watcher = [[AMAAutoPurchasesWatcher alloc] initWithExecutor:executor
                                                transactionObserver:observer
                                                            factory:factory];
    };
    
    beforeEach(^{
        reporter = [AMAReporter mock];
        observer = [AMATransactionObserver mock];
        executor = [[AMACurrentQueueExecutor alloc] init];
        factory = [AMARevenueInfoModelFactory nullMock];
        
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configuration = [AMAMetricaConfiguration sharedInstance];

        createWatcher();
    });
    
    context(@"Activation", ^{
        
        it(@"Should start observing", ^{
            [[observer should] receive:@selector(startObservingTransactions)];
            [watcher startWatchingWithReporter:reporter];
        });
    });
    
    context(@"Transactions", ^{
        
        AMAProductRequestor *__block requestor = nil;
        
        beforeEach(^{
            requestor = [AMAProductRequestor nullMock];
            [AMAProductRequestor stubInstance:requestor forInit:@selector(initWithTransaction:transactionState:delegate:)];
        });
        
        it(@"Should create product requestor on new transaction", ^{
            [watcher transactionObserver:observer didCaptureTransaction:KWMock.mock withState:AMATransactionStateUndefined];
        });
        
        it(@"Should request product information on new transaction", ^{
            [[requestor should] receive:@selector(requestProductInformation)];
            [watcher transactionObserver:observer didCaptureTransaction:KWMock.mock withState:AMATransactionStateUndefined];
        });

        context(@"Products", ^{
            it(@"Should create model on success reposonse", ^{
                id product = KWMock.nullMock;
                
                [[factory should] receive:@selector(revenueInfoModelWithTransaction:state:product:)
                            withArguments:kw_any(), kw_any(), product];
                [watcher productRequestor:requestor didRecieveProduct:product];
            });
            
            it(@"Should create model on failed reposonse", ^{
                [[factory should] receive:@selector(revenueInfoModelWithTransaction:state:product:)
                            withArguments:kw_any(), kw_any(), KWNull.null];
                [watcher productRequestorDidFailToFetchProduct:requestor];
            });
            
            context(@"Reporting", ^{
                
                AMARevenueInfoModel *__block revenueMock = nil;
                
                beforeEach(^{
                    revenueMock = [AMARevenueInfoModel mock];
                    [factory stub:@selector(revenueInfoModelWithTransaction:state:product:) andReturn:revenueMock];
                    [observer stub:@selector(startObservingTransactions)];
                    [watcher startWatchingWithReporter:reporter];
                });
                
                it(@"Should report model on success", ^{
                    [[reporter should] receive:@selector(reportAutoRevenue:onFailure:)
                                 withArguments:revenueMock, kw_any()];
                    [watcher productRequestor:requestor didRecieveProduct:KWMock.nullMock];
                });
                
                it(@"Should report model on failure", ^{
                    [[reporter should] receive:@selector(reportAutoRevenue:onFailure:)
                                 withArguments:revenueMock, kw_any()];
                    [watcher productRequestorDidFailToFetchProduct:requestor];
                });
            });
        });
    });
    context(@"Protocols", ^{
        it(@"Should conform to AMATransactionObserverDelegate", ^{
            [[watcher should] conformToProtocol:@protocol(AMATransactionObserverDelegate)];
        });
        it(@"Should conform to AMAProductRequestorDelegate", ^{
            [[watcher should] conformToProtocol:@protocol(AMAProductRequestorDelegate)];
        });
    });
});

SPEC_END
