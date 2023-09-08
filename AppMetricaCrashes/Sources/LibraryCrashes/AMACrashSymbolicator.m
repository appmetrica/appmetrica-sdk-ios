
#import "AMACrashSymbolicator.h"
#import "AMADecodedCrash.h"
#import "AMABacktraceFrame.h"

#import "AMASymbol.h"
#import "AMABinaryImage.h"
#import "AMASymbolsCollection.h"
#import "AMABacktrace.h"

@implementation AMACrashSymbolicator

+ (BOOL)symbolicateCrash:(AMADecodedCrash *)crash
       symbolsCollection:(AMASymbolsCollection *)symbolsCollection
{
    if (symbolsCollection.count == 0) {
        return NO;
    }

    NSDictionary *binaryImages = [self binaryImagesByAddress:crash.binaryImages];
    AMABacktrace *backtrace = crash.crashedThreadBacktrace;

    BOOL framesSymbolicated = NO;
    for (NSUInteger i = 0; i < backtrace.frames.count; i++) {
        AMABacktraceFrame *symbolicatedFrame = [self symbolicatedBacktraceFrame:backtrace.frames[i]
                                                              symbolsCollection:symbolsCollection
                                                                   binaryImages:binaryImages];
        if (symbolicatedFrame != nil) {
            framesSymbolicated = YES;
            backtrace.frames[i] = symbolicatedFrame;
        }
    }
    return framesSymbolicated;
}

+ (AMABacktraceFrame *)symbolicatedBacktraceFrame:(AMABacktraceFrame *)frame
                                symbolsCollection:(AMASymbolsCollection *)symbolsCollection
                                     binaryImages:(NSDictionary *)binaryImages
{
    AMABacktraceFrame *symbolicatedFrame = nil;

    NSNumber *address = frame.stripped ? frame.instructionAddress : frame.symbolAddress;
    AMABinaryImage *image = binaryImages[frame.objectAddress];

    AMASymbol *symbol = [symbolsCollection symbolForAddress:address.unsignedLongValue binaryImage:image];

    if (symbol != nil) {
        symbolicatedFrame = [frame backtraceFrameByReplacingSymbolName:symbol.symbolName
                                                         symbolAddress:@(symbol.address)];
    }

    return symbolicatedFrame;
}

+ (NSDictionary *)binaryImagesByAddress:(NSArray *)images
{
    NSMutableDictionary *binaryImages = [NSMutableDictionary dictionaryWithCapacity:images.count];
    for (AMABinaryImage *image in images) {
        binaryImages[@(image.address)] = image;
    }
    return [binaryImages copy];
}

@end
