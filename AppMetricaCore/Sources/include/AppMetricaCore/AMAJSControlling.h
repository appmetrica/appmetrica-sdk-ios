
#import <Foundation/Foundation.h>

#if !TARGET_OS_TV
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAsyncExecuting;

NS_SWIFT_NAME(JSReporting)
@protocol AMAJSReporting <NSObject>

- (void)reportJSEvent:(NSString *)name value:(NSString *)value;
- (void)reportJSInitEvent:(NSString *)value;

@end

NS_SWIFT_NAME(JSControlling)
@protocol AMAJSControlling <NSObject>

@property (nonatomic, strong, readonly) WKUserContentController *userContentController;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)setUpWebViewReporting:(id<AMAAsyncExecuting>)executor
                 withReporter:(id<AMAJSReporting>)reporter;

@end

NS_ASSUME_NONNULL_END

#endif
