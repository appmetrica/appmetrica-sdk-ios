
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppMetricaLibraryAdapterConfiguration)
@interface AMAAppMetricaLibraryAdapterConfiguration: NSObject

@property (nonatomic, assign) BOOL advertisingIdentifierTrackingEnabled;
@property (nonatomic, assign) BOOL locationTrackingEnabled;
@property (nonatomic, copy, nullable) NSArray<NSString *> *customHosts;

@end

NS_ASSUME_NONNULL_END
