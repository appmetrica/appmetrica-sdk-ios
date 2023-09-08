
#import "AMASymbol.h"

@implementation AMASymbol

- (instancetype)initWithMethodName:(NSString *)methodName
                         className:(NSString *)className
                  isInstanceMethod:(BOOL)isInstanceMethod
                           address:(NSUInteger)address
                              size:(NSUInteger)size
{
    self = [super init];
    if (self != nil) {
        _methodName = [methodName copy];
        _className = [className copy];
        _instanceMethod = isInstanceMethod;
        _address = address;
        _size = size;
    }
    return self;
}

- (NSString *)symbolName
{
    return [NSString stringWithFormat:@"%@[%@ %@]", self.instanceMethod ? @"-" : @"+", self.className, self.methodName];
}

- (instancetype)symbolByChangingAddress:(NSUInteger)address
{
    return [[[self class] alloc] initWithMethodName:self.methodName
                                          className:self.className
                                   isInstanceMethod:self.instanceMethod
                                            address:address
                                               size:self.size];
}

- (instancetype)symbolByChangingSize:(NSUInteger)size
{
    return [[[self class] alloc] initWithMethodName:self.methodName
                                          className:self.className
                                   isInstanceMethod:self.instanceMethod
                                            address:self.address
                                               size:size];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return self.address;
}

- (NSComparisonResult)compare:(AMASymbol *)otherSymbol
{
    if (self.address < otherSymbol.address) {
        return NSOrderedAscending;
    }
    else if (self.address > otherSymbol.address) {
        return NSOrderedDescending;
    }
    else {
        return NSOrderedSame;
    }
}

- (BOOL)isEqual:(id)object
{
    BOOL isEqual = [object isKindOfClass:[self class]];
    if (isEqual) {
        AMASymbol *otherSymbol = object;
        isEqual = otherSymbol.address == self.address;
        isEqual = isEqual && otherSymbol.size == self.size;
        isEqual = isEqual &&
            (otherSymbol.className == self.className || [otherSymbol.className isEqualToString:self.className]);
        isEqual = isEqual &&
            (otherSymbol.methodName == self.methodName || [otherSymbol.methodName isEqualToString:self.methodName]);
    }
    return isEqual;
}

#if AMA_ALLOW_DESCRIPTIONS
- (NSString *)description
{
    unsigned long symbolShiftBegin = (unsigned long)self.address;
    unsigned long symbolShiftEnd = (unsigned long)(self.address + self.size);
    unsigned long symbolShiftSize = (unsigned long)(self.size);

    return [NSString stringWithFormat:@"0x%02lx + %lu : 0x%02lx (%@)",
                                      symbolShiftBegin, symbolShiftSize, symbolShiftEnd, self.symbolName];
}
#endif

@end
