
#import <Kiwi/Kiwi.h>
#import "AMATruncatedDataProcessingResult.h"

SPEC_BEGIN(AMATruncatedDataProcessingResultTests)

describe(@"AMATruncatedDataProcessingResult", ^{

    NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger bytesTruncated = 23;

    AMATruncatedDataProcessingResult *__block result = nil;

    beforeEach(^{
        result = [[AMATruncatedDataProcessingResult alloc] initWithData:data
                                                         bytesTruncated:bytesTruncated];
    });
    it(@"Should store data", ^{
        [[result.data should] equal:data];
    });
    it(@"Should store bytesTruncated", ^{
        [[theValue(result.bytesTruncated) should] equal:theValue(bytesTruncated)];
    });

});

SPEC_END
