
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation NSObject (AMATestAdditions)

+ (id)stubbedNullMockForDefaultInit
{
    return [self stubbedNullMockForInit:@selector(init)];
}

+ (id)stubbedNullMockForInit:(SEL)selector
{
    KWMock *mock = [self nullMock];
    return [self stubInstance:mock forInit:selector];
}

+ (id)stubInstance:(id)instance forInit:(SEL)selector
{
    [self stub:@selector(alloc) andReturn:instance];
    [instance stub:selector andReturn:instance];
    return instance;
}

@end

@implementation AMATestUtilities

+ (void)fillObjectPointerParameter:(NSValue *)parameter withValue:(id)value
{
    void *errorPointer = [parameter pointerValue];
    if (errorPointer != NULL) {
        *(id __autoreleasing *)errorPointer = value;
    }
}

+ (void)fillIntPointerParameter:(NSValue *)parameter withValue:(NSUInteger)value
{
    void *errorPointer = [parameter pointerValue];
    if (errorPointer != NULL) {
        *(NSUInteger *)errorPointer = value;
    }
}

+ (NSString *)stringOfLength:(NSUInteger)length filledWithSample:(NSString *)sample
{
    NSMutableString *string = [NSMutableString stringWithCapacity:length + sample.length];
    NSUInteger samplesCount = (length / sample.length) + 1;
    for (NSUInteger idx = 0; idx < samplesCount; ++idx) {
        [string appendString:sample];
    }
    return [string substringWithRange:[string rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, length)]];
}

+ (NSData *)dataOfSize:(NSUInteger)size filledWithSample:(NSData *)sample
{
    NSMutableData *data = [NSMutableData dataWithCapacity:size + sample.length];
    NSUInteger samplesCount = (size / sample.length) + 1;
    for (NSUInteger idx = 0; idx < samplesCount; ++idx) {
        [data appendData:sample];
    }
    return [data subdataWithRange:NSMakeRange(0, size)];
}

+ (void)stubAssertions
{
    NSAssertionHandler *handler = [NSAssertionHandler currentHandler];
    [handler stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
    [handler stub:@selector(handleFailureInFunction:file:lineNumber:description:)];
}

@end
