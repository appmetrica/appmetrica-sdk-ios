
#import <Foundation/Foundation.h>

typedef void (^AMATruncationBlock)(NSUInteger bytesTruncated);

@protocol AMAStringTruncating <NSObject>

- (NSString *)truncatedString:(NSString *)string onTruncation:(AMATruncationBlock)onTruncation;

@end

@protocol AMADataTruncating <NSObject>

- (NSData *)truncatedData:(NSData *)data onTruncation:(AMATruncationBlock)onTruncation;

@end

@protocol AMADictionaryTruncating <NSObject>

- (NSDictionary *)truncatedDictionary:(NSDictionary *)data onTruncation:(AMATruncationBlock)onTruncation;

@end
