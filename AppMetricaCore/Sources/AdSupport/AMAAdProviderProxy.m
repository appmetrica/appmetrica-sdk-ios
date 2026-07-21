
#import "AMACore.h"
#import "AMAAdProviderProxy.h"

@interface AMAAdProviderProxy ()

@property (nonatomic, strong, nullable) id<AMAAdProviding> backingProvider;

@end

@implementation AMAAdProviderProxy

@synthesize enabled = _enabled;

#pragma mark - Public -

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static AMAAdProviderProxy *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[[self class] alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enabled = YES;
    }
    return self;
}

- (BOOL)isAdvertisingTrackingEnabled
{
    @synchronized (self) {
        if (self.enabled && self.backingProvider != nil) {
            return [self.backingProvider isAdvertisingTrackingEnabled];
        }
        else {
            return NO;
        }
    }
}

- (NSUUID *)advertisingIdentifier
{
    @synchronized (self) {
        if (self.enabled && self.backingProvider != nil) {
            return [self.backingProvider advertisingIdentifier];
        }
        else {
            return nil;
        }
    }
}

- (AMATrackingManagerAuthorizationStatus)ATTStatus API_AVAILABLE(ios(14.0), tvos(14.0))
{
    @synchronized (self) {
        if (self.enabled && self.backingProvider != nil) {
            return [self.backingProvider ATTStatus];
        }
        else {
            return AMATrackingManagerAuthorizationStatusNotDetermined;
        }
    }
}

- (void)setEnabled:(BOOL)enabled
{
    @synchronized (self) {
        _enabled = enabled;
    }
}

- (void)setBackingProvider:(id<AMAAdProviding>)backingProvider
{
    @synchronized (self) {
        _backingProvider = backingProvider;
    }
}

@end
