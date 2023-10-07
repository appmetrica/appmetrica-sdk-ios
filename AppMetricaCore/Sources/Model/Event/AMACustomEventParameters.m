
#import "AMACore.h"

@implementation AMACustomEventParameters

- (instancetype)initWithEventType:(NSUInteger)eventType
{
    self = [super init];
    if (self != nil) {
        _eventType = eventType;
        _valueType = AMAEventValueTypeString;
        _fileName = nil;
        _GZipped = YES;
        _truncated = YES;
        _encrypted = YES;
        _appEnvironment = self.appEnvironment.copy;
        _errorEnvironment = self.errorEnvironment.copy;
        _extras = self.extras.copy;
        _isPast = NO;
        _bytesTruncated = 0;
    }
    return self;
}

@end
