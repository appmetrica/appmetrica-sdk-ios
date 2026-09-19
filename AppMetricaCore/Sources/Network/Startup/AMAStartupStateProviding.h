#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAStartupStateProviding <NSObject>

// Stable set of parameter keys that additional module parameters must not overwrite.
@property (nonatomic, copy, readonly) NSSet<NSString *> *reservedParameterKeys;

// Returns an immutable snapshot of all reserved keys, used to check freshness and populate the next request.
- (NSDictionary<NSString *, NSString *> *)startupParameters;
- (BOOL)requiresUpdateForParameters:(NSDictionary<NSString *, NSString *> *)parameters;

// Called for an accepted successful response, before notifying startup observers.
// Only reserved parameter values are guaranteed to remain unchanged throughout the request.
- (void)startupDidSucceedWithParameters:(NSDictionary<NSString *, NSString *> *)parameters;

@end

NS_ASSUME_NONNULL_END
