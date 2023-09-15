
#import <Kiwi/Kiwi.h>
#import "AMADateAttribute.h"
#import "AMAStringAttribute.h"
#import "AMAInvalidUserProfileUpdateFactory.h"

SPEC_BEGIN(AMADateAttributeTests)

describe(@"AMADateAttribute", ^{

    AMAStringAttribute *__block stringAttribute = nil;
    AMAUserProfileUpdate *__block stringAttributeUpdate = nil;
    AMADateAttribute *__block attribute = nil;

    beforeEach(^{
        stringAttribute = [AMAStringAttribute nullMock];
        stringAttributeUpdate = [AMAUserProfileUpdate nullMock];
        attribute = [[AMADateAttribute alloc] initWithStringAttribute:stringAttribute];
    });

    context(@"With value", ^{
        NSUInteger const year = 1999;
        NSUInteger const month = 7;
        NSUInteger const day = 12;
        beforeEach(^{
            [stringAttribute stub:@selector(withValue:) andReturn:stringAttributeUpdate];
        });
        context(@"Age", ^{
            NSUInteger const age = 18;
            NSString *__block expectedDateString = @"2000";
            beforeEach(^{
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:1515114000]; // 2018-01-05 01:00:00
                [NSDate stub:@selector(date) andReturn:date];
            });
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:expectedDateString];
                [attribute withAge:age];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withAge:age] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Year", ^{
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999"];
                [attribute withYear:year];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withYear:year] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Year and month", ^{
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999-07"];
                [attribute withYear:year month:month];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withYear:year month:month] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Year, month and day", ^{
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999-07-12"];
                [attribute withYear:year month:month day:day];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withYear:year month:month day:day] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Date components", ^{
            NSDateComponents *__block components = nil;
            beforeEach(^{
                components = [[NSDateComponents alloc] init];
            });
            context(@"With year", ^{
                beforeEach(^{
                    components.year = year;
                });
                context(@"With month", ^{
                    beforeEach(^{
                        components.month = month;
                    });
                    context(@"With day", ^{
                        beforeEach(^{
                            components.day = day;
                        });
                        it(@"Should request valid string attribute update", ^{
                            [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999-07-12"];
                            [attribute withDateComponents:components];
                        });
                        it(@"Should return string attribute update", ^{
                            [[[attribute withDateComponents:components] should] equal:stringAttributeUpdate];
                        });
                    });
                    context(@"Without day", ^{
                        it(@"Should request valid string attribute update", ^{
                            [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999-07"];
                            [attribute withDateComponents:components];
                        });
                        it(@"Should return string attribute update", ^{
                            [[[attribute withDateComponents:components] should] equal:stringAttributeUpdate];
                        });
                    });
                });
                context(@"Without month", ^{
                    context(@"With day", ^{
                        beforeEach(^{
                            components.day = day;
                        });
                        it(@"Should request valid string attribute update", ^{
                            [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999"];
                            [attribute withDateComponents:components];
                        });
                        it(@"Should return string attribute update", ^{
                            [[[attribute withDateComponents:components] should] equal:stringAttributeUpdate];
                        });
                    });
                    context(@"Without day", ^{
                        it(@"Should request valid string attribute update", ^{
                            [[stringAttribute should] receive:@selector(withValue:) withArguments:@"1999"];
                            [attribute withDateComponents:components];
                        });
                        it(@"Should return string attribute update", ^{
                            [[[attribute withDateComponents:components] should] equal:stringAttributeUpdate];
                        });
                    });
                });
            });
            context(@"Invalid", ^{
                NSString *const name = @"ATTRIBUTE_NAME";
                AMAUserProfileUpdate *__block invalidUpdate = nil;

                beforeEach(^{
                    invalidUpdate = [AMAUserProfileUpdate nullMock];
                    [AMAInvalidUserProfileUpdateFactory stub:@selector(invalidDateUpdateWithAttributeName:)
                                                   andReturn:invalidUpdate];
                    [stringAttribute clearStubs];
                    [stringAttribute stub:@selector(withValueReset) andReturn:stringAttributeUpdate];
                    [stringAttribute stub:@selector(name) andReturn:name];
                });
                context(@"Nil", ^{
                    beforeEach(^{
                        components = nil;
                    });
                    it(@"Should request valid string attribute update", ^{
                        [[AMAInvalidUserProfileUpdateFactory should] receive:@selector(invalidDateUpdateWithAttributeName:)
                                                               withArguments:name];
                        [attribute withDateComponents:components];
                    });
                    it(@"Should return string attribute update", ^{
                        [[[attribute withDateComponents:components] should] equal:invalidUpdate];
                    });
                });
                context(@"Without year", ^{
                    it(@"Should request valid string attribute update", ^{
                        [[AMAInvalidUserProfileUpdateFactory should] receive:@selector(invalidDateUpdateWithAttributeName:)
                                                               withArguments:name];
                        [attribute withDateComponents:components];
                    });
                    it(@"Should return string attribute update", ^{
                        [[[attribute withDateComponents:components] should] equal:invalidUpdate];
                    });
                });
            });
        });
    });
    context(@"With reset", ^{
        beforeEach(^{
            [stringAttribute stub:@selector(withValueReset) andReturn:stringAttributeUpdate];
        });
        it(@"Should request valid string attribute update", ^{
            [[stringAttribute should] receive:@selector(withValueReset)];
            [attribute withValueReset];
        });
        it(@"Should return string attribute update", ^{
            [[[attribute withValueReset] should] equal:stringAttributeUpdate];
        });
    });

    it(@"Should conform to AMABirthDateAttribute", ^{
        [[attribute should] conformToProtocol:@protocol(AMABirthDateAttribute)];
    });
});

SPEC_END
