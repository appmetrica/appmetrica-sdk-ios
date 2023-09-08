
#import <Kiwi/Kiwi.h>
#import "AMAStartupPermission.h"

SPEC_BEGIN(AMAStartupPermissionTests)

describe(@"AMAStartupPermission", ^{
    
    context(@"Equality", ^{
        NSString *const permissionName1 = @"permission1";
        AMAStartupPermission * __block permission = nil;
        beforeEach(^{
            permission = [[AMAStartupPermission alloc] initWithName:permissionName1 enabled:YES];
        });
        it(@"Should consider objects equal if all fields are equal", ^{
            AMAStartupPermission *anotherPermission = [[AMAStartupPermission alloc] initWithName:permissionName1 enabled:YES];
            [[permission should] equal:anotherPermission];
        });
        it(@"Should consider objects not equal if names are not equal", ^{
            AMAStartupPermission *anotherPermission = [[AMAStartupPermission alloc] initWithName:@"permission2" enabled:YES];
            [[permission shouldNot] equal:anotherPermission];
        });
        it(@"Should consider objects not equal if enabled fields are not equal", ^{
            AMAStartupPermission *anotherPermission = [[AMAStartupPermission alloc] initWithName:permissionName1 enabled:NO];
            [[permission shouldNot] equal:anotherPermission];
        });
    });
});

SPEC_END

