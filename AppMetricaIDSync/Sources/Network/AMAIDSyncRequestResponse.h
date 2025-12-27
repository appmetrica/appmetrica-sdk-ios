
#import <Foundation/Foundation.h>

@class AMAIDSyncRequest;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncRequestResponse : NSObject

@property (nonatomic, strong, readonly) AMAIDSyncRequest *request;
@property (nonatomic, assign, readonly) NSInteger code;
@property (nonatomic, copy, readonly, nullable) NSString *body;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSArray<NSString *> *> *headers;
@property (nonatomic, copy, readonly) NSString *responseURL;

- (instancetype)initWithRequest:(AMAIDSyncRequest *)request
                           code:(NSInteger)code
                           body:(nullable NSString *)body
                        headers:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)headers
                    responseURL:(NSString *)responseURL;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
