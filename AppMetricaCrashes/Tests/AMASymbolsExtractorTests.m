
#import <Kiwi/Kiwi.h>
#import "AMASymbolsExtractor.h"
#import "AMACrashMatchingRule.h"
#import "AMASymbolsCollection.h"
#import "AMASymbol.h"
#import "AMABinaryImage.h"

#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

@interface AMASymbolsExtractor (Tests)

+ (NSArray *)symbolsOfClassesWithPrefixes:(NSArray *)prefixes;
+ (NSArray *)symbolsOfClasses:(NSArray *)classes;
+ (NSArray *)symbolsOfClass:(Class)aClass;
+ (AMASymbol *)symbolForMethod:(Method)method ofClass:(Class)aClass;

+ (NSArray *)symbolsWithFilledSize:(NSArray *)symbols;
+ (NSArray *)symbolsWithZeroSizeSymbolsDropped:(NSArray *)symbols;
+ (NSArray *)orderedSymbols:(NSArray *)symbols;
+ (NSString *)stringIgnoringNULL:(const char *)UTFString;

+ (void)enumerateClassesWithBlock:(void(^)(__unsafe_unretained Class aClass))block;
+ (void)enumerateMethodsOfClass:(Class)aClass
                          block:(void(^)(__unsafe_unretained Class aClass, Method method))block;
+ (void)enumerateMethodsOfPartialClass:(Class)aClass
                                 block:(void(^)(Class aClass, Method method))block;

+ (NSArray *)images;
+ (NSArray<AMABinaryImage *> *)filterUserImages:(NSArray<AMABinaryImage *> *)images;
+ (AMABinaryImage *)imageForImageIndex:(int)index;

@end

@interface AMASymbolsCollection (Tests)

@property (nonatomic, copy) NSSet *symbols;

@end

SPEC_BEGIN(AMASymbolsExtractorTests)

