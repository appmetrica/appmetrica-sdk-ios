
#import "AMACrashLogging.h"
#import "AMASymbolsCollectionSerializer.h"
#import "AMASymbolsCollection.h"
#import "AMASymbol.h"
#import "AMABinaryImage.h"
#import "SymbolsCollection.pb-c.h"
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

@implementation AMASymbolsCollectionSerializer

#pragma mark - Serialization

+ (NSData *)dataForCollection:(AMASymbolsCollection *)collection
{
    NSData *__block resultData = nil;
    [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
        Ama__SymbolsCollection result = AMA__SYMBOLS_COLLECTION__INIT;
        [self fillSymbolsForCollection:&result symbols:collection.symbols tracker:tracker];
        [self fillImagesForCollection:&result images:collection.images.allValues tracker:tracker];
        [self fillBinaryNamesForCollection:&result binaryNames:collection.dynamicBinaryNames.allObjects tracker:tracker];
        resultData = [self packCollection:&result];
    }];

    return resultData;
}

+ (void)fillSymbolsForCollection:(Ama__SymbolsCollection *)collection
                         symbols:(NSArray *)symbols
                         tracker:(id<AMAAllocationsTracking>)tracker
{
    collection->n_symbols = symbols.count;
    collection->symbols = [tracker allocateSize:sizeof(Ama__SymbolsCollection__Symbol *) * collection->n_symbols];
    [symbols enumerateObjectsUsingBlock:^(AMASymbol *symbol, NSUInteger idx, BOOL *stop) {
        Ama__SymbolsCollection__Symbol *symbolMsg = [tracker allocateSize:sizeof(Ama__SymbolsCollection__Symbol)];
        ama__symbols_collection__symbol__init(symbolMsg);
        symbolMsg->is_inctance_method = (bool)symbol.instanceMethod;
        [AMAProtobufUtilities fillBinaryData:&symbolMsg->class_name withString:symbol.className tracker:tracker];
        [AMAProtobufUtilities fillBinaryData:&symbolMsg->method_name withString:symbol.methodName tracker:tracker];
        symbolMsg->address = (uint64_t)symbol.address;
        symbolMsg->size = (uint32_t)symbol.size;
        collection->symbols[idx] = symbolMsg;
    }];
}

+ (void)fillImagesForCollection:(Ama__SymbolsCollection *)collection
                         images:(NSArray *)images
                        tracker:(id<AMAAllocationsTracking>)tracker
{
    collection->n_images = images.count;
    collection->images = [tracker allocateSize:sizeof(Ama__SymbolsCollection__Image *) * collection->n_images];
    [images enumerateObjectsUsingBlock:^(AMABinaryImage *image, NSUInteger idx, BOOL *stop) {
        Ama__SymbolsCollection__Image *imageMsg = [tracker allocateSize:sizeof(Ama__SymbolsCollection__Image)];
        ama__symbols_collection__image__init(imageMsg);
        [AMAProtobufUtilities fillBinaryData:&imageMsg->uuid withString:image.UUID tracker:tracker];
        [AMAProtobufUtilities fillBinaryData:&imageMsg->name withString:image.name tracker:tracker];
        imageMsg->cpu_type = (uint32_t)image.cpuType;
        imageMsg->cpu_subtype = (uint32_t)image.cpuSubtype;
        imageMsg->address = (uint64_t)image.address;
        imageMsg->vm_address = (uint64_t)image.vmAddress;
        imageMsg->size = (uint32_t)image.size;
        collection->images[idx] = imageMsg;
    }];
}

+ (void)fillBinaryNamesForCollection:(Ama__SymbolsCollection *)collection
                         binaryNames:(NSArray *)binaryNames
                             tracker:(id<AMAAllocationsTracking>)tracker
{
    collection->n_dynamic_binary_names = binaryNames.count;
    collection->dynamic_binary_names =
        [tracker allocateSize:sizeof(ProtobufCBinaryData) * collection->n_dynamic_binary_names];
    [binaryNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        [AMAProtobufUtilities fillBinaryData:collection->dynamic_binary_names + idx withString:name tracker:tracker];
    }];
}

