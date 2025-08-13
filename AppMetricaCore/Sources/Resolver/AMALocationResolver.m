#import "AMALocationResolver.h"
#import "AMALocationManager.h"

@implementation AMALocationResolver

- (instancetype)initWithLocationManager:(AMALocationManager *)locationManager
{
    self = [super init];
    if (self) {
        _locationManager = locationManager;
    }
    return self;
}

- (void)updateWithValue:(BOOL)value
{
    self.locationManager.trackLocationEnabled = value;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static AMALocationResolver *resolver;
    dispatch_once(&onceToken, ^{
        resolver = [[AMALocationResolver alloc] initWithLocationManager:[AMALocationManager sharedManager]];
    });
    return resolver;
}

@end
