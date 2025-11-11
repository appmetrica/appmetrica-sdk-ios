
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAnonymousActivationPolicy.h"

SPEC_BEGIN(AMAAnonymousActivationPolicyTests)

describe(@"AMAAnonymousActivationPolicy", ^{
    
    __block NSBundle *mockBundle = nil;
    NSString *const key = @"io.appmetrica.library_reporter_activation_allowed";
    __block AMAAnonymousActivationPolicy *mockPolicy = nil;
    
    beforeEach(^{
        mockBundle = [NSBundle nullMock];
        mockPolicy = [[AMAAnonymousActivationPolicy alloc] initWithBundle:mockBundle];
    });
    
    context(@"isAnonymousActivationAllowedForReporter should return", ^{
        it(@"YES when value is YES in Info.plist", ^{
            [mockBundle stub:@selector(objectForInfoDictionaryKey:) andReturn:@YES withArguments:key];
            
            [[theValue(mockPolicy.isAnonymousActivationAllowedForReporter) should] beYes];
        });
        
        it(@"NO when value is NO in Info.plist", ^{
            [mockBundle stub:@selector(objectForInfoDictionaryKey:) andReturn:@NO withArguments:key];
            
            [[theValue(mockPolicy.isAnonymousActivationAllowedForReporter) should] beNo];
        });
        
        it(@"default YES when value is not present in Info.plist", ^{
            [mockBundle stub:@selector(objectForInfoDictionaryKey:) andReturn:nil withArguments:key];
            
            [[theValue(mockPolicy.isAnonymousActivationAllowedForReporter) should] beYes];
        });
        
        it(@"default YES when value is invalid", ^{
            [mockBundle stub:@selector(objectForInfoDictionaryKey:) andReturn:@"not_a_bool" withArguments:key];
            
            [[theValue(mockPolicy.isAnonymousActivationAllowedForReporter) should] beYes];
        });
    });
});

SPEC_END
