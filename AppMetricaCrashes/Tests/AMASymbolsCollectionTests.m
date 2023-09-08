
#import <Kiwi/Kiwi.h>
#import "AMASymbolsCollection.h"
#import "AMASymbol.h"
#import "AMABinaryImage.h"

SPEC_BEGIN(AMASymbolsCollectionTests)

describe(@"AMASymbolsCollection", ^{

    AMASymbol *(^createSymbol)(NSString *name, NSUInteger address, NSUInteger size) =
        ^(NSString *name, NSUInteger address, NSUInteger size) {
            return [[AMASymbol alloc] initWithMethodName:name
                                               className:@""
                                        isInstanceMethod:YES
                                                 address:address
                                                    size:size];
        };

    AMABinaryImage *(^createImage)(NSString *UUID, NSUInteger address, NSUInteger size) =
        ^(NSString *UUID, NSUInteger address, NSUInteger size) {
            return [[AMABinaryImage alloc] initWithName:@""
                                                   UUID:UUID
                                                address:address
                                                   size:size
                                              vmAddress:0
                                                cpuType:0
                                             cpuSubtype:0
                                           majorVersion:0
                                           minorVersion:0
                                        revisionVersion:0
                                       crashInfoMessage:nil
                                      crashInfoMessage2:nil];
        };

    NSUInteger validShift = 23;
    NSUInteger validSize = 10;
    NSUInteger invalidAddress = 35;
    NSUInteger originalImageAddress = 0;
    NSUInteger actualImageAddress = 1000;

    NSUInteger actualSymbolAddress = actualImageAddress + validShift;
    NSUInteger actualInstructionAddress = actualImageAddress + validShift + validSize / 2;

    AMASymbol *validSymbol = createSymbol(@"VALID", originalImageAddress + validShift, validSize);
    NSArray *symbols = @[
        createSymbol(@"", 4, 2),
        createSymbol(@"", 8, 5),
        createSymbol(@"", 15, 1),
        createSymbol(@"", 16, 1),
        validSymbol,
        createSymbol(@"", 42, 20)
    ];

    NSString *imageUUID = @"UUID";
    AMABinaryImage *originalImage = createImage(imageUUID, originalImageAddress, 200);
    AMABinaryImage *actualImage = createImage(imageUUID, actualImageAddress, 200);
    NSArray *images = @[
        originalImage,
        createImage(@"01", 1000, 1000)
    ];

    NSString *binaryName = @"BinaryName";
    NSArray *binaryNames = @[
        binaryName,
        @"OtherBinaryName",
    ];

    AMASymbolsCollection *__block collection = nil;

    beforeEach(^{
        collection = [[AMASymbolsCollection alloc] initWithSymbols:symbols
                                                            images:images
                                                dynamicBinaryNames:binaryNames];
    });

    it(@"Should store symbols", ^{
        [[collection.symbols should] equal:symbols];
    });

    it(@"Should return valid symbol by symbol address", ^{
        AMASymbol *symbol = [collection symbolForAddress:actualSymbolAddress binaryImage:actualImage];
        [[symbol.methodName should] equal:validSymbol.methodName];
    });

    it(@"Should return valid symbol by instruction address", ^{
        AMASymbol *symbol = [collection symbolForAddress:actualInstructionAddress binaryImage:actualImage];
        [[symbol.methodName should] equal:validSymbol.methodName];
    });

    it(@"Should return symbol with actual address", ^{
        AMASymbol *symbol = [collection symbolForAddress:actualInstructionAddress binaryImage:actualImage];
        [[theValue(symbol.address) should] equal:theValue(actualSymbolAddress)];
    });

    it(@"Should not return invalid symbol", ^{
        AMASymbol *symbol = [collection symbolForAddress:actualImageAddress + invalidAddress binaryImage:actualImage];
        [[symbol should] beNil];
    });

    it(@"Should return valid count", ^{
        [[theValue(collection.count) should] equal:theValue(symbols.count)];
    });

    it(@"Should return self as copy", ^{
        [[[collection copy] should] beIdenticalTo:collection];
    });

    context(@"Dynamic binaries", ^{
        it(@"Should return YES for existing binary", ^{
            [[theValue([collection containsDynamicBinaryWithName:binaryName]) should] beYes];
        });
        it(@"Should return NO for unknown binary", ^{
            [[theValue([collection containsDynamicBinaryWithName:@"UnknownBinary"]) should] beNo];
        });
    });

});

SPEC_END
