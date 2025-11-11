
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMADeviceDescription.h"
#import "AMAAppIdentifierProvider.h"
#import "AMAJailbreakCheck.h"

SPEC_BEGIN(AMADeviceDescriptionTests)

describe(@"AMADeviceDescription", ^{
    
    context(@"Application", ^{
        it(@"Should return appIdentifierPrefix", ^{
            NSString *prefix = @"prefix";
            [AMAAppIdentifierProvider stub:@selector(appIdentifierPrefix) andReturn:prefix];
            
            [[[AMADeviceDescription appIdentifierPrefix] should] equal:prefix];
        });
        
        context(@"Jailbreak", ^{
            it(@"Should return device root status", ^{
                NSUInteger rand = arc4random_uniform(2) + 1;
                if (rand == 1) {
                    [AMAJailbreakCheck stub:@selector(jailbroken) andReturn:theValue(AMA_KFJailbroken)];
                    
                    [[theValue([AMADeviceDescription isDeviceRooted]) should] beYes];
                }
                else {
                    NSArray *jailChecks = @[
                        @(AMA_KFOpenURL),
                        @(AMA_KFCydia),
                        @(AMA_KFIFC),
                        @(AMA_KFPlist),
                        @(AMA_KFProcessesCydia),
                        @(AMA_KFProcessesOtherCydia),
                        @(AMA_KFProcessesOtherOCydia),
                        @(AMA_KFFSTab),
                        @(AMA_KFSystem),
                        @(AMA_KFSymbolic),
                        @(AMA_KFFileExists),
                    ];
                    NSUInteger rand = arc4random_uniform((uint32_t)[jailChecks count]);
                    NSUInteger value = [jailChecks objectAtIndex:rand];
                    
                    [AMAJailbreakCheck stub:@selector(jailbroken) andReturn:theValue(value)];
                    
                    [[theValue([AMADeviceDescription isDeviceRooted]) should] beNo];
                }
            });
        });
        
        it(@"Should return true if current device contains device model", ^{
            NSString *deviceModel = @"AC-130";
            [[UIDevice currentDevice] stub:@selector(model) andReturn:[NSString stringWithFormat:@"%@H", deviceModel]];
            
            [[theValue([AMADeviceDescription isDeviceModelOfType:deviceModel]) should] beYes];
        });
        
        it(@"Should return UIScreen width", ^{
            CGRect bounds = [[UIScreen mainScreen] bounds];
            
            [[[AMADeviceDescription screenWidth] should] equal:[NSString stringWithFormat:@"%.0f",
                                                                CGRectGetWidth(bounds)]];
        });
        
        it(@"Should return UIScreen height", ^{
            CGRect bounds = [[UIScreen mainScreen] bounds];
            
            [[[AMADeviceDescription screenHeight] should] equal:[NSString stringWithFormat:@"%.0f",
                                                                 CGRectGetHeight(bounds)]];
        });
        
        it(@"Should return scalefactor", ^{
            [[UIScreen mainScreen] stub:@selector(scale) andReturn:theValue(30)];
            
            [[[AMADeviceDescription scalefactor] should] equal:@"30.00"];
        });
        
        it(@"Should return manufacturer", ^{
            [[[AMADeviceDescription manufacturer] should] equal:@"Apple"];
        });
        
        it(@"Should return OSVersion", ^{
            NSString *version = @"5.7";
            [[UIDevice currentDevice] stub:@selector(systemVersion) andReturn:version];
            
            [[[AMADeviceDescription OSVersion] should] equal:version];
        });
        
        it(@"Should return ipad if current idiom is ipad", ^{
            [[UIDevice currentDevice] stub:@selector(userInterfaceIdiom)
                                 andReturn:theValue(UIUserInterfaceIdiomPad)];
            
            [[[AMADeviceDescription appPlatform] should] equal:@"ipad"];
        });
        
        it(@"Should return iphone if current idiom is not ipad", ^{
            [[UIDevice currentDevice] stub:@selector(userInterfaceIdiom)
                                 andReturn:theValue(UIUserInterfaceIdiomTV)];
            
            [[[AMADeviceDescription appPlatform] should] equal:@"iphone"];
        });
    });
});

SPEC_END
