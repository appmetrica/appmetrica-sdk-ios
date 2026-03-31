#import "AMAStorageMock.h"

@implementation AMAStorageMock

- (BOOL)deleteFileWithError:(NSError *__autoreleasing *)error
{
    [self.deleteExpectation fulfill];
    NSError *me = self.mockError;
    
    if (error != nil) {
        *error = self.mockError;
    }
    return me != nil;
}

- (NSData *)readDataWithError:(NSError *__autoreleasing *)error
{
    [self.readExpectation fulfill];
    NSError *me = self.mockError;
    
    if (me != nil) {
        if (error != nil) {
            *error = me;
        }
        return nil;
    } else {
        return self.mockedData;
    }
}

- (BOOL)writeData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    [self.writeExpectation fulfill];
    NSError *me = self.mockError;
    
    if (me != nil) {
        if (error != nil) {
            *error = me;
        }
    } else {
        self.mockedData = data;
    }
    
    return me != nil;
}

@end
