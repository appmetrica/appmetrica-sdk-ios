
#import "AMACore.h"
#import "AMAAppMetricaPreloadInfo.h"

@interface AMAAppMetricaPreloadInfo ()

@property (nonatomic, copy, readwrite) NSString *trackingID;
@property (atomic, strong, readwrite) NSDictionary *additionalInfo;

@end

@implementation AMAAppMetricaPreloadInfo

- (instancetype)initWithTrackingIdentifier:(NSString *)trackingID
{
    NSParameterAssert(trackingID.length);

    if (trackingID.length == 0) {
        AMALogError(@"Failed to create AMAAppMetricaPreloadInfo; tracking identifier is empty");
        return nil;
    }

    self = [super init];
    if (self) {
        _trackingID = [trackingID copy];
    }
    return self;
}

- (void)setAdditionalInfo:(NSString *)info forKey:(NSString *)key
{
    if (key.length == 0 || info.length == 0) {
        return;
    }

    @synchronized (self) {
        NSMutableDictionary *additionalInfo = [NSMutableDictionary dictionaryWithDictionary:self.additionalInfo];
        additionalInfo[key] = info;
        self.additionalInfo = additionalInfo;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    AMAAppMetricaPreloadInfo *copy =
            [(AMAAppMetricaPreloadInfo *)[[self class] alloc] initWithTrackingIdentifier:self.trackingID];
    copy.additionalInfo = self.additionalInfo;
    return copy;
}

#if AMA_ALLOW_DESCRIPTIONS
- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", super.description];
    [description appendFormat:@"self.trackingID=%@", self.trackingID];
    [description appendFormat:@", self.additionalInfo=%@", self.additionalInfo];
    [description appendString:@">"];
    return description;
}
#endif

@end
