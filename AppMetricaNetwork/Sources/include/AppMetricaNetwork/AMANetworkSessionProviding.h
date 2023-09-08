
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMANetworkSessionProviding <NSURLSessionDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) NSURLSessionConfiguration *configuration;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
