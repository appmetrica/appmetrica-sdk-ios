#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAdProviderResolver.h"
#import "AMAAdProviderProxy.h"

SPEC_BEGIN(AMAAdProviderResolverTests)

describe(@"AMAAdProviderResolver", ^{
    AMAAdProviderProxy *__block adProviderProxy = nil;
    AMAAdProviderResolver *__block resolver = nil;
    
    beforeEach(^{
        adProviderProxy = [AMAAdProviderProxy nullMock];
        [adProviderProxy stub:@selector(setEnabled:)];
        resolver = [[AMAAdProviderResolver alloc] initWithAdProviderProxy:adProviderProxy];
    });
    
    context(@"Update value", ^{
        it(@"should call setEnabled", ^{
            [[adProviderProxy should] receive:@selector(setEnabled:) withArguments:theValue(NO)];
            [resolver updateWithValue:NO];
        });
    });
});

SPEC_END
