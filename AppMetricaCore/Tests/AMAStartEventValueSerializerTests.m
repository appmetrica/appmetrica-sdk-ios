
#import <Kiwi/Kiwi.h>

#import "AMAStartEventValueSerializer.h"

SPEC_BEGIN(AMAStartEventValueSerializerTests)

    describe(@"AMAStartEventValueSerializer", ^{
        
        static NSString *const base64String = @"EiYKJDZkMjA3N2FlLTA4N2EtNGI1OS04NjZlLTIyNTk4OTNjOWFhYxImCiQ2NzBkMzA2N"
            "S01MTc5LTRmNmMtODA3MS1kY2Q3ZWNlZTg2MjQSJgokYjAzZWVkMDctNzljYS00NTAwLTk1NzgtNDQ5M2Q3ZjQ3MTNl";
        
        NSArray *const uuids = @[
            @"6d2077ae-087a-4b59-866e-2259893c9aac",
            @"670d3065-5179-4f6c-8071-dcd7ecee8624",
            @"b03eed07-79ca-4500-9578-4493d7f4713e",
        ];
        
        NSData *const expectedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];

        AMAStartEventValueSerializer *__block serialier = nil;
        
        beforeEach(^{
            serialier = [[AMAStartEventValueSerializer alloc] init];
        });
        
        it(@"Should serialize", ^{
            [[[serialier dataForUUIDs:uuids] should] equal:expectedData];
        });
    });

SPEC_END
