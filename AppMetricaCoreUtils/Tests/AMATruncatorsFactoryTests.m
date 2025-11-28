
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMATruncatorsFactoryTests)

describe(@"AMATruncatorsFactory", ^{

    context(@"eventNameTruncator", ^{
        AMALengthStringTruncator *__block truncator = nil;
        beforeEach(^{
            truncator = [AMALengthStringTruncator stubbedNullMockForInit:@selector(initWithMaxLength:)];
        });
        afterEach(^{
            [AMALengthStringTruncator clearStubs];
        });
        
        it(@"Should create valid truncator", ^{
            [[truncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(1000)];
            [AMATruncatorsFactory eventNameTruncator];
        });
        it(@"Should return created truncator", ^{
            [[(NSObject *)[AMATruncatorsFactory eventNameTruncator] should] equal:truncator];
        });
    });
    context(@"eventStringValueTruncator", ^{
        AMABytesStringTruncator *__block truncator = nil;
        beforeEach(^{
            truncator = [AMABytesStringTruncator stubbedNullMockForInit:@selector(initWithMaxBytesLength:)];
        });
        afterEach(^{
            [AMABytesStringTruncator clearStubs];
        });
        
        it(@"Should create valid truncator", ^{
            [[truncator should] receive:@selector(initWithMaxBytesLength:) withArguments:theValue(230 * 1024)];
            [AMATruncatorsFactory eventStringValueTruncator];
        });
        it(@"Should return created truncator", ^{
            [[(NSObject *)[AMATruncatorsFactory eventStringValueTruncator] should] equal:truncator];
        });
    });
    context(@"eventBinaryValueTruncator", ^{
        AMADataTruncator *__block truncator = nil;
        
        beforeEach(^{
            truncator = [AMADataTruncator stubbedNullMockForInit:@selector(initWithMaxLength:)];
        });
        afterEach(^{
            [AMADataTruncator clearStubs];
        });
        
        it(@"Should create valid truncator", ^{
            [[truncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(230 * 1024)];
            [AMATruncatorsFactory eventBinaryValueTruncator];
        });
        it(@"Should return created truncator", ^{
            [[(NSObject *)[AMATruncatorsFactory eventBinaryValueTruncator] should] equal:truncator];
        });
    });
    context(@"extrasMigrationTruncator", ^{
        AMALengthStringTruncator *__block truncator = nil;
        
        beforeEach(^{
            truncator = [AMALengthStringTruncator stubbedNullMockForInit:@selector(initWithMaxLength:)];
        });
        afterEach(^{
            [AMALengthStringTruncator clearStubs];
        });
        
        it(@"Should create valid truncator", ^{
            [[truncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(10000)];
            [AMATruncatorsFactory extrasMigrationTruncator];
        });
        it(@"Should return created truncator", ^{
            [[(NSObject *)[AMATruncatorsFactory extrasMigrationTruncator] should] equal:truncator];
        });
    });
    context(@"profileID", ^{
        AMALengthStringTruncator *__block truncator = nil;
        
        beforeEach(^{
            truncator = [AMALengthStringTruncator stubbedNullMockForInit:@selector(initWithMaxLength:)];
        });
        afterEach(^{
            [AMALengthStringTruncator clearStubs];
        });
        
        it(@"Should create valid truncator", ^{
            [[truncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(200)];
            [AMATruncatorsFactory profileIDTruncator];
        });
        it(@"Should return created truncator", ^{
            [[(NSObject *)[AMATruncatorsFactory profileIDTruncator] should] equal:truncator];
        });
    });

});

SPEC_END
