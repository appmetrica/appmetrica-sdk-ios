
#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import "AMAVersionMatcher.h"

SPEC_BEGIN(AMAVersionMatcherTests)

describe(@"AMAVersionMatcher", ^{
    
    __auto_type itShouldMatch = ^(NSString *version, NSString *constraint) {
        it([NSString stringWithFormat:@"Should match %@ with %@ constarint", version, constraint], ^{
            [[theValue([AMAVersionMatcher isVersion:version matchesPessimisticConstraint:constraint]) should] beYes];
        });
    };
    
    __auto_type itShouldNotMatch = ^(NSString *version, NSString *constraint) {
        it([NSString stringWithFormat:@"Should not match %@ with %@ constarint", version, constraint], ^{
            [[theValue([AMAVersionMatcher isVersion:version matchesPessimisticConstraint:constraint]) shouldNot] beYes];
        });
    };
    
    itShouldMatch(@"3.0.1.1", @"3.0.1");
    itShouldMatch(@"3.0.1", @"3.0.1");
    itShouldMatch(@"3.0.1", @"3.0");
    itShouldMatch(@"3.0.0", @"3.0");
    itShouldMatch(@"3.1", @"3");
    itShouldMatch(@"3.1.1", @"3");
    itShouldMatch(@"3.0.1", @"3");
    itShouldMatch(@"3.0", @"3.0.0");
    itShouldMatch(@"3", @"3.0.0");
    
    itShouldNotMatch(@"3.0.2.1", @"3.0.1");
    itShouldNotMatch(@"3.0.2", @"3.0.1");
    itShouldNotMatch(@"3.0.1", @"3.0.0");
    itShouldNotMatch(@"3.0", @"3.0.1");
    itShouldNotMatch(@"3", @"3.0.1");
    itShouldNotMatch(@"3.0", @"3.2");
    itShouldNotMatch(@"3.3", @"3.2");
    itShouldNotMatch(@"3.0.1", @"4");
    itShouldNotMatch(@"3.0", @"4");
    itShouldNotMatch(@"3", @"4");
});

SPEC_END
