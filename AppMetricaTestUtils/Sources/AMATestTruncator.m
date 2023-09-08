
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMATestTruncator ()

@property (nonatomic, assign) id defaultTruncationResult;
@property (nonatomic, assign) NSNumber *defaultBytesTruncated;
@property (nonatomic, copy, readonly) NSMutableDictionary *truncationResults;
@property (nonatomic, copy, readonly) NSMutableDictionary *bytesTruncated;

@end

@implementation AMATestTruncator

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _truncationResults = [NSMutableDictionary dictionary];
        _bytesTruncated = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)enableTruncationWithResult:(id)truncationResult bytesTruncated:(NSUInteger)bytesTruncated
{
    [self enableTruncationWithResult:truncationResult
                         forArgument:nil
                      bytesTruncated:bytesTruncated];
}

- (void)enableTruncationWithResult:(id)truncationResult forArgument:(id)argument bytesTruncated:(NSUInteger)bytesTruncated
{
    if (argument != nil) {
        self.truncationResults[argument] = truncationResult;
        self.bytesTruncated[argument] = @(bytesTruncated);
    } else {
        self.defaultTruncationResult = truncationResult;
        self.defaultBytesTruncated = @(bytesTruncated);
    }
}

- (id)truncatedObject:(id)object onTruncation:(AMATruncationBlock)onTruncation
{
    id result = object;
    if (result != nil) {
        result = self.truncationResults[object] ?: self.defaultTruncationResult ?: object;
        if (onTruncation != nil) {
            NSNumber *bytesTruncatedForArgument = self.bytesTruncated[object];
            if (bytesTruncatedForArgument == nil) {
                if (self.defaultBytesTruncated != nil) {
                    onTruncation(self.defaultBytesTruncated.unsignedIntegerValue);
                }
            } else {
                onTruncation(bytesTruncatedForArgument.unsignedIntegerValue);
            }
        }
    }
    return result;
}

- (NSData *)truncatedData:(NSData *)data onTruncation:(AMATruncationBlock)onTruncation
{
    return [self truncatedObject:data onTruncation:onTruncation];
}

- (NSString *)truncatedString:(NSString *)string onTruncation:(AMATruncationBlock)onTruncation
{
    return [self truncatedObject:string onTruncation:onTruncation];
}

- (NSDictionary *)truncatedDictionary:(NSDictionary *)dictionary onTruncation:(AMATruncationBlock)onTruncation
{
    return [self truncatedObject:dictionary onTruncation:onTruncation];
}

@end
