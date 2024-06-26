
#import <Foundation/Foundation.h>

@class AMALogOutput;

@interface AMALogFacadeMock : AMALogFacade

@property (nonatomic, strong) NSMutableArray<AMALogOutput *> *outputs;
@property (nonatomic, strong, readonly) NSArray<AMALogOutput *> *OSOutputs;
@property (nonatomic, strong, readonly) NSArray<AMALogOutput *> *TTYOutputs;
@property (nonatomic, strong, readonly) NSArray<AMALogOutput *> *ASLOutputs;
#ifdef AMA_ENABLE_FILE_LOG
@property (nonatomic, strong, readonly) NSArray<AMALogOutput *> *fileOutputs;
#endif //AMA_ENABLE_FILE_LOG

@end
