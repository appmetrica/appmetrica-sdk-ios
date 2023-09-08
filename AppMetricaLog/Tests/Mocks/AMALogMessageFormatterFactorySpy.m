
#import "AMALogMessageFormatterFactorySpy.h"

@implementation AMALogMessageFormatterFactorySpy

- (instancetype)initWithFormatters:(NSDictionary *)formatters
{
    self = [super initWithFormatters:formatters];
    if (self) {
        _calls = [NSMutableArray array];
    }
    return self;
}

- (id<AMALogMessageFormatting>)formatterWithFormatParts:(NSArray *)format
{
    [self.calls addObject:format];
    return [super formatterWithFormatParts:format];
}

@end
