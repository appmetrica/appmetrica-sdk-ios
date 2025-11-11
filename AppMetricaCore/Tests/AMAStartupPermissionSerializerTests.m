
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStartupPermissionSerializer.h"
#import "AMAStartupPermission.h"

static NSString *const kAMAStartupPermissionNameIdentifier = @"name";
static NSString *const kAMAStartupPermissionEnabledIdentifier = @"enabled";

SPEC_BEGIN(AMAStartupPermissionSerializerTests)

describe(@"AMAStartupPermissionSerializer", ^{
    
    NSString *const permissionName = @"permissionName";
    NSString *const serializedPermission = @"[{\"name\":\"permissionName\",\"enabled\":true}]";
    AMAStartupPermission *__block permission = nil;
    
    NSDictionary *(^permissionInDictionary)(NSString *permissionName, AMAStartupPermission *permission) = ^NSDictionary *(NSString *permissionName, AMAStartupPermission *permission) {
        return @{ permissionName : permission };
    };
    
    beforeEach(^{
        permission = [[AMAStartupPermission alloc] initWithName:permissionName enabled:YES];
    });
    
    context(@"Serialize", ^{
        
        it(@"Should serialize permissions into string", ^{
            NSDictionary *permissionDictionary = permissionInDictionary(permissionName, permission);
            NSString *JSONString = [AMAStartupPermissionSerializer JSONStringWithPermissions:permissionDictionary];
            [[JSONString should] equal:serializedPermission];
        });
    });
    
    context(@"Deserialize", ^{
        
        it(@"Should deserialize permissions from array", ^{
            NSArray *array = @[ @{ kAMAStartupPermissionNameIdentifier : permissionName,
                                   kAMAStartupPermissionEnabledIdentifier : @YES
                                   }
                                ];
            NSDictionary *deserilizedPermissions = [AMAStartupPermissionSerializer permissionsWithArray:array];
            [[deserilizedPermissions should] equal:permissionInDictionary(permissionName, permission) ];
        });
        
        it(@"Should deserialize permissions from string", ^{
            NSDictionary *deserilizedPermissions = [AMAStartupPermissionSerializer permissionsWithJSONString:serializedPermission];
            [[deserilizedPermissions should] equal:permissionInDictionary(permissionName, permission)];
        });

        context(@"Broken array", ^{
            NSArray *const brokenArray = @[ @"null" ];
            it(@"Should return empty array", ^{
                [[[AMAStartupPermissionSerializer permissionsWithArray:brokenArray] should] beEmpty];
            });
        });
    });
});

SPEC_END

