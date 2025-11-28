
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppMetrica.h"
#import "AMASharedReporterProvider.h"

SPEC_BEGIN(AMASharedReporterProviderTests)

describe(@"AMASharedReporterProvider", ^{
    NSString *apiKey = @"API KEY";
    AMASharedReporterProvider *__block provider = nil;
    
    beforeEach(^{
        [AMAAppMetrica stub:@selector(reporterForAPIKey:)];
        provider = [[AMASharedReporterProvider alloc] initWithApiKey:apiKey];
    });
    afterEach(^{
        [AMAAppMetrica clearStubs];
    });

    it(@"Should pass apiKey to extended API", ^{
        [[AMAAppMetrica should] receive:@selector(reporterForAPIKey:) withArguments:apiKey];
        [provider reporter];
    });

    it(@"Should return reporter", ^{
        id<AMAAppMetricaReporting> expectedReporter = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting )];
        [AMAAppMetrica stub:@selector(reporterForAPIKey:) andReturn:expectedReporter];
        id reporter = [provider reporter];
        [[reporter should] equal:expectedReporter];
    });
    
    it(@"Should conform to AMAReporterProviding", ^{
        [[provider should] conformToProtocol:@protocol(AMAReporterProviding)];
    });
});

SPEC_END
