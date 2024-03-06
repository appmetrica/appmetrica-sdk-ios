
#import <Kiwi/Kiwi.h>
#import "AMABuildUID.h"

SPEC_BEGIN(AMABuildUIDTests)

describe(@"AMABuildUID", ^{
    
    it(@"Should correcty create buildUID from build __DATE__ __TIME__", ^{
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        [buildUID shouldNotBeNil];
        [buildUID.stringValue shouldNotBeNil];
    });
    
    it(@"Should initialize correctly with a given date", ^{
        NSDate *specificDate = [NSDate dateWithTimeIntervalSince1970:1500000000];
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithDate:specificDate];
        
        NSTimeInterval timestamp = [buildUID.stringValue doubleValue];
        [[theValue(timestamp) should] equal:theValue(1500000000)];
    });
    
    it(@"Should compare two build UIDs correctly", ^{
        NSDate *earlierDate = [NSDate dateWithTimeIntervalSince1970:1000000000];
        NSDate *laterDate = [NSDate dateWithTimeIntervalSince1970:1500000000];
        
        AMABuildUID *earlierBuildUID = [[AMABuildUID alloc] initWithDate:earlierDate];
        AMABuildUID *laterBuildUID = [[AMABuildUID alloc] initWithDate:laterDate];
        
        [[theValue([earlierBuildUID compare:laterBuildUID]) should] equal:theValue(NSOrderedAscending)];
        [[theValue([laterBuildUID compare:earlierBuildUID]) should] equal:theValue(NSOrderedDescending)];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    it(@"Should return nil when initialized with a nil date", ^{
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithDate:nil];
        
        [[buildUID should] beNil];
    });
    
    it(@"Should return nil when initialized with a non-UNIX timestamp string", ^{
        NSString *nonUnixTimestampString = @"Not a timestamp";
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithString:nonUnixTimestampString];
        
        [[buildUID should] beNil];
    });
    
    it(@"Should return nil when initialized with a nil string", ^{
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithString:nil];
        
        [[buildUID should] beNil];
    });
#pragma clang diagnostic pop
    it(@"Should initialize correctly with a valid UNIX timestamp string", ^{
        NSString *unixTimestampString = @"1617181920";
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithString:unixTimestampString];
        
        [[buildUID shouldNot] beNil];
        
        [[buildUID.stringValue should] equal:unixTimestampString];
    });
    
    it(@"Should initialize correctly with a valid date and check stringValue", ^{
        NSDate *validDate = [NSDate date];
        AMABuildUID *buildUID = [[AMABuildUID alloc] initWithDate:validDate];
        [[buildUID shouldNot] beNil];
        
        NSString *expectedTimestampString = [NSString stringWithFormat:@"%ld", (long)[validDate timeIntervalSince1970]];
        [[buildUID.stringValue should] equal:expectedTimestampString];
    });

    it(@"Should conform to NSCopying", ^{
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        [[buildUID should] conformToProtocol:@protocol(NSCopying)];
    });
    
    it(@"Should conform to NSSecureCoding", ^{
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        [[buildUID should] conformToProtocol:@protocol(NSSecureCoding)];
    });
});


SPEC_END
