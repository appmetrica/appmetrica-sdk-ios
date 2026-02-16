
#import "AMACrashEvent.h"
#import "AMACrashThreadInfo.h"

@interface AMACrashEvent ()

@property (nonatomic, copy, readwrite, nullable) AMAApplicationState *appState;
@property (nonatomic, copy, readwrite, nullable) NSDictionary<NSString *, NSString *> *errorEnvironment;
@property (nonatomic, copy, readwrite, nullable) NSDictionary<NSString *, NSString *> *appEnvironment;
@property (nonatomic, copy, readwrite, nullable) AMACrashInfo *info;
@property (nonatomic, copy, readwrite, nullable) AMACrashEventError *error;
@property (nonatomic, copy, readwrite, nullable) NSArray<AMACrashThreadInfo *> *threads;

@end

@implementation AMACrashEvent

- (AMACrashThreadInfo *)crashedThread
{
    NSUInteger index =
        [self.threads indexOfObjectPassingTest:^BOOL(AMACrashThreadInfo *obj, NSUInteger idx, BOOL *stop) {
            return obj.crashed;
        }];

    if (index != NSNotFound) {
        return self.threads[index];
    }
    return nil;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMAMutableCrashEvent *copy = [[AMAMutableCrashEvent alloc] init];
    copy.appState = self.appState;
    copy.errorEnvironment = self.errorEnvironment;
    copy.appEnvironment = self.appEnvironment;
    copy.info = self.info;
    copy.error = self.error;
    copy.threads = self.threads;
    return copy;
}

@end

@implementation AMAMutableCrashEvent

@dynamic appState;
@dynamic errorEnvironment;
@dynamic appEnvironment;
@dynamic info;
@dynamic error;
@dynamic threads;

- (id)copyWithZone:(NSZone *)zone
{
    AMACrashEvent *copy = [[AMACrashEvent alloc] init];
    copy.appState = self.appState;
    copy.errorEnvironment = self.errorEnvironment;
    copy.appEnvironment = self.appEnvironment;
    copy.info = self.info;
    copy.error = self.error;
    copy.threads = self.threads;
    return copy;
}

@end
