
#import "AMAReportRequestMock.h"
#import "AMAMetricaConfiguration.h"

@implementation AMAReportRequestMock

- (NSURLRequest *)buildURLRequest
{
    if (self.host != nil) {
        NSURL *URL = [NSURL URLWithString:self.host];
        return [NSURLRequest requestWithURL:URL];
    }
    else {
        return nil;
    }
}

@end
