
#import <Foundation/Foundation.h>

@interface NSObject (AMATestAdditions)

+ (id)stubbedNullMockForDefaultInit;
+ (id)stubbedNullMockForInit:(SEL)selector;
+ (id)stubInstance:(id)instance forInit:(SEL)selector;

@end

@interface AMATestUtilities : NSObject

+ (void)fillObjectPointerParameter:(NSValue *)parameter withValue:(id)value;
+ (void)fillIntPointerParameter:(NSValue *)parameter withValue:(NSUInteger)value;

+ (NSString *)stringOfLength:(NSUInteger)length filledWithSample:(NSString *)sample;
+ (NSData *)dataOfSize:(NSUInteger)size filledWithSample:(NSData *)sample;

+ (void)stubAssertions;

@end
