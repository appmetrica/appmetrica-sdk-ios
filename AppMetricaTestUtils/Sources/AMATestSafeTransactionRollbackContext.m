
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString * const param1Key = @"test_rollback_param1";
static NSString * const param2Key = @"tets_rollback_param2";

@implementation AMATestSafeTransactionRollbackContext

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _param1 = @"damn";
        _param2 = @"it";
    }

    return self;
}

- (NSUInteger)hash
{
    return [self.param1 hash] + [self.param2 hash];
}

- (BOOL)isEqual:(AMATestSafeTransactionRollbackContext *)object
{
    BOOL equal = NO;

    if (self == object) {
        equal = YES;
    }

    else if ([object isKindOfClass:[self class]]) {
        equal = [self.param1 isEqual:object.param1] && [self.param2 isEqual:object.param2];
    }

    return equal;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil) {
        _param1 = [aDecoder decodeObjectForKey:param1Key];
        _param2 = [aDecoder decodeObjectForKey:param2Key];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.param1 forKey:param1Key];
    [aCoder encodeObject:self.param2 forKey:param2Key];
}

@end
