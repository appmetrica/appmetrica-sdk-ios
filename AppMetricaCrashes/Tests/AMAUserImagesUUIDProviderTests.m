
#import <Kiwi/Kiwi.h>

#import "AMAUserImagesUUIDProvider.h"
#import "AMASymbolsExtractor.h"
#import "AMABinaryImage.h"

SPEC_BEGIN(AMAUserImagesUUIDProviderTests)

    describe(@"AMAUserImagesUUIDProvider", ^{
        
        NSArray *const kAMAExpectedUUIDs = @[
            @"123e4567-e89b-12d3-a456-426655440000",
            @"643e4567-afdb-14d3-14f6-642663440000"
        ];
        
        AMAUserImagesUUIDProvider *__block provider = nil;
        
        beforeEach(^{
            AMABinaryImage *firstImage = [[AMABinaryImage alloc] initWithName:@"First"
                                                                         UUID:kAMAExpectedUUIDs[0]
                                                                      address:0xDEADBEEF
                                                                         size:123
                                                                    vmAddress:0xDEADBEEF
                                                                      cpuType:1
                                                                   cpuSubtype:2
                                                                 majorVersion:1
                                                                 minorVersion:0
                                                              revisionVersion:0
                                                             crashInfoMessage:nil
                                                            crashInfoMessage2:nil];
            
            AMABinaryImage *secondImage = [[AMABinaryImage alloc] initWithName:@"Second"
                                                                          UUID:kAMAExpectedUUIDs[1]
                                                                       address:0xDEADC0DE
                                                                          size:467
                                                                     vmAddress:0xDEADC0DE
                                                                       cpuType:1
                                                                    cpuSubtype:2
                                                                  majorVersion:2
                                                                  minorVersion:3
                                                               revisionVersion:6
                                                              crashInfoMessage:nil
                                                             crashInfoMessage2:nil];
            
            [AMASymbolsExtractor stub:@selector(userApplicationImages) andReturn:@[ firstImage, secondImage ]];
            
            provider = [[AMAUserImagesUUIDProvider alloc] init];
        });
        
        it(@"Should extract UUIDs", ^{
            [[provider.UUIDs should] containObjectsInArray:kAMAExpectedUUIDs];
        });
        
    });

SPEC_END
