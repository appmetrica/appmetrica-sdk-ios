
#import <Foundation/Foundation.h>

@interface AMASymbol : NSObject <NSCopying>

@property (nonatomic, assign, readonly) BOOL instanceMethod;
@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, copy, readonly) NSString *methodName;
@property (nonatomic, assign, readonly) NSUInteger address;
@property (nonatomic, assign, readonly) NSUInteger size;

@property (nonatomic, copy, readonly) NSString *symbolName;

- (instancetype)initWithMethodName:(NSString *)methodName
                         className:(NSString *)className
                  isInstanceMethod:(BOOL)isInstanceMethod
                           address:(NSUInteger)address
                              size:(NSUInteger)size;

- (instancetype)symbolByChangingAddress:(NSUInteger)address;
- (instancetype)symbolByChangingSize:(NSUInteger)size;

@end
