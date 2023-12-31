
#import <Kiwi/Kiwi.h>
#import "AMACrashLogging.h"
#import "AMACrashErrorsFactory.h"

SPEC_BEGIN(AMACrashErrorsFactoryTests)

describe(@"AMACrashErrorsFactory", ^{
    
    context(@"Constructed errors", ^{
        
        NSError *__block error = nil;
        
        context(@"crashReportDecodingError", ^{
            beforeEach(^{
                error = [AMACrashErrorsFactory crashReportDecodingError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:@"io.appmetrica"];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(1001)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Crash report decoding failed";
                [[error.localizedDescription should] equal:description];
            });
        });
        
        context(@"crashReportRecrashError", ^{
            beforeEach(^{
                error = [AMACrashErrorsFactory crashReportRecrashError];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:kAMAAppMetricaInternalErrorDomain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(2000)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Recrash report was found in crash report";
                [[error.localizedDescription should] equal:description];
            });
        });
        
        context(@"crashUnsupportedReportVersionError", ^{
            
            static NSString *const kAMAExpectedVersion = @"11.22.333";
            
            beforeEach(^{
                error = [AMACrashErrorsFactory crashUnsupportedReportVersionError:kAMAExpectedVersion];
            });
            it(@"Should use correct domain", ^{
                [[error.domain should] equal:kAMAAppMetricaInternalErrorDomain];
            });
            it(@"Should use correct code", ^{
                [[theValue(error.code) should] equal:theValue(2002)];
            });
            it(@"Should use correct description", ^{
                NSString *description = @"Crash report version unsupported: <11.22.333>";
                [[error.localizedDescription should] equal:description];
            });
        });
        
    });
    
});

SPEC_END
