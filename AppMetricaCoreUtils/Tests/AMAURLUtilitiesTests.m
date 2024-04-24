
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAURLUtilitiesTests)

describe(@"AMAURLUtilities", ^{

    context(@"URLWithBaseURLString:pathComponents:httpGetParameters:", ^{
        context(@"Invalid base URL", ^{
            it(@"Should return nil for nil base URL", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:nil
                                                       pathComponents:@[]
                                                    httpGetParameters:@{}];
                [[result should] beNil];
            });
            it(@"Should return nil for empty base URL", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:@""
                                                       pathComponents:@[]
                                                    httpGetParameters:@{}];
                [[result should] beNil];
            });
            it(@"Should return nil for invalid base URL", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:@"__not_an_url#^&"
                                                       pathComponents:@[]
                                                    httpGetParameters:@{}];
                [[result should] beNil];
            });
            it(@"Should assert empty base URL", ^{
                [[[AMAURLUtilities URLWithBaseURLString:@"" pathComponents:@[] httpGetParameters:@{}] should] beNil];
            });
        });

        context(@"Valid base URL", ^{
            NSString *__block baseURL = nil;

            beforeEach(^{
                baseURL = @"https://appmetrica.io";
            });

            it(@"Should return valid URL without additional parameters", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL pathComponents:@[] httpGetParameters:@{}];
                [[result should] equal:[NSURL URLWithString:baseURL]];
            });
            it(@"Should return valid URL with nil additional parameters", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL pathComponents:nil httpGetParameters:nil];
                [[result should] equal:[NSURL URLWithString:baseURL]];
            });
            it(@"Should return valid URL with custom path components", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[ @"path", @"components" ]
                                                    httpGetParameters:@{}];
                [[result.path should] equal:@"/path/components"];
            });
            it(@"Should return valid URL with custom get parameters", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[]
                                                    httpGetParameters:@{ @"foo": @"bar", @"bar": @"foo" }];
                NSArray *queryComponents = [result.query componentsSeparatedByString:@"&"];
                [[queryComponents should] containObjects:@"foo=bar", @"bar=foo", nil];
            });
            it(@"Should return valid URL with all parameters", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[ @"path", @"components" ]
                                                    httpGetParameters:@{ @"foo": @"bar" }];
                [[result should] equal:[NSURL URLWithString:[NSString stringWithFormat:@"%@/path/components?foo=bar", baseURL]]];
            });
            it(@"Should not add slash between query and host", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[]
                                                    httpGetParameters:@{ @"foo": @"bar" }];
                [[result should] equal:[NSURL URLWithString:[NSString stringWithFormat:@"%@?foo=bar", baseURL]]];
            });
            it(@"Should escape query parameters", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[]
                                                    httpGetParameters:@{ @"foo?&=": @"=&?bar" }];
                [[result should] equal:[NSURL URLWithString:[NSString stringWithFormat:@"%@?foo?%%26%%3D=%%3D%%26?bar", baseURL]]];
            });
            it(@"Should escape path", ^{
                NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                       pathComponents:@[ @"foo?&=", @"=&?bar" ]
                                                    httpGetParameters:@{}];
                [[result should] equal:[NSURL URLWithString:[NSString stringWithFormat:@"%@/foo%%3F&=/=&%%3Fbar", baseURL]]];
            });

            context(@"Base URL with path and query", ^{
                beforeEach(^{
                    baseURL = @"https://appmetrica.io/v1?key=value";
                });

                it(@"Should return valid URL without additional parameters", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[]
                                                        httpGetParameters:@{}];
                    [[result should] equal:[NSURL URLWithString:baseURL]];
                });
                it(@"Should return valid URL with nil additional parameters", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:nil
                                                        httpGetParameters:nil];
                    [[result should] equal:[NSURL URLWithString:baseURL]];
                });
                it(@"Should return valid URL with custom path components", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[ @"path", @"components" ]
                                                        httpGetParameters:@{}];
                    [[result.path should] equal:@"/v1/path/components"];
                });
                it(@"Should return valid URL with custom get parameters", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[]
                                                        httpGetParameters:@{ @"foo": @"bar", @"bar": @"foo" }];
                    NSArray *queryComponents = [result.query componentsSeparatedByString:@"&"];
                    [[queryComponents should] containObjects:@"key=value", @"foo=bar", @"bar=foo", nil];
                });
                it(@"Should return valid URL with all parameters", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[ @"path", @"components" ]
                                                        httpGetParameters:@{ @"foo": @"bar" }];
                    NSURL *expected =
                        [NSURL URLWithString:@"https://appmetrica.io/v1/path/components?key=value&foo=bar"];
                    [[result should] equal:expected];
                });
                it(@"Should escape query parameters", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[]
                                                        httpGetParameters:@{ @"foo?&=": @"=&?bar" }];
                    NSURL *expected =
                        [NSURL URLWithString:@"https://appmetrica.io/v1?key=value&foo?%26%3D=%3D%26?bar"];
                    [[result should] equal:expected];
                });
                it(@"Should escape path", ^{
                    NSURL *result = [AMAURLUtilities URLWithBaseURLString:baseURL
                                                           pathComponents:@[ @"foo?&=", @"=&?bar" ]
                                                        httpGetParameters:@{}];
                    NSURL *expected =
                        [NSURL URLWithString:@"https://appmetrica.io/v1/foo%3F&=/=&%3Fbar?key=value"];
                    [[result should] equal:expected];
                });
            });
        });
    });

    context(@"URLWithBaseURLString:pathComponents:httpGetParameters:", ^{
        it(@"Should proxy call to extended method", ^{
            NSString *baseURL = @"https://appmetrica.io";
            NSDictionary *parameters = @{ @"foo": @"bar" };
            [[AMAURLUtilities should] receive:@selector(URLWithBaseURLString:pathComponents:httpGetParameters:)
                                withArguments:baseURL, @[], parameters];
            [AMAURLUtilities URLWithBaseURLString:baseURL httpGetParameters:parameters];
        });
    });

    context(@"HTTPGetParametersForURL:", ^{
        it(@"Should return empty for nil URL", ^{
            NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:nil];
            [[parameters should] beEmpty];
        });
        it(@"Should return empty for URL without parameters", ^{
            NSURL *url = [NSURL URLWithString:@"https://appmetrica.io/"];
            NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:url];
            [[parameters should] beEmpty];
        });
        it(@"Should return valid parameters", ^{
            NSURL *url = [NSURL URLWithString:@"https://appmetrica.io?foo=bar&bar=foo"];
            NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:url];
            [[parameters should] equal:@{ @"foo": @"bar", @"bar": @"foo" }];
        });
        it(@"Should return unescaped parameters", ^{
            NSURL *url = [NSURL URLWithString:@"https://appmetrica.io?foo?%26%3D=%3D%26?bar"];
            NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:url];
            [[parameters should] equal:@{ @"foo?&=": @"=&?bar" }];
        });
        it(@"Should return last value for key", ^{
            NSURL *url = [NSURL URLWithString:@"https://appmetrica.io?foo=bar1&foo=bar2"];
            NSDictionary *parameters = [AMAURLUtilities HTTPGetParametersForURL:url];
            [[parameters should] equal:@{ @"foo": @"bar2" }];
        });
    });

});

SPEC_END

