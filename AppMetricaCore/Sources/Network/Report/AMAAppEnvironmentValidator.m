
#import "AMAAppEnvironmentValidator.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAInternalEventsReporter.h"
#import "AMAEnvironmentLimiter.h"

@interface AMAAppEnvironmentValidator ()

@property (nonatomic, strong, readonly) AMAInternalEventsReporter *reporter;

@end

@implementation AMAAppEnvironmentValidator

- (instancetype)init
{
    return [self initWithInternalReporter:[AMAAppMetrica sharedInternalEventsReporter]];
}

- (instancetype)initWithInternalReporter:(AMAInternalEventsReporter *)reporter
{
    self = [super init];
    if (self) {
        _reporter = reporter;
    }
    return self;
}

- (BOOL)validateAppEnvironmentKey:(id)object
{
    NSString *type = @"key";
    
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        if (string.length > kAMAEnvironmentKeyLengthLimit) {
            [self.reporter reportAppEnvironmentError:@{ @"limit_exceeded": string } type:type];
            return NO;
        }
    }
    return [self validateAppEnvironmentObject:object type:type];
}

- (BOOL)validateAppEnvironmentValue:(id)object
{
    NSString *type = @"value";
    
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        if (string.length > kAMAEnvironmentValueLengthLimit) {
            [self.reporter reportAppEnvironmentError:@{ @"limit_exceeded": string } type:type];
            return NO;
        }
    }
    return [self validateAppEnvironmentObject:object type:type];
}

- (BOOL)validateAppEnvironmentObject:(id)object type:(NSString *)type
{
    if (object == nil) {
        [self.reporter reportAppEnvironmentError:@{ @"error": @"null" } type:type];
        return NO;
    }
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        if ([string canBeConvertedToEncoding:NSUTF8StringEncoding] == NO) {
            [self.reporter reportAppEnvironmentError:@{ @"invalid_string": string } type:type];
            return NO;
        }
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        [self.reporter reportAppEnvironmentError:@ { @"invalid_dictionary": object } type:type];
        return NO;
    }
    else {
        [self.reporter reportAppEnvironmentError:@{ @"invalid_type": NSStringFromClass([object class]) } type:type];
        return NO;
    }
    return YES;
}

@end
