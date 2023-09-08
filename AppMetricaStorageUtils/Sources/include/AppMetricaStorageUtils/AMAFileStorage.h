
#import <Foundation/Foundation.h>

@protocol AMAFileStorage <NSObject>

@property (nonatomic, assign, readonly) BOOL fileExists;

- (NSData *)readDataWithError:(NSError **)error;
- (BOOL)writeData:(NSData *)data error:(NSError **)error;
- (BOOL)deleteFileWithError:(NSError **)error;

@end
