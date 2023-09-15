
#import <Kiwi/Kiwi.h>
#import "AMABinaryEventValue.h"

SPEC_BEGIN(AMABinaryEventValueTests)

describe(@"AMABinaryEventValue", ^{

    AMABinaryEventValue *__block value = nil;

    context(@"Empty data", ^{
        NSData *const data = [NSData data];
        beforeEach(^{
            value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
        });
        it(@"Should be empty", ^{
            [[theValue(value.empty) should] beYes];
        });
        it(@"Should return empty data", ^{
            [[[value dataWithError:nil] should] beEmpty];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [value dataWithError:&error];
            [[error should] beNil];
        });
        it(@"Should return no encryption type", ^{
            [[theValue(value.encryptionType) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
        });
    });

    context(@"Non-empty data", ^{
        NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
        beforeEach(^{
            value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
        });
        it(@"Should not be empty", ^{
            [[theValue(value.empty) should] beNo];
        });
        it(@"Should return valid data", ^{
            [[[value dataWithError:nil] should] equal:data];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [value dataWithError:&error];
            [[error should] beNil];
        });
        it(@"Should respond to GZip data getter", ^{
            [[value should] respondToSelector:@selector(gzippedDataWithError:)];
        });
        it(@"Should return nil for gzipped getter", ^{
            [[[value gzippedDataWithError:NULL] should] beNil];
        });
        it(@"Should return no encryption type", ^{
            [[theValue(value.encryptionType) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
        });
    });

    context(@"GZipped data", ^{
        NSData *const data = [@"GZIPPED_DATA" dataUsingEncoding:NSUTF8StringEncoding];
        beforeEach(^{
            value = [[AMABinaryEventValue alloc] initWithData:data gZipped:YES];
        });
        it(@"Should not be empty", ^{
            [[theValue(value.empty) should] beNo];
        });
        it(@"Should return valid data", ^{
            [[[value dataWithError:nil] should] equal:data];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [value dataWithError:&error];
            [[error should] beNil];
        });
        it(@"Should respond to GZip data getter", ^{
            [[value should] respondToSelector:@selector(gzippedDataWithError:)];
        });
        it(@"Should return valid data for gzipped getter", ^{
            [[[value gzippedDataWithError:NULL] should] equal:data];
        });
        it(@"Should return GZip encryption type", ^{
            [[theValue(value.encryptionType) should] equal:theValue(AMAEventEncryptionTypeGZip)];
        });
    });
    
    it(@"Should conform to AMAEventValueProtocol", ^{
        [[value should] conformToProtocol:@protocol(AMAEventValueProtocol)];
    });
});

SPEC_END

