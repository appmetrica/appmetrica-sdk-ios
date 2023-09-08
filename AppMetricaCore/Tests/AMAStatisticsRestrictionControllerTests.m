
#import <Kiwi/Kiwi.h>
#import "AMAStatisticsRestrictionController.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMAStatisticsRestrictionControllerTests)

describe(@"AMAStatisticsRestrictionController", ^{

    NSString *const mainApiKey = @"MAIN";
    NSString *const firstApiKey = @"FIRST";
    NSString *const secondApiKey = @"SECOND";

    AMAStatisticsRestrictionController *__block controller = nil;

    beforeEach(^{
        controller = [[AMAStatisticsRestrictionController alloc] init];
    });

    context(@"Main key not activated", ^{
        beforeEach(^{
            [controller setMainApiKeyRestriction:AMAStatisticsRestrictionNotActivated];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:firstApiKey];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
            [controller setMainApiKeyRestriction:AMAStatisticsRestrictionAllowed];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:firstApiKey];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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
            [controller setMainApiKeyRestriction:AMAStatisticsRestrictionForbidden];
        });
        it(@"Should return actual restirction", ^{
            [[theValue([controller restrictionForApiKey:mainApiKey]) should] equal:theValue(AMAStatisticsRestrictionForbidden)];
        });
        context(@"First API key not activated", ^{
            beforeEach(^{
                [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:firstApiKey];
            });
            context(@"Second API key not activated", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionNotActivated forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:firstApiKey];
            });
            it(@"Should return actual restirction", ^{
                [[theValue([controller restrictionForApiKey:firstApiKey]) should] equal:theValue(AMAStatisticsRestrictionAllowed)];
            });
            context(@"Second API key allowed", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionAllowed forApiKey:secondApiKey];
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
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
                });
                it(@"Should return actual restirction", ^{
                    [[theValue([controller restrictionForApiKey:secondApiKey]) should] equal:theValue(AMAStatisticsRestrictionForbidden)];
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
                [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:firstApiKey];
            });
            context(@"Second API key forbidden", ^{
                beforeEach(^{
                    [controller setReporterRestriction:AMAStatisticsRestrictionForbidden forApiKey:secondApiKey];
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

});

SPEC_END
