
#import <Kiwi/Kiwi.h>

#import "AMAPermission.h"
#import "AMAPermissionsSerializer.h"

SPEC_BEGIN(AMAPermissionsSerializerTests)

describe(@"AMAPermissionsSerializer", ^{
    
    context(@"Should serialize permissions", ^{
        
        __auto_type permissionJSON = ^NSString *(BOOL granted, NSString *grantType) {
            return [NSString stringWithFormat:@"{\"permissions\":["
                                                    "{"
                                                        "\"name\":\"CLAuthorizationStatusAuthorizedWhenInUse\","
                                                        "\"granted\":%@,"
                                                        "\"grant_type\":\"%@\""
                                                    "}"
                                               "]}", granted ? @"true" : @"false", grantType];
        };
        
        it(@"Serialize AMAPermissionGranted", ^{
            NSString *correctJSON = permissionJSON(YES, @"authorized");
            AMAPermission *permission = [[AMAPermission alloc] initWithName:@"CLAuthorizationStatusAuthorizedWhenInUse"
                                                                  grantType:AMAPermissionGrantTypeAuthorized];
            NSString *generatedJSON = [AMAPermissionsSerializer JSONStringForPermissions:@[permission]];
            [[generatedJSON should] equal:correctJSON];
        });
        
        it(@"Serialize AMAPermissionDenied", ^{
            NSString *correctJSON = permissionJSON(NO, @"denied");
            AMAPermission *permission = [[AMAPermission alloc] initWithName:@"CLAuthorizationStatusAuthorizedWhenInUse"
                                                                  grantType:AMAPermissionGrantTypeDenied];
            NSString *generatedJSON = [AMAPermissionsSerializer JSONStringForPermissions:@[permission]];
            [[generatedJSON should] equal:correctJSON];
        });
        
        it(@"Serialize AMAPermissionRestricted", ^{
            NSString *correctJSON = permissionJSON(NO, @"restricted");
            AMAPermission *permission = [[AMAPermission alloc] initWithName:@"CLAuthorizationStatusAuthorizedWhenInUse"
                                                                  grantType:AMAPermissionGrantTypeRestricted];
            NSString *generatedJSON = [AMAPermissionsSerializer JSONStringForPermissions:@[permission]];
            [[generatedJSON should] equal:correctJSON];
        });
        
        it(@"Serialize AMAPermissionUndefined", ^{
            NSString *correctJSON = permissionJSON(NO, @"not_determined");
            AMAPermission *permission = [[AMAPermission alloc] initWithName:@"CLAuthorizationStatusAuthorizedWhenInUse"
                                                                  grantType:AMAPermissionGrantTypeNotDetermined];
            NSString *generatedJSON = [AMAPermissionsSerializer JSONStringForPermissions:@[permission]];
            [[generatedJSON should] equal:correctJSON];
        });
    });
});

SPEC_END
