
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAPermissionsController.h"
#import "AMAPermissionsConfiguration.h"
#import "AMAPermissionsExtractor.h"
#import "AMAPermissionsSerializer.h"
#import "AMATime.h"

SPEC_BEGIN(AMAPermissionsControllerTests)

describe(@"AMAPermissionsController", ^{
    
    AMAPermissionsController *__block permissionContoller = nil;
    AMAPermissionsConfiguration *__block configurationMock = nil;
    AMAPermissionsExtractor *__block extractorMock = nil;
    AMADateProviderMock *__block dateProviderMock = nil;
    
    NSString *const expectedJSON = @"{\"permission\":[]}";
    NSDate *const lastUpdateDate = [NSDate date];
    NSTimeInterval const interval = 3 * AMA_DAYS;
    
    NSArray<AMAPermissionKey> *const testPermissions = @[ @"permission1", @"permission2" ];
  
    beforeEach(^{
        configurationMock = [AMAPermissionsConfiguration nullMock];
        [configurationMock stub:@selector(lastUpdateDate) andReturn:lastUpdateDate];
        [configurationMock stub:@selector(collectingInterval) andReturn:theValue(interval)];
        [configurationMock stub:@selector(keys) andReturn:testPermissions];
    
        extractorMock = [AMAPermissionsExtractor nullMock];
        dateProviderMock = [[AMADateProviderMock alloc] init];
        
        permissionContoller = [[AMAPermissionsController alloc] initWithConfiguration:configurationMock
                                                                            extractor:extractorMock
                                                                         dateProvider:dateProviderMock];
    
        [AMAPermissionsSerializer stub:@selector(JSONStringForPermissions:) andReturn:expectedJSON];
    });
    
    context(@"Configuration allows", ^{
            
        beforeEach(^{
            [configurationMock stub:@selector(collectingEnabled) andReturn:theValue(YES)];
        });
    
        context(@"Update time passed", ^{

            beforeEach(^{
                [dateProviderMock freezeWithDate:[lastUpdateDate dateByAddingTimeInterval:interval]];
            });
           
            it(@"Should request all permissions in extractor", ^{
                KWCaptureSpy *spy = [extractorMock captureArgument:@selector(permissionsForKeys:) atIndex:0];
                [permissionContoller updateIfNeeded];
                [[spy.argument should] equal:testPermissions];
            });
            it(@"Should serialize permissions", ^{
                NSArray *permissions = @[ [KWMock mock], [KWMock mock] ];
                [extractorMock stub:@selector(permissionsForKeys:) andReturn:permissions];
                [[AMAPermissionsSerializer should] receive:@selector(JSONStringForPermissions:) withArguments:permissions];
                [permissionContoller updateIfNeeded];
            });
            it(@"Should return serialized JSON", ^{
                [[[permissionContoller updateIfNeeded] should] equal:expectedJSON];
            });
            it(@"Should update config with new update time", ^{
                [[configurationMock should] receive:@selector(setLastUpdateDate:)
                                      withArguments:dateProviderMock.currentDate];
                [permissionContoller updateIfNeeded];
            });
        });
        
        it(@"Should update if there is no last update date", ^{
            [configurationMock stub:@selector(lastUpdateDate) andReturn:nil];
            [[[permissionContoller updateIfNeeded] should] equal:expectedJSON];
        });
             
        context(@"Update time haven't passed", ^{

            beforeEach(^{
                [dateProviderMock freezeWithDate:[lastUpdateDate dateByAddingTimeInterval:interval - 1 * AMA_HOURS]];
            });
           
            it(@"Should not request permissions in extractor", ^{
                [[extractorMock shouldNot] receive:@selector(permissionsForKeys:)];
                [permissionContoller updateIfNeeded];
            });
            it(@"Should not serialize permissions", ^{
                [[AMAPermissionsSerializer shouldNot] receive:@selector(JSONStringForPermissions:)];
                [permissionContoller updateIfNeeded];
            });
            it(@"Should return nil", ^{
                [[[permissionContoller updateIfNeeded] should] beNil];
            });
            it(@"Should not update config with new update time", ^{
                [[configurationMock shouldNot] receive:@selector(setLastUpdateDate:)];
                [permissionContoller updateIfNeeded];
            });
        });
    });

    context(@"Config disallows", ^{
        
        beforeEach(^{
            [configurationMock stub:@selector(collectingEnabled) andReturn:theValue(NO)];
        });
    
        context(@"Update time passed", ^{

            beforeEach(^{
                [dateProviderMock freezeWithDate:[lastUpdateDate dateByAddingTimeInterval:interval]];
            });
           
            it(@"Should not request permissions in extractor", ^{
                [[extractorMock shouldNot] receive:@selector(permissionsForKeys:)];
                [permissionContoller updateIfNeeded];
            });
            it(@"Should not serialize permissions", ^{
                [[AMAPermissionsSerializer shouldNot] receive:@selector(JSONStringForPermissions:)];
                [permissionContoller updateIfNeeded];
            });
            it(@"Should return nil", ^{
                [[[permissionContoller updateIfNeeded] should] beNil];
            });
            it(@"Should not update config with new update time", ^{
                [[configurationMock shouldNot] receive:@selector(setLastUpdateDate:)];
                [permissionContoller updateIfNeeded];
            });
        });
    });
});

SPEC_END
