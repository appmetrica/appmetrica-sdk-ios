
#import <Kiwi/Kiwi.h>
#import "AMAReporter.h"
#import "AMAAppOpenWatcher.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMADeepLinkController.h"

@interface AMAAppOpenWatcher ()

- (void)didFinishLaunching:(NSNotification *)notification;

@end

SPEC_BEGIN(AMAAppOpenWatcherTests)

describe(@"AMAAppOpenWatcher", ^{

    AMADeepLinkController *__block deeplinkController = nil;
    AMAAppOpenWatcher *__block appOpenWatcher = nil;
    NSNotificationCenter *__block notificationCenter = nil;
    AMAStartupParametersConfiguration *__block startup = nil;

    beforeEach(^{
        notificationCenter = [NSNotificationCenter nullMock];
        deeplinkController = [AMADeepLinkController nullMock];
        startup = [AMAStartupParametersConfiguration nullMock];
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        [AMAMetricaConfiguration.sharedInstance stub:@selector(startup) andReturn:startup];
    });

    context(@"Start watching", ^{
        it(@"Should start watching", ^{
            appOpenWatcher = [[AMAAppOpenWatcher alloc] initWithNotificationCenter:notificationCenter];
            [[notificationCenter should] receive:@selector(addObserver:selector:name:object:)
                                   withArguments:appOpenWatcher, kw_any(),
                                                 UIApplicationDidFinishLaunchingNotification, nil];
            [appOpenWatcher startWatchingWithDeeplinkController:deeplinkController];
        });
    });

    context(@"DidFinishLaunching", ^{

        NSNotification *__block notification = nil;

        beforeEach(^{
            notification = [NSNotification nullMock];
            appOpenWatcher = [[AMAAppOpenWatcher alloc] initWithNotificationCenter:notificationCenter];
            [appOpenWatcher startWatchingWithDeeplinkController:deeplinkController];
        });

        it (@"Null notification", ^{
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:nil];
        });
        it (@"No user info", ^{
            [notification stub:@selector(userInfo) andReturn:nil];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Empty user info", ^{
            [notification stub:@selector(userInfo) andReturn:@{}];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Empty userActivity dictionary", ^{
            NSDictionary *userInfo = @{ UIApplicationLaunchOptionsUserActivityDictionaryKey : @{} };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Null webpage url", ^{
            NSUserActivity *userActivity = [NSUserActivity nullMock];
            [userActivity stub:@selector(webpageURL) andReturn:nil];
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"UIApplicationLaunchOptionsUserActivityKey" : userActivity
                }
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"User activity is not NSUserActivity", ^{
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"UIApplicationLaunchOptionsUserActivityKey" : @"string"
                }
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:nil, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"NSUserActivity has strange key", ^{
            NSString *universalLink = @"https://28620.redirect.appmetrica.com/path?"
                                      "appmetrica_tracking_id=747492033211469825";
            NSURL *url = [[NSURL alloc] initWithString:universalLink];
            NSUserActivity *userActivity = [NSUserActivity nullMock];
            [userActivity stub:@selector(webpageURL) andReturn:url];
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"not_documented_key" : userActivity
                }
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:)
                                   withArguments:url, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"2 NSUserActivities", ^{
            NSString *universalLink = @"https://28620.redirect.appmetrica.com/path?"
                                      "appmetrica_tracking_id=747492033211469825";
            NSURL *url = [[NSURL alloc] initWithString:universalLink];
            NSUserActivity *userActivity = [NSUserActivity nullMock];
            [userActivity stub:@selector(webpageURL) andReturn:url];
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"not_documented_key1" : userActivity,
                    @"not_documented_key2" : userActivity
                }
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:)
                                   withArguments:url, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Has universal link", ^{
            NSString *universalLink = @"https://28620.redirect.appmetrica.com/path?"
                                      "appmetrica_tracking_id=747492033211469825";
            NSURL *url = [[NSURL alloc] initWithString:universalLink];
            NSUserActivity *userActivity = [NSUserActivity nullMock];
            [userActivity stub:@selector(webpageURL) andReturn:url];
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"UIApplicationLaunchOptionsUserActivityKey" : userActivity
                }
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:)
                                   withArguments:url, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Has deeplink", ^{
            NSString *deeplink = @"appmetricasample://path?a=b";
            NSURL *url = [[NSURL alloc] initWithString:deeplink];
            NSDictionary *userInfo = @{ UIApplicationLaunchOptionsURLKey : url };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:)
                                   withArguments:url, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
        it (@"Has both deeplink and universal link", ^{
            NSString *deeplink = @"appmetricasample://path?a=b";
            NSString *universalLink = @"https://28620.redirect.appmetrica.com/path?"
                                      "appmetrica_tracking_id=747492033211469825";
            NSURL *deeplinkURL = [[NSURL alloc] initWithString:deeplink];
            NSUserActivity *userActivity = [NSUserActivity nullMock];
            [userActivity stub:@selector(webpageURL) andReturn:[[NSURL alloc] initWithString:universalLink]];
            NSDictionary *userInfo = @{
                UIApplicationLaunchOptionsUserActivityDictionaryKey : @{
                    @"UIApplicationLaunchOptionsUserActivityKey" : userActivity
                },
                UIApplicationLaunchOptionsURLKey : deeplinkURL
            };
            [notification stub:@selector(userInfo) andReturn:userInfo];
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:)
                                   withArguments:deeplinkURL, @"open", theValue(YES)];
            [appOpenWatcher didFinishLaunching:notification];
        });
    });
});


SPEC_END
