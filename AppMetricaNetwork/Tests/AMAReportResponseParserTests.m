
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

SPEC_BEGIN(AMAReportResponseParserTests)

describe(@"AMAReportResponseParser", ^{

    AMAReportResponseParser *__block parser = nil;

    beforeEach(^{
        parser = [[AMAReportResponseParser alloc] init];
    });

    it(@"Should return nil for nil data", ^{
        AMAReportResponse *response = [parser responseForData:nil];
        [[response should] beNil];
    });

    it(@"Should return nil for empty data", ^{
        AMAReportResponse *response = [parser responseForData:[NSData data]];
        [[response should] beNil];
    });

    it(@"Should return nil for bad data", ^{
        NSData *badData = [@"BAD_DATA" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[response should] beNil];
    });

    it(@"Should return nil for JSON array in data", ^{
        NSData *badData = [@"[\"something\"]" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[response should] beNil];
    });

    it(@"Should return nil for JSON object without status key in data", ^{
        NSData *badData = [@"{\"other_kay\":\"accepted\"}" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[response should] beNil];
    });

    it(@"Should return non-nil response for JSON object with status key in data", ^{
        NSData *badData = [@"{\"status\":\"other_value\"}" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[response should] beNonNil];
    });

    it(@"Should return response with unknown status for JSON object with unknown status in data", ^{
        NSData *badData = [@"{\"status\":\"other_value\"}" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[theValue(response.status) should] equal:theValue(AMAReportResponseStatusUnknown)];
    });

    it(@"Should return response with accepted status for valid JSON in data", ^{
        NSData *badData = [@"{\"status\":\"accepted\"}" dataUsingEncoding:NSUTF8StringEncoding];
        AMAReportResponse *response = [parser responseForData:badData];
        [[theValue(response.status) should] equal:theValue(AMAReportResponseStatusAccepted)];
    });
    
    context(@"Validator", ^{
        it(@"Should return NO for nil data", ^{
            [[theValue([parser isResponseValidWithData:nil]) should] beNo];
        });

        it(@"Should return NO for bad data", ^{
            NSData *badData = [@"BAD_DATA" dataUsingEncoding:NSUTF8StringEncoding];
            [[theValue([parser isResponseValidWithData:badData]) should] beNo];
        });

        it(@"Should return NO for JSON object without status key in data", ^{
            NSData *badData = [@"{\"other_kay\":\"accepted\"}" dataUsingEncoding:NSUTF8StringEncoding];
            [[theValue([parser isResponseValidWithData:badData]) should] beNo];
        });

        it(@"Should return NO for JSON object with unknown status in data", ^{
            NSData *badData = [@"{\"status\":\"other_value\"}" dataUsingEncoding:NSUTF8StringEncoding];
            [[theValue([parser isResponseValidWithData:badData]) should] beNo];
        });

        it(@"Should return YES for valid JSON in data", ^{
            NSData *data = [@"{\"status\":\"accepted\"}" dataUsingEncoding:NSUTF8StringEncoding];
            [[theValue([parser isResponseValidWithData:data]) should] beYes];
        });
    });

});

SPEC_END
