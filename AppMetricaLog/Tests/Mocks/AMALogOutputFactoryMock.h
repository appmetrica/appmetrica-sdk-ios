
#import "AMALogOutputFactory.h"

@interface AMALogOutputFactoryMock : AMALogOutputFactory

@property (nonatomic, strong) AMALogOutput *mockOutput;

- (instancetype)initWithOutput:(AMALogOutput *)output;

- (AMALogOutput *)outputWithChannel:(AMALogChannel)channel
                              level:(AMALogLevel)level
                          formatter:(id<AMALogMessageFormatting>)formatter
                         middleware:(id<AMALogMiddleware>)middleware;

@end
