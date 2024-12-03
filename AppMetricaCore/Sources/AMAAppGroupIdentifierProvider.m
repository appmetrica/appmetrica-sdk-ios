
#import "AMAAppGroupIdentifierProvider.h"
#import "AMACore.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

NSString *const AMAInfoPlistAppGroupIdentifierKey = @"AMAApplicationGroupIdentifier";

@interface AMAAppGroupIdentifierProvider ()

@property (nonatomic, strong, nonnull, readonly) NSBundle *bundle;

@end

@implementation AMAAppGroupIdentifierProvider

@synthesize appGroupIdentifier = _appGroupIdentifier;

- (instancetype)init
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [self initWithBundle:bundle.applicationBundle ?: bundle];
}

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    self = [super init];
    if (self) {
        _bundle = bundle;
    }
    return self;
}


- (NSString *)appGroupIdentifier
{
    if (_appGroupIdentifier == nil) {
        @synchronized (self) {
            if (_appGroupIdentifier == nil) {
                id value = [self.bundle objectForInfoDictionaryKey:AMAInfoPlistAppGroupIdentifierKey];
                if ([value isKindOfClass:[NSString class]]) {
                    AMALogInfo(@"Read AMAApplicationGroupIdentifier=%@", value);
                    _appGroupIdentifier = value;
                }
            }
        }
    }
    
    return _appGroupIdentifier;
}

@end
