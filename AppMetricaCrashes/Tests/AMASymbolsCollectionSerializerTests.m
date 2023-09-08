
#import <Kiwi/Kiwi.h>
#import "AMASymbolsCollectionSerializer.h"
#import "AMASymbolsCollection.h"
#import "AMASymbol.h"
#import "AMABinaryImage.h"

SPEC_BEGIN(AMASymbolsCollectionSerializerTests)

describe(@"AMASymbolsCollectionSerializer", ^{

    AMASymbol *const expectedSymbol = [[AMASymbol alloc] initWithMethodName:@"methodName"
                                                                  className:@"ClassName"
                                                           isInstanceMethod:YES
                                                                    address:108
                                                                       size:23];
    AMABinaryImage *const expectedImage = [[AMABinaryImage alloc] initWithName:@"BinaryImage"
                                                                          UUID:@"Binary Image UUID"
                                                                       address:520195046
                                                                          size:481516
                                                                     vmAddress:2342
                                                                       cpuType:4
                                                                    cpuSubtype:8
                                                                  majorVersion:0
                                                                  minorVersion:0
                                                               revisionVersion:0
                                                              crashInfoMessage:nil
                                                             crashInfoMessage2:nil];
    NSString *const expectedDynamicBinaryName = @"DynamicBinaryName";
    NSString *const expectedDataString = @"Ch0IARIJQ2xhc3NOYW1lGgptZXRob2ROYW1lIGwoFxIxChFCaW5hcnkgSW1hZ2UgVVVJRBILQml"
        "uYXJ5SW1hZ2UYBCAIKOaXhvgBMKYSOOyxHRoRRHluYW1pY0JpbmFyeU5hbWU=";
    NSData *const expectedData = [[NSData alloc] initWithBase64EncodedString:expectedDataString options:0];

    AMASymbolsCollection *__block collection = nil;

    context(@"Serialization", ^{
        beforeEach(^{
            collection = [[AMASymbolsCollection alloc] initWithSymbols:@[expectedSymbol]
                                                                images:@[expectedImage]
                                                    dynamicBinaryNames:@[expectedDynamicBinaryName]];
        });

        it(@"Should retrun valid data", ^{
            NSData *data = [AMASymbolsCollectionSerializer dataForCollection:collection];
            [[data should] equal:expectedData];
        });
    });

    context(@"Deserialization", ^{
        context(@"Valid data", ^{
            beforeEach(^{
                collection = [AMASymbolsCollectionSerializer collectionForData:expectedData];
            });
            context(@"Symbol", ^{
                AMASymbol *__block symbol = nil;
                beforeEach(^{
                    symbol = collection.symbols.firstObject;
                });

                it(@"Should have valid method name", ^{
                    [[symbol.methodName should] equal:expectedSymbol.methodName];
                });
                it(@"Should have valid class name", ^{
                    [[symbol.className should] equal:expectedSymbol.className];
                });
                it(@"Should have valid instance flag if YES", ^{
                    [[theValue(symbol.instanceMethod) should] beYes];
                });
                it(@"Should have valid instance flag if NO", ^{
                    [symbol stub:@selector(instanceMethod) andReturn:theValue(NO)];
                    NSData *data = [AMASymbolsCollectionSerializer dataForCollection:collection];
                    collection = [AMASymbolsCollectionSerializer collectionForData:data];
                    symbol = collection.symbols.firstObject;
                    [[theValue(symbol.instanceMethod) should] beNo];
                });
                it(@"Should have valid address", ^{
                    [[theValue(symbol.address) should] equal:theValue(expectedSymbol.address)];
                });
                it(@"Should have valid size", ^{
                    [[theValue(symbol.size) should] equal:theValue(expectedSymbol.size)];
                });
            });
            context(@"Image", ^{
                AMABinaryImage *__block image = nil;
                beforeEach(^{
                    image = collection.images.allValues.firstObject;
                });

                it(@"Should have valid name", ^{
                    [[image.name should] equal:expectedImage.name];
                });
                it(@"Should have valid UUID", ^{
                    [[image.UUID should] equal:expectedImage.UUID];
                });
                it(@"Should have valid CPU type", ^{
                    [[theValue(image.cpuType) should] equal:theValue(expectedImage.cpuType)];
                });
                it(@"Should have valid CPU subtype", ^{
                    [[theValue(image.cpuSubtype) should] equal:theValue(expectedImage.cpuSubtype)];
                });
                it(@"Should have valid address", ^{
                    [[theValue(image.address) should] equal:theValue(expectedImage.address)];
                });
                it(@"Should have valid VM address", ^{
                    [[theValue(image.vmAddress) should] equal:theValue(expectedImage.vmAddress)];
                });
                it(@"Should have valid size", ^{
                    [[theValue(image.size) should] equal:theValue(expectedImage.size)];
                });
            });
            context(@"Dynamic Binary Name", ^{
                it(@"Should contain valid value", ^{
                    [[collection.dynamicBinaryNames should] contain:expectedDynamicBinaryName];
                });
            });
        });

        context(@"Invalid data", ^{
            it(@"Should return nil for nil data", ^{
                [[[AMASymbolsCollectionSerializer collectionForData:nil] should] beNil];
            });
            it(@"Should return nil for empty data", ^{
                [[[AMASymbolsCollectionSerializer collectionForData:[NSData data]] should] beNil];
            });
            it(@"Should return nil for corrupted data", ^{
                NSData *data = [@"NOT PROTOBUF" dataUsingEncoding:NSUTF8StringEncoding];
                [[[AMASymbolsCollectionSerializer collectionForData:data] should] beNil];
            });
        });
    });

});

SPEC_END