+ (NSData *)packCollection:(Ama__SymbolsCollection *)collection
{
    size_t dataSize = ama__symbols_collection__get_packed_size(collection);
    void *buffer = malloc(dataSize);
    ama__symbols_collection__pack(collection, buffer);
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataSize];
    return data;
}

#pragma mark - Deserialization

+ (AMASymbolsCollection *)collectionForData:(NSData *)data
{
    if (data.length == 0) {
        return nil;
    }
    
    AMASymbolsCollection *result = nil;
    NS_VALID_UNTIL_END_OF_SCOPE AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
    Ama__SymbolsCollection *collection =
        ama__symbols_collection__unpack([allocator protobufCAllocator], data.length, data.bytes);

    if (collection != NULL) {
        result = [[AMASymbolsCollection alloc] initWithSymbols:[self symbolsForCollection:collection]
                                                        images:[self imagesForCollection:collection]
                                            dynamicBinaryNames:[self dynamicBinaryNamesForCollection:collection]];
    }
    else {
        AMALogError(@"Invalid symbols collection data");
    }
    return result;
}

+ (NSArray *)symbolsForCollection:(Ama__SymbolsCollection *)collection
{
    NSMutableArray *symbols = [NSMutableArray arrayWithCapacity:collection->n_symbols];
    for (NSUInteger idx = 0; idx < collection->n_symbols; ++idx) {
        Ama__SymbolsCollection__Symbol *symbolMsg = collection->symbols[idx];
        BOOL isInstanceMethod = (BOOL)symbolMsg->is_inctance_method;
        NSString *className = [AMAProtobufUtilities stringForBinaryData:&symbolMsg->class_name];
        NSString *methodName = [AMAProtobufUtilities stringForBinaryData:&symbolMsg->method_name];
        NSUInteger address = (NSUInteger)symbolMsg->address;
        NSUInteger size = (NSUInteger)symbolMsg->size;
        AMASymbol *symbol = [[AMASymbol alloc] initWithMethodName:methodName
                                                        className:className
                                                 isInstanceMethod:isInstanceMethod
                                                          address:address
                                                             size:size];
        [symbols addObject:symbol];
    }
    return [symbols copy];
}

+ (NSArray *)imagesForCollection:(Ama__SymbolsCollection *)collection
{
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:collection->n_images];
    for (NSUInteger idx = 0; idx < collection->n_images; ++idx) {
        Ama__SymbolsCollection__Image *imageMsg = collection->images[idx];
        NSString *UUID = [AMAProtobufUtilities stringForBinaryData:&imageMsg->uuid];
        NSString *name = [AMAProtobufUtilities stringForBinaryData:&imageMsg->name];
        NSUInteger cpuType = (NSUInteger)imageMsg->cpu_type;
        NSUInteger cpuSubtype = (NSUInteger)imageMsg->cpu_subtype;
        NSUInteger address = (NSUInteger)imageMsg->address;
        NSUInteger vmAddress = (NSUInteger)imageMsg->vm_address;
        NSUInteger size = (NSUInteger)imageMsg->size;
        AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:name
                                                                UUID:UUID
                                                             address:address
                                                                size:size
                                                           vmAddress:vmAddress
                                                             cpuType:cpuType
                                                          cpuSubtype:cpuSubtype
                                                        majorVersion:0
                                                        minorVersion:0
                                                     revisionVersion:0
                                                    crashInfoMessage:nil
                                                   crashInfoMessage2:nil];
        [images addObject:image];
    }
    return [images copy];
}

+ (NSArray *)dynamicBinaryNamesForCollection:(Ama__SymbolsCollection *)collection
{
    NSMutableArray *dynamicBinaryNames = [NSMutableArray arrayWithCapacity:collection->n_dynamic_binary_names];
    for (NSUInteger idx = 0; idx < collection->n_dynamic_binary_names; ++idx) {
        NSString *name = [AMAProtobufUtilities stringForBinaryData:collection->dynamic_binary_names + idx];
        [dynamicBinaryNames addObject:name];
    }
    return [dynamicBinaryNames copy];
}

@end
