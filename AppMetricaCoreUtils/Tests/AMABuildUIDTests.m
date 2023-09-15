
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMABuildUID (Tests)

@property (nonatomic, copy, readonly) NSDate *buildDate;

@end

SPEC_BEGIN(AMABuildUIDTests)

describe(@"AMABuildUID", ^{

    NSFileManager *__block fileManager = nil;
    NSDate *__block buildDate = nil;

    beforeEach(^{
        fileManager = [KWMock nullMockForClass:[NSFileManager class]];
        [NSFileManager stub:@selector(defaultManager) andReturn:fileManager];
        NSDictionary *fileAttributes = [KWMock nullMockForClass:[NSDictionary class]];
        [fileManager stub:@selector(attributesOfItemAtPath:error:) andReturn:fileAttributes];
        [fileAttributes stub:@selector(fileModificationDate) withBlock:^id(NSArray *params) {
            return buildDate;
        }];
    });

    it(@"Should fetch build date from main bundle executable", ^{
        NSString *executablePath = [[NSBundle mainBundle] executablePath];
        KWCaptureSpy *spy = [fileManager captureArgument:@selector(attributesOfItemAtPath:error:) atIndex:0];

        [AMABuildUID buildUID];
        [[spy.argument should] equal:executablePath];
    });

    it(@"Should return equal buildUID for equal build date", ^{
        buildDate = [NSDate date];
        AMABuildUID *firstBuildUID = [AMABuildUID buildUID];
        AMABuildUID *secondBuildUID = [AMABuildUID buildUID];

        [[secondBuildUID should] equal:firstBuildUID];
    });

    it(@"Should return different buildUID for different build date", ^{
        buildDate = [NSDate date];
        AMABuildUID *nowBuildUID = [AMABuildUID buildUID];
        buildDate = [NSDate dateWithTimeIntervalSinceNow:-3600.0];
        AMABuildUID *oldBuildUID = [AMABuildUID buildUID];

        [[oldBuildUID shouldNot] equal:nowBuildUID];
    });

    it(@"Should increase with time", ^{
        buildDate = [NSDate date];
        AMABuildUID *nowBuildUID = [AMABuildUID buildUID];
        buildDate = [NSDate dateWithTimeIntervalSinceNow:-3600.0];
        AMABuildUID *oldBuildUID = [AMABuildUID buildUID];

        [[nowBuildUID should] beGreaterThan:oldBuildUID];
    });

    it(@"Should store build date", ^{
        buildDate = [NSDate date];
        AMABuildUID *buildUID = [AMABuildUID buildUID];

        [[buildUID.buildDate should] equal:buildDate];
    });

    it(@"Should return buildUID without valid build date", ^{
        buildDate = nil;
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        
        [[buildUID.stringValue should] beNonNil];
    });
    
    it(@"Should comform to NSCopying", ^{
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        [[buildUID should] conformToProtocol:@protocol(NSCopying)];
    });
    it(@"Should comform to NSSecureCoding", ^{
        AMABuildUID *buildUID = [AMABuildUID buildUID];
        [[buildUID should] conformToProtocol:@protocol(NSSecureCoding)];
    });
});

SPEC_END
