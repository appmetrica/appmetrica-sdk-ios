
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.2))
@interface SKProductMutableDiscount : SKProductDiscount

@property(nonatomic, strong) NSDecimalNumber *price;
@property(nonatomic, strong) NSLocale *priceLocale;
@property(nonatomic, strong) NSString *identifier API_AVAILABLE(ios(12.2));
@property(nonatomic, nullable, strong) SKProductSubscriptionPeriod *subscriptionPeriod;
@property(nonatomic, assign) NSUInteger numberOfPeriods;
@property(nonatomic, assign) SKProductDiscountPaymentMode paymentMode;
@property(nonatomic, assign) SKProductDiscountType type API_AVAILABLE(ios(12.2));

@end

API_AVAILABLE(ios(11.2))
@interface  SKProductSubscriptionMutablePeriod : SKProductSubscriptionPeriod

@property(nonatomic, assign) NSUInteger numberOfUnits;
@property(nonatomic, assign) SKProductPeriodUnit unit;

@end

@interface AMAMutableSKProduct : SKProduct

@property(nonatomic, strong) NSString *localizedDescription;
@property(nonatomic, strong) NSString *localizedTitle;
@property(nonatomic, strong) NSDecimalNumber *price;
@property(nonatomic, strong) NSLocale *priceLocale;
@property(nonatomic, strong) NSString *productIdentifier;
@property(nonatomic, assign) BOOL isDownloadable;
@property(nonatomic, assign) BOOL isFamilyShareable;
@property(nonatomic, strong) NSArray<NSNumber *> *downloadContentLengths;
@property(nonatomic, strong) NSString *downloadContentVersion;
@property(nonatomic, nullable, strong) SKProductSubscriptionPeriod *subscriptionPeriod API_AVAILABLE(ios(11.2));
@property(nonatomic, nullable, strong) SKProductDiscount *introductoryPrice API_AVAILABLE(ios(11.2));
@property(nonatomic, nullable, strong) NSString *subscriptionGroupIdentifier;
@property(nonatomic, nullable, strong) NSArray<SKProductDiscount *> *discounts API_AVAILABLE(ios(11.2));

@end

NS_ASSUME_NONNULL_END
