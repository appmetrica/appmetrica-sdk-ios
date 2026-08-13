#import "AMAModulesStatusReportState.h"

static NSString *const kAMAModulesStatusReportStateLastSentKey = @"last_sent";
static NSString *const kAMAModulesStatusReportStateModulesKey = @"modules";

@implementation AMAModulesStatusReportState

- (instancetype)initWithLastSentDate:(NSDate *)lastSentDate
                      moduleStatuses:(NSDictionary<NSString *, NSNumber *> *)moduleStatuses
{
    self = [super init];
    if (self != nil) {
        _lastSentDate = [lastSentDate copy];
        _moduleStatuses = [moduleStatuses copy];
    }
    return self;
}

#pragma mark - AMAJSONSerializable

- (NSDictionary *)JSON
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (self.lastSentDate != nil) {
        json[kAMAModulesStatusReportStateLastSentKey] = @([self.lastSentDate timeIntervalSince1970]);
    }
    if (self.moduleStatuses != nil) {
        json[kAMAModulesStatusReportStateModulesKey] = [self.moduleStatuses copy];
    }
    return [json copy];
}

- (instancetype)initWithJSON:(NSDictionary *)json
{
    if ([json isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }

    NSDate *lastSentDate = nil;
    id rawLastSent = json[kAMAModulesStatusReportStateLastSentKey];
    if ([rawLastSent isKindOfClass:[NSNumber class]]) {
        lastSentDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)rawLastSent doubleValue]];
    }

    NSDictionary<NSString *, NSNumber *> *moduleStatuses = nil;
    id rawModules = json[kAMAModulesStatusReportStateModulesKey];
    if ([rawModules isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary<NSString *, NSNumber *> *filtered = [NSMutableDictionary dictionary];
        [(NSDictionary *)rawModules enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSNumber class]]) {
                filtered[key] = value;
            }
        }];
        moduleStatuses = [filtered copy];
    }

    return [self initWithLastSentDate:lastSentDate moduleStatuses:moduleStatuses];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[AMAModulesStatusReportState allocWithZone:zone] initWithLastSentDate:self.lastSentDate
                                                                    moduleStatuses:self.moduleStatuses];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[AMAModulesStatusReportState class]] == NO) {
        return NO;
    }
    AMAModulesStatusReportState *other = (AMAModulesStatusReportState *)object;
    BOOL lastSentEqual = (self.lastSentDate == other.lastSentDate)
        || [self.lastSentDate isEqualToDate:other.lastSentDate];
    BOOL modulesEqual = (self.moduleStatuses == other.moduleStatuses)
        || [self.moduleStatuses isEqualToDictionary:other.moduleStatuses];
    return lastSentEqual && modulesEqual;
}

- (NSUInteger)hash
{
    return [self.lastSentDate hash] ^ [self.moduleStatuses hash];
}

@end
