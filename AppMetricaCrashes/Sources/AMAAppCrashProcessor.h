
#import "AMACrashProcessing.h"

@class AMADecodedCrashSerializer;
@protocol AMACrashProcessingReporting;

@interface AMAAppCrashProcessor : NSObject <AMACrashProcessing>

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *ignoredCrashSignals;

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals;

- (instancetype)initWithIgnoredSignals:(NSArray *)ignoredSignals
                            serializer:(AMADecodedCrashSerializer *)serializer;

@end
