
#import "AMALogMiddleware.h"

@interface AMAFileLogMiddleware : NSObject <AMALogMiddleware>

- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle;

@end
