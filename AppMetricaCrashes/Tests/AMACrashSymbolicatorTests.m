
#import <Kiwi/Kiwi.h>
#import "AMASymbolsCollection.h"
#import "AMACrashSymbolicator.h"
#import "AMADecodedCrash.h"
#import "AMABinaryImage.h"
#import "AMABacktraceFrame.h"
#import "AMASymbol.h"
#import "AMABacktrace.h"

@interface AMACrashSymbolicator (Tests)

+ (AMABacktraceFrame *)symbolicatedBacktraceFrame:(AMABacktraceFrame *)frame
                                symbolsCollection:(AMASymbolsCollection *)symbolsCollection
                                     binaryImages:(NSDictionary *)binaryImages;

+ (NSDictionary *)binaryImagesByAddress:(NSArray *)images;

@end

SPEC_BEGIN(AMACrashSymbolicatorTests)

describe(@"AMACrashSymbolicator", ^{

    AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:@"MetricaSample"
                                                            UUID:@""
                                                         address:2
                                                            size:100
                                                       vmAddress:0
                                                         cpuType:0
                                                      cpuSubtype:0
                                                    majorVersion:0
                                                    minorVersion:0
                                                 revisionVersion:0
                                                crashInfoMessage:nil
                                               crashInfoMessage2:nil];
    NSDictionary *images = @{ @(image.address): image };
    AMASymbol *symbol = [[AMASymbol alloc] initWithMethodName:@"init"
                                                    className:@"AMAMock"
                                             isInstanceMethod:YES
                                                      address:23
                                                         size:1];
    AMABacktraceFrame *strippedFrame = [[AMABacktraceFrame alloc] initWithLineOfCode:0
                                                                  instructionAddress:@32
                                                                       symbolAddress:@2
                                                                       objectAddress:@2
                                                                          symbolName:@"_mh_execute_header"
                                                                          objectName:@"MetricaSample"
                                                                            stripped:YES];
    AMABacktraceFrame *symbolicatedFrame = [[AMABacktraceFrame alloc] initWithLineOfCode:0
                                                                      instructionAddress:@32
                                                                           symbolAddress:@23
                                                                           objectAddress:@2
                                                                              symbolName:@"-[AMAMock init]"
                                                                              objectName:@"MetricaSample"
                                                                                stripped:NO];
    AMASymbolsCollection *__block symbolsCollection = nil;

    beforeEach(^{
        symbolsCollection = [AMASymbolsCollection nullMock];
    });

    context(@"Decoded crash", ^{

        AMADecodedCrash *__block decodedCrash = nil;
        AMABacktraceFrame *__block frameAfterSymbolication = nil;

        beforeEach(^{
            frameAfterSymbolication = nil;
            decodedCrash = [AMADecodedCrash nullMock];
            [symbolsCollection stub:@selector(count) andReturn:theValue(1)];
            [AMACrashSymbolicator stub:@selector(symbolicatedBacktraceFrame:symbolsCollection:binaryImages:)
                             withBlock:^id(NSArray *params) {
                                 return frameAfterSymbolication;
                             }];
            [AMACrashSymbolicator stub:@selector(binaryImagesByAddress:)];
        });

        it(@"Should return NO for crash without backtrace", ^{
            BOOL isSymbolicated = [AMACrashSymbolicator symbolicateCrash:nil symbolsCollection:symbolsCollection];
            [[theValue(isSymbolicated) should] beNo];
        });

        it(@"Should index crash binary images", ^{
            NSArray *binaryImages = @[ image ];
            [decodedCrash stub:@selector(binaryImages) andReturn:binaryImages];
            [[AMACrashSymbolicator should] receive:@selector(binaryImagesByAddress:) withArguments:binaryImages];
            [AMACrashSymbolicator symbolicateCrash:decodedCrash symbolsCollection:symbolsCollection];
        });

        context(@"Crash with stripped frame", ^{

            beforeEach(^{
                frameAfterSymbolication = symbolicatedFrame;
                [decodedCrash stub:@selector(crashedThreadBacktrace)
                         andReturn:[[AMABacktrace alloc] initWithFrames:@[ strippedFrame ].mutableCopy]];
            });

            it(@"Should w symbolication", ^{
                KWCaptureSpy *spy =
                    [AMACrashSymbolicator captureArgument:@selector(symbolicatedBacktraceFrame:symbolsCollection:binaryImages:)
                                                  atIndex:0];
                [AMACrashSymbolicator symbolicateCrash:decodedCrash symbolsCollection:symbolsCollection];
                [[spy.argument should] beIdenticalTo:strippedFrame];
            });

            it(@"Should return NO if symbols not found", ^{
                frameAfterSymbolication = nil;
                BOOL isSymbolicated = [AMACrashSymbolicator symbolicateCrash:decodedCrash
                                                           symbolsCollection:symbolsCollection];
                [[theValue(isSymbolicated) should] beNo];
            });

            it(@"Should symbolicate frames", ^{
                [AMACrashSymbolicator symbolicateCrash:decodedCrash symbolsCollection:symbolsCollection];
                [[decodedCrash.crashedThreadBacktrace.frames.firstObject should] equal:symbolicatedFrame];
            });

        });

        context(@"Empty symbols collection", ^{

            beforeEach(^{
                [symbolsCollection stub:@selector(count) andReturn:theValue(0)];
            });

            it(@"Should return NO", ^{
                BOOL isSymbolicated = [AMACrashSymbolicator symbolicateCrash:nil symbolsCollection:symbolsCollection];
                [[theValue(isSymbolicated) should] beNo];
            });

        });

    });

    context(@"Binary images", ^{

        it(@"Should create binary images index", ^{
            NSArray *binaryImages = @[ image ];
            NSDictionary *index = [AMACrashSymbolicator binaryImagesByAddress:binaryImages];
            [[index should] equal:images];
        });

    });

    context(@"Backtrace frame", ^{

        it(@"Should fill stripped frame with symbol name", ^{
            [symbolsCollection stub:@selector(symbolForAddress:binaryImage:) andReturn:symbol];
            AMABacktraceFrame *frame = [AMACrashSymbolicator symbolicatedBacktraceFrame:strippedFrame
                                                                      symbolsCollection:symbolsCollection
                                                                           binaryImages:images];
            [[frame.symbolName should] equal:symbolicatedFrame.symbolName];
        });

        it(@"Should fill stripped frame with symbol address", ^{
            [symbolsCollection stub:@selector(symbolForAddress:binaryImage:) andReturn:symbol];
            AMABacktraceFrame *frame = [AMACrashSymbolicator symbolicatedBacktraceFrame:strippedFrame
                                                                      symbolsCollection:symbolsCollection
                                                                           binaryImages:images];
            [[frame.symbolAddress should] equal:symbolicatedFrame.symbolAddress];
        });

        it(@"Should fill not stripped frame with symbol address", ^{
            [symbolsCollection stub:@selector(symbolForAddress:binaryImage:) andReturn:symbol];
            AMABacktraceFrame *frame = [AMACrashSymbolicator symbolicatedBacktraceFrame:symbolicatedFrame
                                                                      symbolsCollection:symbolsCollection
                                                                           binaryImages:images];
            [[frame.symbolAddress should] equal:symbolicatedFrame.symbolAddress];
        });

        it(@"Should return nil for frame with unknown symbol", ^{
            [symbolsCollection stub:@selector(symbolForAddress:binaryImage:) andReturn:nil];
            AMABacktraceFrame *frame = [AMACrashSymbolicator symbolicatedBacktraceFrame:strippedFrame
                                                                      symbolsCollection:symbolsCollection
                                                                           binaryImages:images];
            [[frame should] beNil];
        });

        it(@"Should pass valid address for stripped symbol search", ^{
            KWCaptureSpy *spy = [symbolsCollection captureArgument:@selector(symbolForAddress:binaryImage:)
                                                           atIndex:0];
            [AMACrashSymbolicator symbolicatedBacktraceFrame:strippedFrame
                                           symbolsCollection:symbolsCollection
                                                binaryImages:images];
            [[spy.argument should] equal:strippedFrame.instructionAddress];
        });

        it(@"Should pass valid address for not stripped symbol search", ^{
            KWCaptureSpy *spy = [symbolsCollection captureArgument:@selector(symbolForAddress:binaryImage:)
                                                           atIndex:0];
            [AMACrashSymbolicator symbolicatedBacktraceFrame:symbolicatedFrame
                                           symbolsCollection:symbolsCollection
                                                binaryImages:images];
            [[spy.argument should] equal:symbolicatedFrame.symbolAddress];
        });

        it(@"Should pass valid image for symbol search", ^{
            KWCaptureSpy *spy = [symbolsCollection captureArgument:@selector(symbolForAddress:binaryImage:)
                                                           atIndex:1];
            [AMACrashSymbolicator symbolicatedBacktraceFrame:strippedFrame
                                           symbolsCollection:symbolsCollection
                                                binaryImages:images];
            [[spy.argument should] equal:image];
        });

    });
    
});

SPEC_END
