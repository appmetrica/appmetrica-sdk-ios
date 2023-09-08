
#import "AMACore.h"
#import "AMARevenueInfo.h"

static NSUInteger const kAMARevenueInfoDefaultQuantity = 1;

@interface AMARevenueInfo ()

@property (nonatomic, assign, readwrite) double price;
@property (nonatomic, strong, readwrite) NSDecimalNumber *priceDecimal;
@property (nonatomic, copy, readwrite) NSString *currency;

@property (nonatomic, assign, readwrite) NSUInteger quantity;
@property (nonatomic, copy, readwrite) NSString *productID;
@property (nonatomic, copy, readwrite) NSString *transactionID;
@property (nonatomic, copy, readwrite) NSData *receiptData;

@property (nonatomic, copy, readwrite) NSDictionary *payload;

@end

@implementation AMARevenueInfo

- (instancetype)initWithPrice:(double)price currency:(NSString *)currency
{
    return [self initWithPrice:price
                      currency:currency
                      quantity:kAMARevenueInfoDefaultQuantity
                     productID:nil
                 transactionID:nil
                   receiptData:nil
                       payload:nil];
}

- (instancetype)initWithPriceDecimal:(NSDecimalNumber *)priceDecimal
                            currency:(NSString *)currency
{
    return [self initWithPriceDecimal:priceDecimal
                             currency:currency
                             quantity:kAMARevenueInfoDefaultQuantity
                            productID:nil
                        transactionID:nil
                          receiptData:nil
                              payload:nil];
}

- (instancetype)initWithPrice:(double)price
                     currency:(NSString *)currency
                     quantity:(NSUInteger)quantity
                    productID:(NSString *)productID
                transactionID:(NSString *)transactionID
                  receiptData:(NSData *)receiptData
                      payload:(NSDictionary *)payload
{
    return [self initWithPrice:price
                  priceDecimal:nil
                      currency:currency
                      quantity:quantity
                     productID:productID
                 transactionID:transactionID
                   receiptData:receiptData
                       payload:payload];
}

- (instancetype)initWithPriceDecimal:(NSDecimalNumber *)priceDecimal
                            currency:(NSString *)currency
                            quantity:(NSUInteger)quantity
                           productID:(NSString *)productID
                       transactionID:(NSString *)transactionID
                         receiptData:(NSData *)receiptData
                             payload:(NSDictionary *)payload
{
    return [self initWithPrice:0.0
                  priceDecimal:priceDecimal
                      currency:currency
                      quantity:quantity
                     productID:productID
                 transactionID:transactionID
                   receiptData:receiptData
                       payload:payload];
}

- (instancetype)initWithPrice:(double)price
                 priceDecimal:(NSDecimalNumber *)priceDecimal
                     currency:(NSString *)currency
                     quantity:(NSUInteger)quantity
                    productID:(NSString *)productID
                transactionID:(NSString *)transactionID
                  receiptData:(NSData *)receiptData
                      payload:(NSDictionary *)payload
{
    self = [super init];
    if (self != nil) {
        _price = price;
        _priceDecimal = priceDecimal;
        _currency = [currency copy];

        _quantity = quantity;
        _productID = [productID copy];
        _transactionID = [transactionID copy];
        _receiptData = [receiptData copy];
        _payload = [payload copy];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
    return [[AMAMutableRevenueInfo alloc] initWithPrice:self.price
                                           priceDecimal:self.priceDecimal
                                               currency:self.currency
                                               quantity:self.quantity
                                              productID:self.productID
                                          transactionID:self.transactionID
                                            receiptData:self.receiptData
                                                payload:self.payload];
}

@end

@implementation AMAMutableRevenueInfo

@dynamic price;
@dynamic priceDecimal;
@dynamic currency;
@dynamic quantity;
@dynamic productID;
@dynamic transactionID;
@dynamic receiptData;
@dynamic payload;

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[AMARevenueInfo alloc] initWithPrice:self.price
                                    priceDecimal:self.priceDecimal
                                        currency:self.currency
                                        quantity:self.quantity
                                       productID:self.productID
                                   transactionID:self.transactionID
                                     receiptData:self.receiptData
                                         payload:self.payload];
}

@end
