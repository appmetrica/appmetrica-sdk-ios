
#import <Foundation/Foundation.h>

@interface AMAIDSyncRequest : NSObject

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSDictionary *headers;
@property (nonatomic, copy, readonly) NSDictionary *preconditions;
@property (nonatomic, copy, readonly) NSNumber *resendIntervalForValidResponse;
@property (nonatomic, copy, readonly) NSNumber *resendIntervalForNotValidResponse;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *validResponseCodes;
@property (nonatomic, assign, readonly) BOOL reportEventEnabled;
@property (nonatomic, copy, readonly) NSString *reportUrl;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithType:(NSString *)type
                         url:(NSString *)url
                     headers:(NSDictionary *)headers
               preconditions:(NSDictionary *)preconditions
         validResendInterval:(NSNumber *)resendIntervalForValidResponse
       invalidResendInterval:(NSNumber *)resendIntervalForNotValidResponse
          validResponseCodes:(NSArray<NSNumber *> *)validResponseCodes
          reportEventEnabled:(BOOL)reportEventEnabled
                   reportUrl:(NSString *)reportUrl;

@end
