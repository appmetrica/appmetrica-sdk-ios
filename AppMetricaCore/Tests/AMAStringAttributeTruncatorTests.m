
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStringAttributeTruncator.h"
#import "AMAUserProfileLogger.h"

SPEC_BEGIN(AMAStringAttributeTruncatorTests)

describe(@"AMAStringAttributeTruncator", ^{

    NSString *const name = @"ATTRIBUTE_NAME";
    NSString *const string = @"STRING";
    NSString *const truncatedString = @"TRUNCATED_STRING";
    NSUInteger const underlyingBytesTruncated = 23;

    AMATruncationBlock __block truncationBlock = nil;
    NSObject<AMAStringTruncating> *__block underlyingTruncator = nil;
    AMAStringAttributeTruncator *__block truncator = nil;

    beforeEach(^{
        [AMAUserProfileLogger stub:@selector(logStringAttributeValueTruncation:attributeName:)];
        underlyingTruncator = [KWMock nullMockForProtocol:@protocol(AMAStringTruncating)];
        [underlyingTruncator stub:@selector(truncatedString:onTruncation:) andReturn:truncatedString];
        truncator = [[AMAStringAttributeTruncator alloc] initWithAttributeName:name
                                                           underlyingTruncator:underlyingTruncator];
    });
    afterEach(^{
        [AMAUserProfileLogger clearStubs];
    });
    
    context(@"Nil block", ^{
        beforeEach(^{
            truncationBlock = nil;
        });
        context(@"Without underlying truncation", ^{
            it(@"Should call underlying truncator", ^{
                [[underlyingTruncator should] receive:@selector(truncatedString:onTruncation:)
                                        withArguments:string, kw_any()];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
            it(@"Should return truncated string", ^{
                [[[truncator truncatedString:string onTruncation:truncationBlock] should] equal:truncatedString];
            });
        });
        context(@"With underlying truncation", ^{
            beforeEach(^{
                [underlyingTruncator stub:@selector(truncatedString:onTruncation:) withBlock:^id(NSArray *params) {
                    AMATruncationBlock block = params[1];
                    if (block != nil) {
                        block(underlyingBytesTruncated);
                    }
                    return truncatedString;
                }];
            });
            it(@"Should not raise", ^{
                [[theBlock(^{
                    [truncator truncatedString:string onTruncation:truncationBlock];
                }) shouldNot] raise];
            });
            it(@"Should call underlying truncator", ^{
                [[underlyingTruncator should] receive:@selector(truncatedString:onTruncation:)
                                        withArguments:string, kw_any()];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
            it(@"Should return truncated string", ^{
                [[[truncator truncatedString:string onTruncation:truncationBlock] should] equal:truncatedString];
            });
            it(@"Should log", ^{
                [[AMAUserProfileLogger should] receive:@selector(logStringAttributeValueTruncation:attributeName:)
                                         withArguments:string, name];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
        });
    });
    context(@"Non-nil block", ^{
        NSNumber *__block bytesTruncated = nil;
        beforeEach(^{
            bytesTruncated = nil;
            truncationBlock = ^(NSUInteger actualBytesTruncated) {
                bytesTruncated = @(actualBytesTruncated);
            };
        });
        context(@"Without underlying truncation", ^{
            it(@"Should call underlying truncator", ^{
                [[underlyingTruncator should] receive:@selector(truncatedString:onTruncation:)
                                        withArguments:string, kw_any()];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
            it(@"Should return truncated string", ^{
                [[[truncator truncatedString:string onTruncation:truncationBlock] should] equal:truncatedString];
            });
        });
        context(@"With underlying truncation", ^{
            beforeEach(^{
                [underlyingTruncator stub:@selector(truncatedString:onTruncation:) withBlock:^id(NSArray *params) {
                    AMATruncationBlock block = params[1];
                    if (block != nil) {
                        block(underlyingBytesTruncated);
                    }
                    return truncatedString;
                }];
            });
            it(@"Should call underlying truncator", ^{
                [[underlyingTruncator should] receive:@selector(truncatedString:onTruncation:)
                                        withArguments:string, kw_any()];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
            it(@"Should return truncated string", ^{
                [[[truncator truncatedString:string onTruncation:truncationBlock] should] equal:truncatedString];
            });
            it(@"Should log", ^{
                [[AMAUserProfileLogger should] receive:@selector(logStringAttributeValueTruncation:attributeName:)
                                         withArguments:string, name];
                [truncator truncatedString:string onTruncation:truncationBlock];
            });
            it(@"Should call block with valid bytesTruncated", ^{
                [truncator truncatedString:string onTruncation:truncationBlock];
                [[bytesTruncated should] equal:@(underlyingBytesTruncated)];
            });
        });
    });

    it(@"Should conform to AMAStringTruncating", ^{
        [[truncator should] conformToProtocol:@protocol(AMAStringTruncating)];
    });
});

SPEC_END
