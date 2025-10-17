
#import <Kiwi/Kiwi.h>
#import "AMABinaryImageExtractor.h"
#import "AMABinaryImage.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

@interface AMABinaryImageExtractor (Tests)

+ (NSArray *)images;
+ (NSArray<AMABinaryImage *> *)filterUserImages:(NSArray<AMABinaryImage *> *)images;
+ (AMABinaryImage *)imageForImageIndex:(int)index;

@end

SPEC_BEGIN(AMABinaryImageExtractorTests)

describe(@"AMABinaryImageExtractor", ^{

    context(@"Images extraction", ^{

        NSUInteger __block imageCount = 0;

        beforeEach(^{
            imageCount = (NSUInteger)_dyld_image_count();
        });
        
        it(@"Should call image extraction images count times", ^{
            [[AMABinaryImageExtractor should] receive:@selector(imageForImageIndex:) withCount:imageCount];
            [AMABinaryImageExtractor images];
        });

        it(@"Should extract all images", ^{
            NSArray *images = [AMABinaryImageExtractor images];
            [[images should] haveCountOf:imageCount];
        });

        it(@"Should extract main executable image", ^{
            NSString *executablePath = [[NSBundle mainBundle] executablePath];
            NSArray *images = [AMABinaryImageExtractor images];
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
                [[[AMABinaryImageExtractor filterUserImages:images].firstObject should] equal:expected];
            });
            
            it(@"Should have valid number of images", ^{
                [[theValue([AMABinaryImageExtractor filterUserImages:images].count) should] equal:@1];
            });
        });
    });

});

SPEC_END
