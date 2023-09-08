
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAUserDefaultsMock ()

@property (nonatomic, assign, readwrite) BOOL synchronized;

@end

@implementation AMAUserDefaultsMock

- (instancetype)init
{
    return [self initWithSuiteName:nil];
}

- (instancetype)initWithSuiteName:(NSString *)suitename
{
    self = [super init];
    if (self != nil) {
        _store = [NSMutableDictionary dictionary];
        _suitename = suitename;
    }
    return self;
}

- (id)objectForKey:(NSString *)defaultName
{
    return self.store[defaultName];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
    if (value == nil || [value isKindOfClass:[NSNull class]]) {
        [self.store removeObjectForKey:defaultName];
    }
    else {
        self.store[defaultName] = value;
    }
    self.synchronized = NO;
}

- (NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)defaultName;
{
    return self.store[defaultName];
}

- (void)synchronize
{
    self.synchronized = YES;
}

@end
