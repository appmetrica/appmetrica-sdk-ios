
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

SPEC_BEGIN(AMAUserDefaultsStorageTests)

describe(@"AMAUserDefaultsStorage", ^{

    AMAUserDefaultsStorage *__block storage = nil;
    NSUserDefaults *__block defaults = nil;

    NSString *const key = @"key";
    NSString *const prefixedKey = @"io.appmetrica.sdk.key";

    beforeEach(^{
        storage = [[AMAUserDefaultsStorage alloc] init];

        defaults = [NSUserDefaults nullMock];
        [NSUserDefaults stub:@selector(standardUserDefaults) andReturn:defaults];
    });
    afterEach(^{
        [NSUserDefaults clearStubs];
    });

    it(@"Should call synchronize", ^{
        [[defaults should] receive:@selector(synchronize)];
        [storage synchronize];
    });

    context(@"String", ^{

        NSString *const value = @"string";

        it(@"Should store value with prefixed key", ^{
            [[defaults should] receive:@selector(setObject:forKey:) withArguments:value, prefixedKey];
            [storage setObject:value forKey:key];
        });

        it(@"Should not call syncronize after setting", ^{
            [[defaults shouldNot] receive:@selector(synchronize)];
            [storage setObject:value forKey:key];
        });

        it(@"Should return stored value by prefixed key", ^{
            [defaults stub:@selector(stringForKey:) andReturn:value withArguments:prefixedKey];
            NSString *result = [storage stringForKey:key];
            [[result should] equal:value];
        });

    });

    context(@"Bool", ^{

        BOOL const value = YES;

        it(@"Should store value with prefixed key", ^{
            [[defaults should] receive:@selector(setBool:forKey:) withArguments:theValue(value), prefixedKey];
            [storage setBool:value forKey:key];
        });

        it(@"Should not call syncronize after setting", ^{
            [[defaults shouldNot] receive:@selector(synchronize)];
            [storage setBool:value forKey:key];
        });

        it(@"Should return stored value by prefixed key", ^{
            [defaults stub:@selector(boolForKey:) andReturn:theValue(value) withArguments:prefixedKey];
            BOOL result = [storage boolForKey:key];
            [[theValue(result) should] equal:theValue(value)];
        });
        
    });

});

SPEC_END
