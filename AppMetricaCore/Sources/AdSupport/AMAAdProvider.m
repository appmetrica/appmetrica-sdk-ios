
#import "AMACore.h"
#import "AMAAdProvider.h"

@interface AMAAdProvider ()

@property (nonatomic, strong) id<AMAAdProviding> externalProvider;

@end

@implementation AMAAdProvider

@synthesize isEnabled = _isEnabled;

#pragma mark - Public -

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static AMAAdProvider *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[[self class] alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isEnabled = YES;
    }
    return self;
}

- (BOOL)isAdvertisingTrackingEnabled
{
    @synchronized (self) {
        if (self.isEnabled && self.externalProvider != nil) {
            return [self.externalProvider isAdvertisingTrackingEnabled];
        }
        else {
            return NO;
        }
    }
}

- (NSUUID *)advertisingIdentifier
{
    @synchronized (self) {
        if (self.isEnabled && self.externalProvider != nil) {
            return [self.externalProvider advertisingIdentifier];
        }
        else {
            return nil;
        }
    }
}

- (NSUInteger)ATTStatus
{
    @synchronized (self) {
        if (self.isEnabled && self.externalProvider != nil) {
            return [self.externalProvider ATTStatus];
        }
        else {
            return AMATrackingManagerAuthorizationStatusNotDetermined;
        }
    }
}

- (void)setEnabled:(BOOL)isEnabled
{
    @synchronized (self) {
        _isEnabled = isEnabled;
    }
}

- (void)setupAdProvider:(id<AMAAdProviding>)adProvider
{
    @synchronized (self) {
        self.externalProvider = adProvider;
    }
}

@end