describe(@"AMASymbolsExtractor", ^{
    
    context(@"Symbol for method", ^{
        Class __block aClass = Nil;
        SEL __block selector = nil;

        Method __block method = NULL;
        BOOL __block isInstanceMethod = NO;
        NSString *__block className = nil;
        NSString *__block methodName = nil;
        NSString *__block symbolName = nil;
        NSUInteger __block symbolAddress = 0;

        AMASymbol *__block symbol = nil;

        void (^extractMethodInfo)(void) = ^{
            method = isInstanceMethod
                ? class_getInstanceMethod(aClass, selector)
                : class_getClassMethod(aClass, selector);

            IMP methodImplementation = method_getImplementation(method);
            Dl_info info;
            dladdr((void *)methodImplementation, &info);
            symbolAddress = (NSUInteger)info.dli_saddr;
            symbolName = [AMASymbolsExtractor stringIgnoringNULL:info.dli_sname];
        };

        context(@"-[AMASymbol address]", ^{

            beforeEach(^{
                aClass = [AMASymbol class];
                className = @"AMASymbol";
                selector = @selector(address);
                methodName = @"address";
                isInstanceMethod = YES;

                extractMethodInfo();
                symbol = [AMASymbolsExtractor symbolForMethod:method ofClass:aClass];
            });

            it(@"Should extract valid symbol address", ^{
                [[theValue(symbol.address) should] equal:theValue(symbolAddress)];
            });

            it(@"Should extract valid method name", ^{
                [[symbol.methodName should] equal:methodName];
            });

            it(@"Should extract valid class name", ^{
                [[symbol.className should] equal:className];
            });

            it(@"Should extract valid symbol name", ^{
                [[symbol.symbolName should] equal:symbolName];
            });

            it(@"Should extract valid symbol type", ^{
                [[theValue(symbol.instanceMethod) should] equal:theValue(isInstanceMethod)];
            });

            it(@"Should extract symbol without size", ^{
                [[theValue(symbol.size) should] equal:theValue(0)];
            });

        });

        context(@"+[AMASymbolsExtractor symbolForMethod:ofClass:]", ^{

            beforeEach(^{
                aClass = object_getClass([AMASymbolsExtractor class]);
                className = @"AMASymbolsExtractor";
                selector = @selector(symbolForMethod:ofClass:);
                methodName = @"symbolForMethod:ofClass:";
                isInstanceMethod = NO;

                extractMethodInfo();
                symbol = [AMASymbolsExtractor symbolForMethod:method ofClass:aClass];
            });

            it(@"Should extract valid symbol address", ^{
                [[theValue(symbol.address) should] equal:theValue(symbolAddress)];
            });

            it(@"Should extract valid method name", ^{
                [[symbol.methodName should] equal:methodName];
            });

            it(@"Should extract valid class name", ^{
                [[symbol.className should] equal:className];
            });

            it(@"Should extract valid symbol name", ^{
                [[symbol.symbolName should] equal:symbolName];
            });

            it(@"Should extract valid symbol type", ^{
                [[theValue(symbol.instanceMethod) should] equal:theValue(isInstanceMethod)];
            });

            it(@"Should extract symbol without size", ^{
                [[theValue(symbol.size) should] equal:theValue(0)];
            });

        });

    });

    context(@"Classes enumeration", ^{

        it(@"Should enumerate classes", ^{
            NSMutableArray *classes = [NSMutableArray array];
            [AMASymbolsExtractor enumerateClassesWithBlock:^(Class aClass) {
                NSString *className = NSStringFromClass(aClass);
                [classes addObject:className];
            }];
            [[classes should] containObjectsInArray:@[ @"NSArray", @"AMASymbolsExtractor", @"UIImage" ]];
        });

    });

    context(@"Methods enumeration", ^{
        Class aClass = [NSArray class];
        Class aMetaClass = object_getClass(aClass);

        it(@"Should enumerate methods of partitial not meta class", ^{
            NSMutableArray *methods = [NSMutableArray array];
            [AMASymbolsExtractor enumerateMethodsOfPartialClass:aClass block:^(Class aClass, Method method) {
                NSString *methodName = [AMASymbolsExtractor stringIgnoringNULL:sel_getName(method_getName(method))];
                [methods addObject:methodName];
            }];
            [[methods should] containObjectsInArray:@[ @"arrayByAddingObject:", @"count" ]];
        });

        it(@"Should enumerate methods of partitial meta class", ^{
            NSMutableArray *methods = [NSMutableArray array];
            [AMASymbolsExtractor enumerateMethodsOfPartialClass:aMetaClass block:^(Class aClass, Method method) {
                NSString *methodName = [AMASymbolsExtractor stringIgnoringNULL:sel_getName(method_getName(method))];
                [methods addObject:methodName];
            }];
            [[methods should] containObjectsInArray:@[ @"arrayWithArray:", @"array" ]];
        });

        it(@"Should not enumerate methods of Nil class", ^{
            BOOL __block enumerated = NO;
            [AMASymbolsExtractor enumerateMethodsOfPartialClass:Nil block:^(Class aClass, Method method) {
                enumerated = YES;
            }];
            [[theValue(enumerated) should] beNo];
        });

        context(@"Full class enumeration", ^{

            NSMutableArray *__block classesEnumerated = nil;

            beforeEach(^{
                classesEnumerated = [NSMutableArray array];
                [AMASymbolsExtractor stub:@selector(enumerateMethodsOfPartialClass:block:) withBlock:^id(NSArray *params) {
                    [classesEnumerated addObject:params[0]];
                    return nil;
                }];
            });

            it(@"Should enumerate static and instance methods", ^{
                [AMASymbolsExtractor enumerateMethodsOfClass:aClass block:^(Class aClass, Method method) { }];
                [[classesEnumerated should] containObjectsInArray:@[aClass, aMetaClass]];
            });

        });

    });

    context(@"Symbols processing", ^{
        NSArray *symbols = @[
            [[AMASymbol alloc] initWithMethodName:@"S1" className:@"C1" isInstanceMethod:YES address:42 size:0],
            [[AMASymbol alloc] initWithMethodName:@"S2" className:@"C1" isInstanceMethod:YES address:23 size:0],
            [[AMASymbol alloc] initWithMethodName:@"S3" className:@"C2" isInstanceMethod:YES address:4 size:0],
            [[AMASymbol alloc] initWithMethodName:@"S4" className:@"C2" isInstanceMethod:YES address:8 size:0],
        ];

        it(@"Should return nil string for NULL UTF8 string", ^{
            NSString *string = [AMASymbolsExtractor stringIgnoringNULL:NULL];
            [[string should] beNil];
        });

        it(@"Should return valid string for valid UTF8 string", ^{
            NSString *string = [AMASymbolsExtractor stringIgnoringNULL:"HELLO"];
            [[string should] equal:@"HELLO"];
        });

        it(@"Should order symbols by address", ^{
            NSArray *orderedSymbols = [AMASymbolsExtractor orderedSymbols:symbols];
            [[orderedSymbols should] equal:@[ symbols[2], symbols[3], symbols[1], symbols[0] ]];
        });

        it(@"Should fill symbols size", ^{
            NSArray *symbolsWithSize = [AMASymbolsExtractor symbolsWithFilledSize:symbols];
            [[symbolsWithSize should] contain:[symbols[1] symbolByChangingSize:19]];
            [[symbolsWithSize should] contain:[symbols[2] symbolByChangingSize:4]];
        });

        it(@"Should fill symbol with 1-byte size for last method of class", ^{
            NSArray *symbolsWithSize = [AMASymbolsExtractor symbolsWithFilledSize:symbols];
            [[symbolsWithSize should] contain:[symbols[0] symbolByChangingSize:1]];
            [[symbolsWithSize should] contain:[symbols[3] symbolByChangingSize:1]];
        });

    });

    context(@"Images extraction", ^{

        NSUInteger __block imageCount = 0;

        beforeEach(^{
            imageCount = (NSUInteger)_dyld_image_count();
        });
        
        it(@"Should call image extraction images count times", ^{
            [[AMASymbolsExtractor should] receive:@selector(imageForImageIndex:) withCount:imageCount];
            [AMASymbolsExtractor images];
        });

        it(@"Should extract all images", ^{
            NSArray *images = [AMASymbolsExtractor images];
            [[images should] haveCountOf:imageCount];
        });

        it(@"Should extract main executable image", ^{
            NSString *executablePath = [[NSBundle mainBundle] executablePath];
            NSArray *images = [AMASymbolsExtractor images];
            NSPredicate *imagePredicate = [NSPredicate predicateWithBlock:^BOOL(AMABinaryImage *image, id bindings) {
                return [image.name isEqualToString:executablePath];
            }];
            NSArray *filteredImages = [images filteredArrayUsingPredicate:imagePredicate];
            [[filteredImages should] haveCountOf:1];
        });
        
        context(@"User images", ^{
            
            __auto_type randomImageWithName = ^AMABinaryImage *(NSString *name) {
                return [[AMABinaryImage alloc] initWithName:name
                                                       UUID:NSUUID.UUID.UUIDString
                                                    address:(NSUInteger)random()
                                                       size:(NSUInteger)random()
                                                  vmAddress:(NSUInteger)random()
                                                    cpuType:1
                                                 cpuSubtype:1
                                               majorVersion:1
                                               minorVersion:0
                                            revisionVersion:0
                                           crashInfoMessage:nil
                                          crashInfoMessage2:nil];
            };
            
            AMABinaryImage *const expected = randomImageWithName(@"/private/var/containers/Bundle/Application/"
                                                                 "26EC5DE5-D587-4547-9D57-1261557874B8/"
                                                                 "MetricaSample.app/MetricaSample");
            NSArray *const images = @[
                randomImageWithName(@"/System/Library/PrivateFrameworks/Preferences.framework/Preferences"),
                randomImageWithName(@"/usr/lib/libAWDSupportFramework.dylib"),
                randomImageWithName(@"/usr/lib/system/libcommonCrypto.dylib"),
                randomImageWithName(@"/usr/lib/swift/libswift.dylib"),
                randomImageWithName(@"/Developers/usr/lib/system/libcommonCrypto.dylib"),
                randomImageWithName(@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library"
                                    "/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources"
                                    "/RuntimeRoot/System/Library/PrivateFrameworks/CoreServicesInternal.framework/"
                                    "CoreServicesInternal"),
                expected,
            ];
            
            it(@"Should filter user images", ^{
                [[[AMASymbolsExtractor filterUserImages:images].firstObject should] equal:expected];
            });
            
            it(@"Should have valid number of images", ^{
                [[theValue([AMASymbolsExtractor filterUserImages:images].count) should] equal:@1];
            });
        });
    });

    context(@"Symbols of class", ^{

        Class aClass = [AMASymbol class];
        Method method = class_getInstanceMethod(aClass, @selector(description));

        beforeEach(^{
            [AMASymbolsExtractor stub:@selector(symbolForMethod:ofClass:)];
            [AMASymbolsExtractor stub:@selector(enumerateMethodsOfClass:block:) withBlock:^id(NSArray *params) {
                Class aClass = params[0];
                void(^block)(Class class, Method method) = params[1];
                block(aClass, method);
                return nil;
            }];
        });

        it(@"Should enumerate methods of class", ^{
            KWCaptureSpy *spy = [AMASymbolsExtractor captureArgument:@selector(enumerateMethodsOfClass:block:)
                                                             atIndex:0];
            [AMASymbolsExtractor symbolsOfClass:aClass];
            [[spy.argument should] equal:aClass];
        });

        it(@"Should call symbol extraction with enumerated method", ^{
            [[AMASymbolsExtractor should] receive:@selector(symbolForMethod:ofClass:)
                                    withArguments:theValue(method), aClass];
            [AMASymbolsExtractor symbolsOfClass:aClass];
        });

        it(@"Should return array with extracted symbols", ^{
            AMASymbol *symbolMock = [AMASymbol nullMock];
            [AMASymbolsExtractor stub:@selector(symbolForMethod:ofClass:) andReturn:symbolMock];
            NSArray *symbols = [AMASymbolsExtractor symbolsOfClass:aClass];
            [[symbols should] contain: symbolMock];
        });

    });

    context(@"Symbols of classes", ^{
        NSArray *classes = @[ [NSArray class], [AMASymbol class] ];
        NSArray *symbolsOfClass = @[ [AMASymbol nullMock] ];

        beforeEach(^{
            [AMASymbolsExtractor stub:@selector(symbolsOfClass:) andReturn:symbolsOfClass];
        });

        it(@"Should extract symbols of class", ^{
            NSArray *symbols = [AMASymbolsExtractor symbolsOfClasses:classes];
            [[symbols should] haveCountOf:classes.count * symbolsOfClass.count];
            [[symbols should] contain:symbolsOfClass.firstObject];
        });

        it(@"Should return empty symbols array for empty classes array", ^{
            NSArray *symbols = [AMASymbolsExtractor symbolsOfClasses:nil];
            [[symbols should] beEmpty];
        });
        
    });

    context(@"Symbols of clases with prefixes", ^{
        Class classWithPrefix = [AMASymbol class];
        NSString *prefix = @"AMA";
        NSArray *classes = @[ classWithPrefix, [NSArray class] ];
        NSArray *symbolsMock = [NSArray nullMock];
        KWCaptureSpy *__block filteredClassesSpy = nil;

        beforeEach(^{
            [AMASymbolsExtractor stub:@selector(symbolsOfClasses:) andReturn:symbolsMock];
            [AMASymbolsExtractor stub:@selector(enumerateClassesWithBlock:) withBlock:^id(NSArray *params) {
                void(^block)(Class aClass) = params[0];
                for (Class aClass in classes) {
                    block(aClass);
                }
                return nil;
            }];
            filteredClassesSpy = [AMASymbolsExtractor captureArgument:@selector(symbolsOfClasses:) atIndex:0];
        });

        it(@"Should filter classes by prefix", ^{
            [AMASymbolsExtractor symbolsOfClassesWithPrefixes:@[ prefix ]];
            [[filteredClassesSpy.argument should] equal:@[ classWithPrefix ]];
        });

        it(@"Should return symbols of filtered classes", ^{
            NSArray *symbols = [AMASymbolsExtractor symbolsOfClassesWithPrefixes:@[ prefix ]];
            [[symbols should] equal:symbolsMock];
        });

    });

    context(@"Symbols collection", ^{

        NSArray *symbolsOfClasses = @[ [AMASymbol mock] ];
        NSArray *symbolsOfClassesWithPrefixes = @[ [AMASymbol mock] ];
        NSArray *symbolsWithFilledSize = @[ [AMASymbol mock] ];
        NSArray *images = @[ [AMABinaryImage nullMock] ];

        NSArray *classes = @[ [AMASymbol class] ];
        NSArray *classPrefixes = @[ @"AMA" ];
        AMACrashMatchingRule *__block rule = nil;
        AMASymbolsCollection *__block symbolsCollection = nil;

        beforeEach(^{
            rule = [[AMACrashMatchingRule alloc] initWithClasses:classes classPrefixes:classPrefixes];

            [AMASymbolsExtractor stub:@selector(symbolsOfClasses:) andReturn:symbolsOfClasses];
            [AMASymbolsExtractor stub:@selector(symbolsOfClassesWithPrefixes:) andReturn:symbolsOfClassesWithPrefixes];
            [AMASymbolsExtractor stub:@selector(symbolsWithFilledSize:) andReturn:symbolsWithFilledSize];
            [AMASymbolsExtractor stub:@selector(sharedImages) andReturn:images];
            symbolsCollection = [AMASymbolsCollection mock];
            [symbolsCollection stub:@selector(initWithSymbols:images:dynamicBinaryNames:) andReturn:symbolsCollection];
            [AMASymbolsCollection stub:@selector(alloc) andReturn:symbolsCollection];
        });

        it(@"Should extract symbols for classes from rule", ^{
            KWCaptureSpy *spy = [AMASymbolsExtractor captureArgument:@selector(symbolsOfClasses:) atIndex:0];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
            [[spy.argument should] equal:classes];
        });

        it(@"Should not extract symbols from empty classes array", ^{
            [rule stub:@selector(classes) andReturn:@[]];
            [[AMASymbolsExtractor shouldNot] receive:@selector(symbolsOfClasses:)];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
        });

        it(@"Should not extract symbols for class prefixes from rule", ^{
            [[AMASymbolsExtractor shouldNot] receive:@selector(symbolsOfClassesWithPrefixes:)];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
        });

        it(@"Should not extract symbols from empty classes array", ^{
            [rule stub:@selector(classPrefixes) andReturn:@[]];
            [[AMASymbolsExtractor shouldNot] receive:@selector(symbolsOfClassesWithPrefixes:)];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
        });

        it(@"Should fill extracted symbols size is symbols found", ^{
            KWCaptureSpy *spy = [AMASymbolsExtractor captureArgument:@selector(symbolsWithFilledSize:)
                                                             atIndex:0];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
            [[spy.argument should] containObjectsInArray:symbolsOfClasses];
        });

        it(@"Should extract images", ^{
            [[AMASymbolsExtractor should] receive:@selector(sharedImages)];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
        });

        it(@"Should create collection with filled symbols", ^{
            KWCaptureSpy *spy = [symbolsCollection captureArgument:@selector(initWithSymbols:images:dynamicBinaryNames:)
                                                           atIndex:0];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
            [[spy.argument should] equal:symbolsWithFilledSize];
        });

        it(@"Should create collection with extracted images", ^{
            KWCaptureSpy *spy = [symbolsCollection captureArgument:@selector(initWithSymbols:images:dynamicBinaryNames:)
                                                           atIndex:1];
            [AMASymbolsExtractor symbolsCollectionForRule:rule];
            [[spy.argument should] equal:images];
        });

        it(@"Should return created collection", ^{
            AMASymbolsCollection *collection = [AMASymbolsExtractor symbolsCollectionForRule:rule];
            [[collection should] equal:symbolsCollection];
        });

    });

});

SPEC_END
