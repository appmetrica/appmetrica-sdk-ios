
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation SKProductMutableDiscount

@synthesize price;
@synthesize priceLocale;
@synthesize identifier;
@synthesize subscriptionPeriod;
@synthesize numberOfPeriods;
@synthesize paymentMode;
@synthesize type;

@end

@implementation SKProductSubscriptionMutablePeriod

@synthesize numberOfUnits;
@synthesize unit;

@end

@implementation AMAMutableSKProduct

@synthesize localizedDescription;
@synthesize localizedTitle;
@synthesize price;
@synthesize priceLocale;
@synthesize productIdentifier;
@synthesize isDownloadable;
@synthesize isFamilyShareable;
@synthesize downloadContentLengths;
@synthesize downloadContentVersion;
@synthesize subscriptionPeriod;
@synthesize introductoryPrice;
@synthesize subscriptionGroupIdentifier;
@synthesize discounts;

@end
