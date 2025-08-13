#import "AMAResolver.h"

@implementation AMAResolver

@synthesize userValue = _userValue;
@synthesize anonymousValue = _anonymousValue;
@synthesize isAnonymousConfigurationActivated = _isAnonymousConfigurationActivated;
@synthesize resultValue = _resultValue;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _resultValue  = [self defaultValue];
    }
    return self;
}

- (BOOL)defaultValue
{
    return YES;
}

- (void)updateWithValue:(BOOL)value;
{
    NSAssert(NO, @"Must be overriden in subclass");
}

- (BOOL)resolve
{
    BOOL result;
    if (self.userValue != nil) {
        result = self.userValue.boolValue;
    }
    else if (self.isAnonymousConfigurationActivated && self.anonymousValue) {
        result = self.anonymousValue.boolValue;
    }
    else {
        result = self.defaultValue;
    }
    return result;
}

- (void)triggerUpdate
{
    BOOL result = [self resolve];
    
    _resultValue = result;
    [self updateWithValue:result];
}

- (NSNumber *)userValue
{
    @synchronized (self) {
        return _userValue;
    }
}

- (void)setUserValue:(NSNumber *)userValue
{
    @synchronized (self) {
        _userValue = [userValue copy];
        [self triggerUpdate];
    }
}

- (NSNumber *)anonymousValue
{
    @synchronized (self) {
        return _anonymousValue;
    }
}

- (void)setAnonymousValue:(NSNumber *)anonymousValue
{
    @synchronized (self) {
        _anonymousValue = [anonymousValue copy];
        [self triggerUpdate];
    }
}

- (BOOL)resultValue
{
    @synchronized (self) {
        return _resultValue;
    }
}

- (void)setAnonymousConfigurationActivated:(BOOL)isAnonymousConfigurationActivated
{
    @synchronized (self) {
        _isAnonymousConfigurationActivated = isAnonymousConfigurationActivated;
        [self triggerUpdate];
    }
}

- (BOOL)isAnonymousConfigurationActivated
{
    @synchronized (self) {
        return _isAnonymousConfigurationActivated;
    }
}

- (void)updateBoolValue:(NSNumber *)value isAnonymous:(BOOL)isAnonymous
{
    if (isAnonymous) {
        self.anonymousValue = value;
    } else {
        self.userValue = value;
    }
}

@end
