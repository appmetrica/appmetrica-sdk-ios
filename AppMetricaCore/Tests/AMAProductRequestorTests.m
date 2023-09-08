#import <Kiwi/Kiwi.h>
#import <StoreKit/StoreKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAProductRequestor.h"

SPEC_BEGIN(AMAProductRequestorTests)

describe(@"AMAProductRequestor", ^{
    
    AMAMutableSKPaymentTransaction *__block transaction = nil;
    AMAProductRequestor *__block requestor = nil;
    NSObject<AMAProductRequestorDelegate> *__block delegate = nil;
    SKProductsRequest *__block productRequestMock = nil;
    
    __auto_type createRequestor = ^(AMATransactionState state) {
        requestor = [[AMAProductRequestor alloc] initWithTransaction:transaction
                                                    transactionState:state
                                                            delegate:delegate];
    };
    
    beforeEach(^{
        transaction = [[AMAMutableSKPaymentTransaction alloc] init];
        
        SKMutablePayment *payment = [[SKMutablePayment alloc] init];
        payment.productIdentifier = @"io.appmetrica.product";
        transaction.payment = payment;
        
        delegate = [KWMock nullMockForProtocol:@protocol(AMAProductRequestorDelegate)];
        productRequestMock = [SKProductsRequest stubbedNullMockForDefaultInit];
        [productRequestMock stub:@selector(initWithProductIdentifiers:) andReturn:productRequestMock];
        
        createRequestor(AMATransactionStatePurchased);
    });
    
    it(@"Should create request with provided product ID", ^{
        [productRequestMock stub:@selector(initWithProductIdentifiers:) withBlock:^id(NSArray *params) {
            [[(NSSet *)params[0] should] contain:transaction.payment.productIdentifier];
            return productRequestMock;
        }];
        [requestor requestProductInformation];
    });
    
    it(@"Should start request", ^{
        [[productRequestMock should] receive:@selector(start)];
        [requestor requestProductInformation];
    });
    
    context(@"Product handling", ^{
        
        SKProductsResponse *__block response = nil;
        NSMutableArray *__block products = nil;
        NSMutableArray *__block invalidIDs = nil;
        
        beforeEach(^{
            products = [NSMutableArray array];
            invalidIDs = [NSMutableArray array];
            
            response = [SKProductsResponse mock];
            [response stub:@selector(products) andReturn:products];
            [response stub:@selector(invalidProductIdentifiers) andReturn:invalidIDs];
        });
        
        it(@"Should handle product", ^{
            AMAMutableSKProduct *product = [[AMAMutableSKProduct alloc] init];
            [products addObject:product];
            
            [[delegate should] receive:@selector(productRequestor:didRecieveProduct:) withArguments:requestor, product];
            
            [requestor productsRequest:productRequestMock didReceiveResponse:response];
        });
        context(@"Invalids", ^{
            
            
            context(@"More than one product", ^{
               
                beforeEach(^{
                    [products addObject:[[AMAMutableSKProduct alloc] init]];
                    [products addObject:[[AMAMutableSKProduct alloc] init]];
                });
                
                it(@"Should not handle", ^{
                    [[delegate shouldNot] receive:@selector(productRequestor:didRecieveProduct:)];
                    [requestor productsRequest:productRequestMock didReceiveResponse:response];
                });
                
                it(@"Should report of failure", ^{
                    [[delegate should] receive:@selector(productRequestorDidFailToFetchProduct:) withArguments:requestor];
                    [requestor productsRequest:productRequestMock didReceiveResponse:response];
                });
            });
            
            context(@"Invalid IDs", ^{
               
                beforeEach(^{
                    [products addObject:[[AMAMutableSKProduct alloc] init]];
                    [invalidIDs addObject:@"io.appmetrica.invalid"];
                });
                
                it(@"Should not handle product if there were invalid IDs", ^{
                    [[delegate shouldNot] receive:@selector(productRequestor:didRecieveProduct:)];
                    [requestor productsRequest:productRequestMock didReceiveResponse:response];
                });
                
                it(@"Should report of failure", ^{
                    [[delegate should] receive:@selector(productRequestorDidFailToFetchProduct:) withArguments:requestor];
                    [requestor productsRequest:productRequestMock didReceiveResponse:response];
                });
            });

            it(@"Should report of failure if no produtcs were fetched", ^{
                [[delegate should] receive:@selector(productRequestorDidFailToFetchProduct:) withArguments:requestor];
                [requestor productsRequest:productRequestMock didReceiveResponse:response];
            });
            
            it(@"Should report of failure if it failed to fetch", ^{
                [[delegate should] receive:@selector(productRequestorDidFailToFetchProduct:) withArguments:requestor];
                [requestor request:productRequestMock didFailWithError:[NSError nullMock]];
            });
        });
    });
});

SPEC_END
