
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

static NSString *const kAMABuildUIDDateKey = @"date";

@interface AMABuildUID ()

@property (nonatomic, copy, readonly) NSDate *buildDate;

@end

@implementation AMABuildUID

- (instancetype)initWithString:(NSString *)buildUIDString
{
    NSDate *buildUIDDate = nil;
    if (buildUIDString != nil) {
        NSTimeInterval timeIntervalSince1970 = (NSUInteger)[buildUIDString integerValue];
        buildUIDDate = [NSDate dateWithTimeIntervalSince1970:timeIntervalSince1970];
    }
    return [self initWithDate:buildUIDDate];
}

- (instancetype)initWithDate:(NSDate *)buildUIDDate
{
    if (buildUIDDate == nil) {
        return nil;
    }

    self = [super init];
    if (self != nil) {
        _buildDate = [buildUIDDate copy];
    }
    return self;
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)[self.buildDate timeIntervalSince1970]];
}

+ (instancetype)buildUID
{
    NSDate *buildDate = [[self class] buildDate];
    return [[AMABuildUID alloc] initWithDate:buildDate];
}

+ (NSDate *)buildDate
{
    NSDate *buildDate = nil;

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *executablePath = [[mainBundle executablePath] stringByResolvingSymlinksInPath];
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:executablePath
                                                                                    error:&error];
    if (error == nil) {
        buildDate = [fileAttributes fileModificationDate];
    }

    if (buildDate == nil) {
        buildDate = [[self class] libraryCompilationDate];
    }

    return buildDate;
}

+ (NSDate *)libraryCompilationDate
{
    NSDate *libraryCompilationDate = nil;
#ifdef __DATE__
    NSString *compileDateString = [NSString stringWithUTF8String:__DATE__];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM d yyyy";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    libraryCompilationDate = [dateFormatter dateFromString:compileDateString];
#else
    libraryCompilationDate = [NSDate dateWithTimeIntervalSince1970:0];
#endif
    return libraryCompilationDate;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSDate *date = [aDecoder decodeObjectOfClass:[NSDate class] forKey:kAMABuildUIDDateKey];
    return [self initWithDate:date];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.buildDate forKey:kAMABuildUIDDateKey];
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return [self.buildDate hash];
}

- (BOOL)isEqual:(id)object
{
    AMABuildUID *other = object;
    BOOL isEqual = [other isKindOfClass:[self class]];
    isEqual = isEqual && (other.buildDate == self.buildDate || [other.buildDate isEqualToDate:self.buildDate]);
    return isEqual;
}

- (NSComparisonResult)compare:(AMABuildUID *)other
{
    return [self.buildDate compare:other.buildDate];
}

#if AMA_ALLOW_DESCRIPTIONS
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@:%@", [super description], self.stringValue];
}
#endif

@end
