#import "AMAAdResolver.h"
#import "AMAAdProvider.h"

@interface AMAAdResolver ()

@property (nonatomic, copy, nullable) NSNumber *userValue;
@property (nonatomic, copy, nullable) NSNumber *anonymousActivationValue;

@end

@implementation AMAAdResolver

- (instancetype)initWithDestination:(AMAAdProvider *)destination
{
    self = [super init];
    if (self) {
        _destination = destination;
    }
    return self;
}

- (void)setAdProvider:(id<AMAAdProviding>)adProvider
{
    _adProvider = adProvider;
    [self resolveAdProvider];
}

- (void)setEnabledAdProvider:(BOOL)enableAdProvider
{
    self.userValue = @(enableAdProvider);
    [self resolveAdProvider];
}

- (void)setEnabledForAnonymousActivation:(BOOL)enabledAdProvider
{
    self.anonymousActivationValue = @(enabledAdProvider);
    [self resolveAdProvider];
}

- (void)resolveAdProvider
{
    if (self.adProvider == nil) {
        return;
    }
    
    if (self.userValue != nil) {
        [self updateAdProvider:[self.userValue boolValue]];
    } else if (self.anonymousActivationValue != nil) {
        [self updateAdProvider:[self.anonymousActivationValue boolValue]];
    } else {
        [self updateAdProvider:YES];
    }
}

- (void)updateAdProvider:(BOOL)isEnabled
{
    if (isEnabled) {
        [self.destination setupAdProvider:self.adProvider];
    } else {
        [self.destination setupAdProvider:nil];
    }
}


@end
