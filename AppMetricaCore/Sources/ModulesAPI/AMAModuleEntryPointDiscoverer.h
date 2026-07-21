#import <Foundation/Foundation.h>
#import "AMAModuleEntryPointDiscovering.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleEntryPointDiscoverer : NSObject <AMAModuleEntryPointDiscovering>

- (instancetype)initWithClassLookup:(nullable Class (^)(NSString *className))classLookup;
- (instancetype)initWithCandidateClassNames:(NSArray<NSString *> *)candidateClassNames
                                 classLookup:(nullable Class (^)(NSString *className))classLookup
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
