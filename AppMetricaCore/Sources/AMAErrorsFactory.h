
#import <Foundation/Foundation.h>

@interface AMAErrorsFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

//appmetrica
+ (NSError *)mainReporterNotReadyError;
+ (NSError *)appMetricaIsNotActivatedError;

//reporter
+ (NSError *)sessionNotLoadedError;
+ (NSError *)internalInconsistencyError:(NSString *)description;
+ (NSError *)internalDatabaseError:(NSString *)description;

//session
+ (NSError *)badEventNameError:(NSString *)name;
+ (NSError *)badErrorMessageError:(NSString *)name;
+ (NSError *)emptyDeepLinkUrlOfUnknownTypeError;
+ (NSError *)emptyDeepLinkUrlOfTypeError:(NSString *)type;
+ (NSError *)deepLinkUrlOfUnknownTypeError:(NSString *)url;
+ (NSError *)eventTypeReservedError:(NSUInteger)eventType;

// UserProfile
+ (NSError *)emptyUserProfileError;

// Revenue
+ (NSError *)invalidRevenueCurrencyError:(NSString *)currency;
+ (NSError *)zeroRevenueQuantityError;

//AdRevenue
+ (NSError *)invalidAdRevenueCurrencyError:(NSString *)currency;

// Cocoa Network
+ (NSError *)badServerResponseError;

@end
