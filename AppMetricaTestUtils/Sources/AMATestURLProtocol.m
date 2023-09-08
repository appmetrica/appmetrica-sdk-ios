
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMATestURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [[[request URL] scheme] isEqualToString:@"https"] || [[[request URL] scheme] isEqualToString:@"https"];
}

- (void)startLoading
{
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	return request;
}

- (void)stopLoading
{
}

@end
