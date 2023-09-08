
#import "AMALogSpy.h"

@implementation AMALogMessageSpy

- (instancetype)initWithChannel:(AMALogChannel)channel
                          level:(NSNumber *)level
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSNumber *)line
                   addBacktrace:(NSNumber *)addBacktrace
                           text:(NSString *)text
{
    self = [super init];
    if (self != nil) {
        _channel = channel;
        _level = level;
        _file = [file copy];
        _function = [function copy];
        _line = line;
        _addBacktrace = addBacktrace;
        _text = [text copy];
    }
    return self;
}

+ (id)any
{
    return [NSNull null];
}

+ (BOOL)isProperty:(id)property equalToOtherObjectProperty:(id)otherProperty
{
    BOOL isAny = otherProperty == [[self class] any] || property == [[self class] any];
    return isAny || property == otherProperty || [property isEqual:otherProperty];
}

- (BOOL)isEqual:(AMALogMessageSpy *)otherMessage
{
    if (self == otherMessage) {
        return YES;
    }
    if ([otherMessage isKindOfClass:[AMALogMessageSpy class]] == NO) {
        return NO;
    }
    BOOL isEqual = YES;
    isEqual = isEqual && [[self class] isProperty:self.text equalToOtherObjectProperty:otherMessage.text];
    isEqual = isEqual && [[self class] isProperty:self.level equalToOtherObjectProperty:otherMessage.level];
    isEqual = isEqual && [[self class] isProperty:self.channel equalToOtherObjectProperty:otherMessage.channel];
    isEqual = isEqual && [[self class] isProperty:self.addBacktrace equalToOtherObjectProperty:otherMessage.addBacktrace];
    isEqual = isEqual && [[self class] isProperty:self.line equalToOtherObjectProperty:otherMessage.line];
    isEqual = isEqual && [[self class] isProperty:self.function equalToOtherObjectProperty:otherMessage.function];
    isEqual = isEqual && [[self class] isProperty:self.file equalToOtherObjectProperty:otherMessage.file];
    return isEqual;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: \"%@\"", [super description], self.text];
}

+ (instancetype)messageWithText:(NSString *)text
{
    return [[[self class] alloc] initWithChannel:[[self class] any]
                                           level:[[self class] any]
                                            file:[[self class] any]
                                        function:[[self class] any]
                                            line:[[self class] any]
                                    addBacktrace:[[self class] any]
                                            text:text];
}

+ (instancetype)messageWithText:(NSString *)text channel:(AMALogChannel)channel
{
    return [[[self class] alloc] initWithChannel:channel
                                           level:[[self class] any]
                                            file:[[self class] any]
                                        function:[[self class] any]
                                            line:[[self class] any]
                                    addBacktrace:[[self class] any]
                                            text:text];
}

+ (instancetype)messageWithText:(NSString *)text channel:(AMALogChannel)channel level:(AMALogLevel)level
{
    return [[[self class] alloc] initWithChannel:channel
                                           level:@(level)
                                            file:[[self class] any]
                                        function:[[self class] any]
                                            line:[[self class] any]
                                    addBacktrace:[[self class] any]
                                            text:text];
}

@end

@interface AMALogSpy ()

@property (nonatomic, strong) NSMutableArray *mutableMessages;

@end

@implementation AMALogSpy

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _mutableMessages = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)messages
{
    return [self.mutableMessages copy];
}

- (void)logMessageToChannel:(AMALogChannel)channel
                      level:(AMALogLevel)level
                       file:(const char *)file
                   function:(const char *)function
                       line:(NSUInteger)line
               addBacktrace:(BOOL)addBacktrace
                     format:(NSString *)format, ...
{
    NSString *text = nil;
    if (format != nil) {
        va_list args;
        va_start(args, format);
        text = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
    }
    AMALogMessageSpy *message = [[AMALogMessageSpy alloc] initWithChannel:channel
                                                                    level:@(level)
                                                                     file:[NSString stringWithUTF8String:file]
                                                                 function:[NSString stringWithUTF8String:function] line:@(line)
                                                             addBacktrace:@(addBacktrace)
                                                                     text:text];
    [self.mutableMessages addObject:message];
}

@end
