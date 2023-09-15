
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAKeyValueStorage.h"
#import "AMAKeyValueStorageConverting.h"

SPEC_BEGIN(AMAKeyValueStorageTests)

describe(@"AMAKeyValueStorage", ^{

    NSString *const key = @"KEY";
    NSString *const convertedValue = @"CONVERTED_VALUE";

    NSObject<AMAKeyValueStorageDataProviding> *__block provider = nil;
    NSObject<AMAKeyValueStorageConverting> *__block converter = nil;
    AMAKeyValueStorage *__block storage = nil;

    beforeEach(^{
        provider = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageDataProviding)];
        [provider stub:@selector(objectForKey:error:) andReturn:convertedValue];
        [provider stub:@selector(saveObject:forKey:error:) andReturn:theValue(YES)];
        [provider stub:@selector(removeKey:error:) andReturn:theValue(YES)];
        converter = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageConverting)];
        storage = [[AMAKeyValueStorage alloc] initWithDataProvider:provider converter:converter];
    });

    context(@"String", ^{
        NSString *const value = @"VALUE";
        beforeEach(^{
            [converter stub:@selector(stringForObject:) andReturn:value];
            [converter stub:@selector(objectForString:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage stringForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(stringForObject:) withArguments:convertedValue];
                [storage stringForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage stringForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage stringForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForString:) withArguments:value];
                [storage saveString:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveString:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveString:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveString:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveString:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"Data", ^{
        NSData *const value = [@"VALUE" dataUsingEncoding:NSUTF8StringEncoding];
        beforeEach(^{
            [converter stub:@selector(dataForObject:) andReturn:value];
            [converter stub:@selector(objectForData:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage dataForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(dataForObject:) withArguments:convertedValue];
                [storage dataForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage dataForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage dataForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForData:) withArguments:value];
                [storage saveData:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveData:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveData:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveData:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveData:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"long long", ^{
        NSNumber *const value = @23;
        beforeEach(^{
            [converter stub:@selector(longLongForObject:) andReturn:theValue(value.longLongValue)];
            [converter stub:@selector(objectForLongLong:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage longLongNumberForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(longLongForObject:) withArguments:convertedValue];
                [storage longLongNumberForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage longLongNumberForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage longLongNumberForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForLongLong:) withArguments:theValue(value.longLongValue)];
                [storage saveLongLongNumber:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveLongLongNumber:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveLongLongNumber:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveLongLongNumber:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveLongLongNumber:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });
    
    context(@"unsigned long long", ^{
        NSNumber *const value = @23;
        beforeEach(^{
            [converter stub:@selector(unsignedLongLongForObject:) andReturn:theValue(value.unsignedLongLongValue)];
            [converter stub:@selector(objectForUnsignedLongLong:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage unsignedLongLongNumberForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(unsignedLongLongForObject:) withArguments:convertedValue];
                [storage unsignedLongLongNumberForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage unsignedLongLongNumberForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage unsignedLongLongNumberForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForUnsignedLongLong:)
                              withArguments:theValue(value.longLongValue)];
                [storage saveUnsignedLongLongNumber:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:)
                             withArguments:convertedValue, key, kw_any()];
                [storage saveUnsignedLongLongNumber:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveUnsignedLongLongNumber:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveUnsignedLongLongNumber:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveUnsignedLongLongNumber:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });
         
    context(@"double", ^{
        NSNumber *const value = @(23.42);
        beforeEach(^{
            [converter stub:@selector(doubleForObject:) andReturn:theValue(value.doubleValue)];
            [converter stub:@selector(objectForDouble:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage doubleNumberForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(doubleForObject:) withArguments:convertedValue];
                [storage doubleNumberForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage doubleNumberForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage doubleNumberForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForDouble:) withArguments:theValue(value.doubleValue)];
                [storage saveDoubleNumber:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveDoubleNumber:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveDoubleNumber:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveDoubleNumber:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveDoubleNumber:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"bool", ^{
        NSNumber *const value = @YES;
        beforeEach(^{
            [converter stub:@selector(boolForObject:) andReturn:theValue(YES)];
            [converter stub:@selector(objectForBool:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage boolNumberForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(boolForObject:) withArguments:convertedValue];
                [storage boolNumberForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage boolNumberForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage boolNumberForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForBool:) withArguments:theValue(value.boolValue)];
                [storage saveBoolNumber:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveBoolNumber:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveBoolNumber:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveBoolNumber:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveBoolNumber:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"Date", ^{
        NSDate *const value = [NSDate date];
        beforeEach(^{
            [converter stub:@selector(dateForObject:) andReturn:value];
            [converter stub:@selector(objectForDate:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage dateForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(dateForObject:) withArguments:convertedValue];
                [storage dateForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage dateForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage dateForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForDate:) withArguments:value];
                [storage saveDate:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveDate:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveDate:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveDate:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveDate:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"Dictionary", ^{
        NSDictionary *const value = @{ @"foo": @"bar" };
        beforeEach(^{
            [converter stub:@selector(stringForObject:) andReturn:@"{\"foo\":\"bar\"}"];
            [converter stub:@selector(objectForString:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage jsonDictionaryForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(stringForObject:) withArguments:convertedValue];
                [storage jsonDictionaryForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage jsonDictionaryForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonDictionaryForKey:key error:nil] should] beNil];
                });
            });
            context(@"Invalid string", ^{
                beforeEach(^{
                    [converter stub:@selector(stringForObject:) andReturn:@"Not a JSON"];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonDictionaryForKey:key error:nil] should] beNil];
                });
            });
            context(@"Invalid JSON object", ^{
                beforeEach(^{
                    [converter stub:@selector(stringForObject:) andReturn:@"[\"foo\",\"bar\"]"];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonDictionaryForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForString:) withArguments:@"{\"foo\":\"bar\"}"];
                [storage saveJSONDictionary:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveJSONDictionary:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveJSONDictionary:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveJSONDictionary:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveJSONDictionary:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });

    context(@"Array", ^{
        NSArray *const value = @[ @"foo", @"bar" ];
        beforeEach(^{
            [converter stub:@selector(stringForObject:) andReturn:@"[\"foo\",\"bar\"]"];
            [converter stub:@selector(objectForString:) andReturn:convertedValue];
        });
        context(@"Get", ^{
            it(@"Should get converted value for a valid key", ^{
                [[provider should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [storage jsonArrayForKey:key error:nil];
            });
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(stringForObject:) withArguments:convertedValue];
                [storage jsonArrayForKey:key error:nil];
            });
            it(@"Should return valid value", ^{
                [[[storage jsonArrayForKey:key error:nil] should] equal:value];
            });
            context(@"Null", ^{
                beforeEach(^{
                    [provider stub:@selector(objectForKey:error:) andReturn:nil];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonArrayForKey:key error:nil] should] beNil];
                });
            });
            context(@"Invalid string", ^{
                beforeEach(^{
                    [converter stub:@selector(stringForObject:) andReturn:@"Not a JSON"];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonArrayForKey:key error:nil] should] beNil];
                });
            });
            context(@"Invalid JSON object", ^{
                beforeEach(^{
                    [converter stub:@selector(stringForObject:) andReturn:@"{\"foo\":\"bar\"}"];
                });
                it(@"Should return nil", ^{
                    [[[storage jsonArrayForKey:key error:nil] should] beNil];
                });
            });
        });
        context(@"Set", ^{
            it(@"Should convert value", ^{
                [[converter should] receive:@selector(objectForString:) withArguments:@"[\"foo\",\"bar\"]"];
                [storage saveJSONArray:value forKey:key error:nil];
            });
            it(@"Should save to provider", ^{
                [[provider should] receive:@selector(saveObject:forKey:error:) withArguments:convertedValue, key, kw_any()];
                [storage saveJSONArray:value forKey:key error:nil];
            });
            it(@"Should return YES", ^{
                [[theValue([storage saveJSONArray:value forKey:key error:nil]) should] beYes];
            });
            context(@"Null", ^{
                it(@"Should remove in provider", ^{
                    [[provider should] receive:@selector(removeKey:error:) withArguments:key, kw_any()];
                    [storage saveJSONArray:nil forKey:key error:nil];
                });
                it(@"Should return YES", ^{
                    [[theValue([storage saveJSONArray:nil forKey:key error:nil]) should] beYes];
                });
            });
        });
    });
    
    it(@"Should conform to AMAKeyValueStoring", ^{
        [[storage should] conformToProtocol:@protocol(AMAKeyValueStoring)];
    });
});

SPEC_END

