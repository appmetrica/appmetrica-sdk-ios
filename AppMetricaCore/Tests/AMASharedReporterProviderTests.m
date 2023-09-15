
#import <Kiwi/Kiwi.h>
#import "AMAAppMetrica.h"
#import "AMASharedReporterProvider.h"

SPEC_BEGIN(AMASharedReporterProviderTests)

describe(@"AMASharedReporterProvider", ^{
    NSString *apiKey = @"API KEY";
    AMASharedReporterProvider *__block provider = nil;
    beforeEach(^{
        [AMAAppMetrica stub:@selector(reporterForApiKey:)];
        provider = [[AMASharedReporterProvider alloc] initWithApiKey:apiKey];
    });

    it(@"Should pass apiKey to extended API", ^{
        [[AMAAppMetrica should] receive:@selector(reporterForApiKey:) withArguments:apiKey];
        [provider reporter];
    });

    it(@"Should return reporter", ^{
        id<AMAAppMetricaReporting> expectedReporter = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting )];
        [AMAAppMetrica stub:@selector(reporterForApiKey:) andReturn:expectedReporter];
        id reporter = [provider reporter];
        [[reporter should] equal:expectedReporter];
    });

});

SPEC_END
