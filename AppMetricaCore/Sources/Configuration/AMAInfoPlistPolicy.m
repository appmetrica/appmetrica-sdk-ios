
#import "AMAInfoPlistPolicy.h"

@interface AMAInfoPlistPolicy ()
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, assign, readonly) BOOL defaultValue;
@property (nonatomic, strong, nullable) NSNumber *cachedValue;
@end

@implementation AMAInfoPlistPolicy

- (instancetype)initWithBundle:(NSBundle *)bundle
                           key:(NSString *)key
                  defaultValue:(BOOL)defaultValue
{
    self = [super init];
    if (self) {
        _bundle = bundle;
        _key = [key copy];
        _defaultValue = defaultValue;
        _cachedValue = nil;
    }
    return self;
}

- (BOOL)isEnabled
{
    if (_cachedValue == nil) {
        @synchronized (self) {
            if (_cachedValue == nil) {
                id value = [self.bundle objectForInfoDictionaryKey:self.key];
                _cachedValue = [value isKindOfClass:[NSNumber class]] ? value : @(self.defaultValue);
            }
        }
    }
    return [_cachedValue boolValue];
}

@end
