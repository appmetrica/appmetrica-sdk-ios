
#import <Foundation/Foundation.h>

@protocol AMADictionaryRepresentation <NSObject>

@required
+ (instancetype)objectWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
