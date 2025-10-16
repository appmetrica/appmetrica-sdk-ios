
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMARequest;

typedef void(^AMAGenericRequestProcessorCallback)(NSData * _Nullable data,
                                                  NSHTTPURLResponse * _Nullable response,
                                                  NSError * _Nullable error);

@interface AMAGenericRequestProcessor : NSObject

- (void)processRequest:(id<AMARequest>)request
              callback:(AMAGenericRequestProcessorCallback)callback;

@end

NS_ASSUME_NONNULL_END
