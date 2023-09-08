
#import <Foundation/Foundation.h>
#import "AMACrashProcessing.h"

@class AMADecodedCrashSerializer;

@interface AMAGenericCrashProcessor : NSObject <AMACrashProcessing>

- (instancetype)initWithApiKey:(NSString *)apiKey;

- (instancetype)initWithApiKey:(NSString *)apiKey serializer:(AMADecodedCrashSerializer *)serializer;

+ (NSString *)identifierForApiKey:(NSString *)apiKey;

@end
