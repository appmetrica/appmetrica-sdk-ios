
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMAPermissionsExtractor.h"
#import "AMAPermission.h"
#import "AMAAdProvider.h"

SPEC_BEGIN(AMAPermissionsExtractorTests)

describe(@"AMAPermissionsExtractor", ^{
    
    AMAPermissionsExtractor *__block extractor = nil;

    beforeEach(^{
        extractor = [[AMAPermissionsExtractor alloc] init];
    });
    afterEach(^{
        [CLLocationManager clearStubs];
        [[AMAAdProvider sharedInstance] clearStubs];
    });

    AMAPermission *__block permission = nil;

    context(@"Location `When in use` permission", ^{

        beforeEach(^{
            [CLLocationManager stub:@selector(authorizationStatus)
                          andReturn:theValue(kCLAuthorizationStatusAuthorizedWhenInUse)];
        });
        
        context(@"AMAPermissionKeyLocationWhenInUse", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationWhenInUse ]].firstObject;
            });
            
            it(@"Should have `authorized` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeAuthorized)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationWhenInUse];
            });
            it(@"Should be granted", ^{
                [[theValue(permission.isGranted) should] beYes];
            });
        });

        context(@"AMAPermissionKeyLocationAlways", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationAlways ]].firstObject;
            });
            
            it(@"Should have `denied` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeDenied)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationAlways];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });
    });
    
    context(@"Location `Always` permission", ^{

        beforeEach(^{
            [CLLocationManager stub:@selector(authorizationStatus)
                          andReturn:theValue(kCLAuthorizationStatusAuthorizedAlways)];
        });
        
        context(@"AMAPermissionKeyLocationWhenInUse", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationWhenInUse ]].firstObject;
            });
            
            it(@"Should have `authorized` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeAuthorized)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationWhenInUse];
            });
            it(@"Should be granted", ^{
                [[theValue(permission.isGranted) should] beYes];
            });
        });

        context(@"AMAPermissionKeyLocationAlways", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationAlways ]].firstObject;
            });
            
            it(@"Should have `authorized` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeAuthorized)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationAlways];
            });
            it(@"Should be granted", ^{
                [[theValue(permission.isGranted) should] beYes];
            });
        });
    });

    context(@"Location `Denied` permission", ^{

        beforeEach(^{
            [CLLocationManager stub:@selector(authorizationStatus)
                          andReturn:theValue(kCLAuthorizationStatusDenied)];
        });
        
        context(@"AMAPermissionKeyLocationWhenInUse", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationWhenInUse ]].firstObject;
            });
            
            it(@"Should have `denied` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeDenied)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationWhenInUse];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });

        context(@"AMAPermissionKeyLocationAlways", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationAlways ]].firstObject;
            });
            
            it(@"Should have `denied` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeDenied)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationAlways];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });
    });

    context(@"Location `Restriced` permission", ^{

        beforeEach(^{
            [CLLocationManager stub:@selector(authorizationStatus)
                          andReturn:theValue(kCLAuthorizationStatusRestricted)];
        });
        
        context(@"AMAPermissionKeyLocationWhenInUse", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationWhenInUse ]].firstObject;
            });
            
            it(@"Should have `restriced` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeRestricted)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationWhenInUse];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });

        context(@"AMAPermissionKeyLocationAlways", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationAlways ]].firstObject;
            });
            
            it(@"Should have `denied` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeRestricted)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationAlways];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });
    });

    context(@"Location `Not determined` permission", ^{

        beforeEach(^{
            [CLLocationManager stub:@selector(authorizationStatus)
                          andReturn:theValue(kCLAuthorizationStatusNotDetermined)];
        });

        context(@"AMAPermissionKeyLocationWhenInUse", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationWhenInUse ]].firstObject;
            });
            
            it(@"Should have `not_determined` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeNotDetermined)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationWhenInUse];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });

        context(@"AMAPermissionKeyLocationAlways", ^{
            
            beforeEach(^{
                permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyLocationAlways ]].firstObject;
            });
            
            it(@"Should have `denied` grat type", ^{
                [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeNotDetermined)];
            });
            it(@"Should have requested name", ^{
                [[permission.name should] equal:kAMAPermissionKeyLocationAlways];
            });
            it(@"Should not be granted", ^{
                [[theValue(permission.isGranted) should] beNo];
            });
        });
    });

    context(@"ATTStatus", ^{
        if (@available(iOS 14.0, tvOS 14.0, *)) {
            context(@"Authorized", ^{
                beforeEach(^{
                    [[AMAAdProvider sharedInstance] stub:@selector(ATTStatus)
                                               andReturn:theValue(AMATrackingManagerAuthorizationStatusAuthorized)];
                    permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyATTStatus ]].firstObject;
                });
                it(@"Should have `authorized` type", ^{
                    [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeAuthorized)];
                });
                it(@"Should have requested name", ^{
                    [[permission.name should] equal:kAMAPermissionKeyATTStatus];
                });
                it(@"Should be granted", ^{
                    [[theValue(permission.isGranted) should] beYes];
                });
            });
            context(@"Denied", ^{
                beforeEach(^{
                    [[AMAAdProvider sharedInstance] stub:@selector(ATTStatus) andReturn:theValue(AMATrackingManagerAuthorizationStatusDenied)];
                    permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyATTStatus ]].firstObject;
                });
                it(@"Should have `denied` type", ^{
                    [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeDenied)];
                });
                it(@"Should have requested name", ^{
                    [[permission.name should] equal:kAMAPermissionKeyATTStatus];
                });
                it(@"Should not be granted", ^{
                    [[theValue(permission.isGranted) should] beNo];
                });
            });
            context(@"Restricted", ^{
                beforeEach(^{
                    [[AMAAdProvider sharedInstance] stub:@selector(ATTStatus)
                                               andReturn:theValue(AMATrackingManagerAuthorizationStatusRestricted)];
                    permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyATTStatus ]].firstObject;
                });
                it(@"Should have `restricted` type", ^{
                    [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeRestricted)];
                });
                it(@"Should have requested name", ^{
                    [[permission.name should] equal:kAMAPermissionKeyATTStatus];
                });
                it(@"Should not be granted", ^{
                    [[theValue(permission.isGranted) should] beNo];
                });
            });
            context(@"Not determined", ^{
                beforeEach(^{
                    [[AMAAdProvider sharedInstance] stub:@selector(ATTStatus)
                                               andReturn:theValue(AMATrackingManagerAuthorizationStatusNotDetermined)];
                    permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyATTStatus ]].firstObject;
                });
                it(@"Should have `ot determined` type", ^{
                    [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeNotDetermined)];
                });
                it(@"Should have requested name", ^{
                    [[permission.name should] equal:kAMAPermissionKeyATTStatus];
                });
                it(@"Should not be granted", ^{
                    [[theValue(permission.isGranted) should] beNo];
                });
            });
            context(@"Unknown", ^{
                beforeEach(^{
                    [[AMAAdProvider sharedInstance] stub:@selector(ATTStatus) andReturn:theValue(666)];
                    permission = [extractor permissionsForKeys:@[ kAMAPermissionKeyATTStatus ]].firstObject;
                });
                it(@"Should have `not determined` type", ^{
                    [[theValue(permission.grantType) should] equal:theValue(AMAPermissionGrantTypeNotDetermined)];
                });
                it(@"Should have requested name", ^{
                    [[permission.name should] equal:kAMAPermissionKeyATTStatus];
                });
                it(@"Should not be granted", ^{
                    [[theValue(permission.isGranted) should] beNo];
                });
            });
        }
    });
});

SPEC_END
