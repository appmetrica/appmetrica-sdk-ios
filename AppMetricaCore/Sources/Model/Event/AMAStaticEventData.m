
#import "AMACore.h"

@implementation AMAStaticEventData

@synthesize name = _name;
@synthesize type = _type;
@synthesize data = _data;
@synthesize bytesTruncated = _bytesTruncated;

- (instancetype)initWithName:(NSString *)name
                        type:(NSUInteger)type
                        data:(NSData *)data
              bytesTruncated:(NSUInteger)bytesTruncated
{
    self = [super init];
    if (self != nil) {
        _name = [name copy];
        _type = type;
        _data = [data copy];
        _bytesTruncated = bytesTruncated;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
