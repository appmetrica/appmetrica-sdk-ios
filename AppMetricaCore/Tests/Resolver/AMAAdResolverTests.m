#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>
#import "AMAAdProviderResolver.h"
#import "AMAAdProvider.h"

SPEC_BEGIN(AMAAdProviderResolverTests)

describe(@"AMAAdProviderResolver", ^{
    AMAAdProvider *__block adProvider = nil;
    AMAAdProviderResolver *__block resolver = nil;
    
    beforeEach(^{
        adProvider = [AMAAdProvider nullMock];
        [adProvider stub:@selector(setEnabled:)];
        resolver = [[AMAAdProviderResolver alloc] initWithAdProvider:adProvider];
    });
    
    context(@"Update value", ^{
        it(@"should call setEnabled", ^{
            [[adProvider should] receive:@selector(setEnabled:) withArguments:theValue(NO)];
            [resolver updateWithValue:NO];
        });
    });
});

SPEC_END

