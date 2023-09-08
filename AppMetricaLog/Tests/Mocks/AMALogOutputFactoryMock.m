
#import "AMALogOutputFactoryMock.h"
#import "AMALogOutput.h"

@implementation AMALogOutputFactoryMock

- (instancetype)initWithOutput:(AMALogOutput *)output
{
    self = [super init];
    if (self != nil) {
        self.mockOutput = output;
    }
    return self;
}

- (AMALogOutput *)outputWithChannel:(AMALogChannel)channel
                              level:(AMALogLevel)level
                          formatter:(id<AMALogMessageFormatting>)formatter
                         middleware:(id<AMALogMiddleware>)middleware
{
    if (self.mockOutput != nil) {
        return self.mockOutput;
    }
    else {
        return [[AMALogOutput alloc] initWithChannel:channel level:level formatter:formatter middleware:middleware];
    }
}

@end
