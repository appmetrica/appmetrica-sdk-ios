#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <StoreKit/StoreKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMATransactionObserver.h"

SPEC_BEGIN(AMATransactionObserverTests)

describe(@"AMATransactionObserver", ^{
    
    SKPaymentQueue *__block paymentQueueMock = nil;
    AMATransactionObserver *__block observer = nil;
    NSObject<AMATransactionObserverDelegate> *__block delegate = nil;
    
    beforeEach(^{
        paymentQueueMock = [SKPaymentQueue mock];
        [paymentQueueMock stub:@selector(removeTransactionObserver:)];
        
        [SKPaymentQueue stub:@selector(defaultQueue) andReturn:paymentQueueMock];
        
        delegate = [KWMock mockForProtocol:@protocol(AMATransactionObserverDelegate)];
        observer = [[AMATransactionObserver alloc] initWithDelegate:delegate];
    });
    afterEach(^{
        [SKPaymentQueue clearStubs];
    });
    
    context(@"Observing", ^{
        it(@"Should start observing", ^{
            [[paymentQueueMock should] receive:@selector(addTransactionObserver:) withArguments:observer];
            [observer startObservingTransactions];
        });
        
        it(@"Should not start observing for the second time", ^{
            [[paymentQueueMock should] receive:@selector(addTransactionObserver:) withArguments:observer];
            [observer startObservingTransactions];
            [observer startObservingTransactions];
        });
        
        it(@"Should not stop observing if it was not started", ^{
            [[paymentQueueMock shouldNot] receive:@selector(removeTransactionObserver:)];
            [observer stopObservingTransactions];
        });
        
        it(@"Should stop after it was started", ^{
            [paymentQueueMock stub:@selector(addTransactionObserver:)];
            [observer startObservingTransactions];
            [[paymentQueueMock should] receive:@selector(removeTransactionObserver:) withArguments:observer];
            [observer stopObservingTransactions];
        });
        
        it(@"Should stop for the seconds time after it was started", ^{
            [paymentQueueMock stub:@selector(addTransactionObserver:)];
            [observer startObservingTransactions];
            [[paymentQueueMock should] receive:@selector(removeTransactionObserver:) withArguments:observer];
            [observer stopObservingTransactions];
            [observer stopObservingTransactions];
        });
        
        it(@"Should start after it was stopped", ^{
            [paymentQueueMock stub:@selector(addTransactionObserver:)];
            [observer startObservingTransactions];
            [paymentQueueMock stub:@selector(removeTransactionObserver:)];
            [observer stopObservingTransactions];
            [[paymentQueueMock should] receive:@selector(addTransactionObserver:) withArguments:observer];
            [observer startObservingTransactions];
        });
        
        it(@"Should not start observing for the second time after it was stopped", ^{
            [paymentQueueMock stub:@selector(addTransactionObserver:)];
            [observer startObservingTransactions];
            [paymentQueueMock stub:@selector(removeTransactionObserver:)];
            [observer stopObservingTransactions];
            [[paymentQueueMock should] receive:@selector(addTransactionObserver:) withArguments:observer];
            [observer startObservingTransactions];
            [observer startObservingTransactions];
        });
    });
    
    context(@"Transactions", ^{
        
        AMAMutableSKPaymentTransaction *__block transaction = nil;
        
        beforeEach(^{
            transaction = [[AMAMutableSKPaymentTransaction alloc] init];
        });
        
        it(@"Should report of new Purchased transaction", ^{
            transaction.transactionState = SKPaymentTransactionStatePurchased;
            
            [[delegate should] receive:@selector(transactionObserver:didCaptureTransaction:withState:)
                         withArguments: observer, transaction, theValue(AMATransactionStatePurchased)];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction ]];
        });
        
        it(@"Should report of new Restored transaction", ^{
            transaction.transactionState = SKPaymentTransactionStateRestored;
            
            [[delegate should] receive:@selector(transactionObserver:didCaptureTransaction:withState:)
                         withArguments: observer, transaction, theValue(AMATransactionStateRestored)];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction ]];
        });
        
        it(@"Should not report of Purchasing transaction", ^{
            transaction.transactionState = SKPaymentTransactionStatePurchasing;
            [[delegate shouldNot] receive:@selector(transactionObserver:didCaptureTransaction:withState:)];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction ]];
        });
        
        it(@"Should not report of Failed transaction", ^{
            transaction.transactionState = SKPaymentTransactionStateFailed;
            [[delegate shouldNot] receive:@selector(transactionObserver:didCaptureTransaction:withState:)];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction ]];
        });
        
        it(@"Should not report of Deferred transaction", ^{
            transaction.transactionState = SKPaymentTransactionStateDeferred;
            [[delegate shouldNot] receive:@selector(transactionObserver:didCaptureTransaction:withState:)];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction ]];
        });
        
        it(@"Should report of all valid transactions in the queue", ^{
            AMAMutableSKPaymentTransaction *second = [[AMAMutableSKPaymentTransaction alloc] init];
            AMAMutableSKPaymentTransaction *third = [[AMAMutableSKPaymentTransaction alloc] init];
            second.transactionState = SKPaymentTransactionStatePurchased;
            transaction.transactionState = SKPaymentTransactionStatePurchased;
            third.transactionState = SKPaymentTransactionStatePurchasing;
            
            [[delegate should] receive:@selector(transactionObserver:didCaptureTransaction:withState:) withCount:2];
            [observer paymentQueue:paymentQueueMock updatedTransactions:@[ transaction, second, third ]];
        });
    });
    it(@"Should conform to SKPaymentTransactionObserver", ^{
        [[observer should] conformToProtocol:@protocol(SKPaymentTransactionObserver)];
    });
});

SPEC_END
