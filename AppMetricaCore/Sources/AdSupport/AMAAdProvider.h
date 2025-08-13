
#import <Foundation/Foundation.h>

@protocol AMAAdProviding;

@interface AMAAdProvider : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isAdvertisingTrackingEnabled;
- (NSUUID *)advertisingIdentifier;
- (NSUInteger)ATTStatus API_AVAILABLE(ios(14.0), tvos(14.0));

@property (nonatomic, assign, setter=setEnabled:) BOOL isEnabled;
- (void)setupAdProvider:(id<AMAAdProviding>)adProvider;

@end
