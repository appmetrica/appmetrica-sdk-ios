
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

SPEC_BEGIN(AMACompositeDataEncoderTests)

describe(@"AMACompositeDataEncoder", ^{

    NSData *const sourceData = [@"SOURCE" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const dataOfFirstEncoder = [@"FIRST" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const dataOfSecondEncoder = [@"SECOND" dataUsingEncoding:NSUTF8StringEncoding];

    NSObject<AMADataEncoding> *__block firstEncoder = nil;
    NSObject<AMADataEncoding> *__block secondEncoder = nil;
    AMACompositeDataEncoder *__block encoder = nil;

    beforeEach(^{
        firstEncoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        secondEncoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        encoder = [[AMACompositeDataEncoder alloc] initWithEncoders:@[firstEncoder, secondEncoder]];
    });

    context(@"Encoding", ^{
        beforeEach(^{
            [firstEncoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                return dataOfFirstEncoder;
            }];
            [secondEncoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                return dataOfSecondEncoder;
            }];
        });
        it(@"Should call first encoder", ^{
            [[firstEncoder should] receive:@selector(encodeData:error:) withArguments:sourceData, kw_any()];
            [encoder encodeData:sourceData error:NULL];
        });
        it(@"Should call second encoder", ^{
            [[secondEncoder should] receive:@selector(encodeData:error:) withArguments:dataOfFirstEncoder, kw_any()];
            [encoder encodeData:sourceData error:NULL];
        });
        it(@"Should return data of last encoder", ^{
            [[[encoder encodeData:sourceData error:NULL] should] equal:dataOfSecondEncoder];
        });
        context(@"First encoder error", ^{
            NSError *const expectedError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            beforeEach(^{
                [firstEncoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should not call second encoder", ^{
                [[secondEncoder shouldNot] receive:@selector(encodeData:error:)];
                [encoder encodeData:sourceData error:NULL];
            });
            it(@"Should return nil", ^{
                [[[encoder encodeData:sourceData error:NULL] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [encoder encodeData:sourceData error:&error];
                [[error should] equal:expectedError];
            });
        });
        context(@"Second encoder error", ^{
            NSError *const expectedError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            beforeEach(^{
                [secondEncoder stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[encoder encodeData:sourceData error:NULL] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [encoder encodeData:sourceData error:&error];
                [[error should] equal:expectedError];
            });
        });
    });

    context(@"Decoding", ^{
        beforeEach(^{
            [firstEncoder stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                return dataOfFirstEncoder;
            }];
            [secondEncoder stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                return dataOfSecondEncoder;
            }];
        });
        it(@"Should call second encoder", ^{
            [[secondEncoder should] receive:@selector(decodeData:error:) withArguments:sourceData, kw_any()];
            [encoder decodeData:sourceData error:NULL];
        });
        it(@"Should call first encoder", ^{
            [[firstEncoder should] receive:@selector(decodeData:error:) withArguments:dataOfSecondEncoder, kw_any()];
            [encoder decodeData:sourceData error:NULL];
        });
        it(@"Should return data of first encoder", ^{
            [[[encoder decodeData:sourceData error:NULL] should] equal:dataOfFirstEncoder];
        });
        context(@"Second encoder error", ^{
            NSError *const expectedError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            beforeEach(^{
                [secondEncoder stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should not call first encoder", ^{
                [[firstEncoder shouldNot] receive:@selector(decodeData:error:)];
                [encoder decodeData:sourceData error:NULL];
            });
            it(@"Should return nil", ^{
                [[[encoder decodeData:sourceData error:NULL] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [encoder decodeData:sourceData error:&error];
                [[error should] equal:expectedError];
            });
        });
        context(@"First encoder error", ^{
            NSError *const expectedError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            beforeEach(^{
                [firstEncoder stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                [[[encoder decodeData:sourceData error:NULL] should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [encoder decodeData:sourceData error:&error];
                [[error should] equal:expectedError];
            });
        });
    });
    
    it(@"Should comform to AMADataEncoding", ^{
        [[encoder should] conformToProtocol:@protocol(AMADataEncoding)];
    });
});

SPEC_END
