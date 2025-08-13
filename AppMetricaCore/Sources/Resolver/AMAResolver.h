#import <Foundation/Foundation.h>
#import "AMAPermissionResolving.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAResolver: NSObject<AMAPermissionResolvingInput, AMAPermissionResolvingOutput>

@property (nonatomic, readonly) BOOL defaultValue;

- (void)triggerUpdate;
- (BOOL)resolve;
- (void)updateWithValue:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
