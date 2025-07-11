
#import <Kiwi/Kiwi.h>
#import "AMADataSendingRestrictionController.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMADataSendingRestrictionControllerTests)

describe(@"AMADataSendingRestrictionController", ^{

    NSString *const mainApiKey = @"MAIN";
    NSString *const firstApiKey = @"FIRST";
    NSString *const secondApiKey = @"SECOND";

    AMADataSendingRestrictionController *__block controller = nil;

    beforeEach(^{
        controller = [[AMADataSendingRestrictionController alloc] init];
    });

    context(@"Main key not activated", ^{
        beforeEach(^{
            [controller setMainApiKeyRestriction:AMADataSendingRestrictionNotActivated];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beYes];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
        context(@"First API key allowed", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:firstApiKey];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beYes];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
        context(@"First API key forbidden", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
    });

    context(@"Main key allowed", ^{
        beforeEach(^{
            [controller setMainApiKeyRestriction:AMADataSendingRestrictionAllowed];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beYes];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beYes];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
        });
        context(@"First API key allowed", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:firstApiKey];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beYes];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beYes];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
        });
        context(@"First API key forbidden", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beYes];
                });
                it(@"Should report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beYes];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beYes];
                });
            });
        });
    });

    context(@"Main key forbidden", ^{
        beforeEach(^{
            [controller setMainApiKey:mainApiKey];
            [controller setMainApiKeyRestriction:AMADataSendingRestrictionForbidden];
        });
        it(@"Should return actual restirction", ^{
            [[theValue([controller restrictionForApiKey:mainApiKey]) should] equal:theValue(AMADataSendingRestrictionForbidden)];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionNotActivated forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
        context(@"First API key allowed", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:firstApiKey];
            });
            it(@"Should return actual restirction", ^{
                [[theValue([controller restrictionForApiKey:firstApiKey]) should] equal:theValue(AMADataSendingRestrictionAllowed)];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionAllowed forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should return actual restirction", ^{
                    [[theValue([controller restrictionForApiKey:secondApiKey]) should] equal:theValue(AMADataSendingRestrictionForbidden)];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
        context(@"First API key forbidden", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMADataSendingRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should not report to main API key", ^{
                    [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
                });
                it(@"Should not report to SDK API key", ^{
                    [[theValue([controller shouldReportToApiKey:kAMAMetricaLibraryApiKey]) should] beNo];
                });
                it(@"Should not report to first API key", ^{
                    [[theValue([controller shouldReportToApiKey:firstApiKey]) should] beNo];
                });
                it(@"Should not report to second API key", ^{
                    [[theValue([controller shouldReportToApiKey:secondApiKey]) should] beNo];
                });
                it(@"Should not enable location sending", ^{
                    [[theValue([controller shouldEnableLocationSending]) should] beNo];
                });
            });
        });
    });
    
    context(@"Restriction storage", ^{
        it(@"Should save and retrieve main api key restriction", ^{
            controller = [[AMADataSendingRestrictionController alloc] init];
            
            [controller setMainApiKey:mainApiKey];
            [controller setMainApiKeyRestriction:AMADataSendingRestrictionForbidden];
            
            controller = [[AMADataSendingRestrictionController alloc] init];
            [[theValue([controller shouldReportToApiKey:mainApiKey]) should] beNo];
        });
    });

});

SPEC_END
