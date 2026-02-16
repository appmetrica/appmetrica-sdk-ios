
#import "MockDecodedCrashSerializer.h"

@implementation MockDecodedCrashSerializer

- (NSData *)dataForCrash:(AMADecodedCrash *)decodedCrash error:(NSError **)error
{
    return [NSData data];
}

@end
