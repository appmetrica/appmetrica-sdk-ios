
#import "AMACrashBacktraceFrame.h"

@interface AMACrashBacktraceFrame ()

@property (nonatomic, strong, readwrite, nullable) NSNumber *instructionAddress;
@property (nonatomic, strong, readwrite, nullable) NSNumber *symbolAddress;
@property (nonatomic, strong, readwrite, nullable) NSNumber *objectAddress;

@property (nonatomic, copy, readwrite, nullable) NSString *symbolName;
@property (nonatomic, copy, readwrite, nullable) NSString *objectName;

@property (nonatomic, assign, readwrite) BOOL stripped;

@end

@implementation AMACrashBacktraceFrame

- (instancetype)initWithClassName:(NSString *)className
                       methodName:(NSString *)methodName
                       lineOfCode:(NSNumber *)lineOfCode
                     columnOfCode:(NSNumber *)columnOfCode
                   sourceFileName:(NSString *)sourceFileName
{
    self = [super init];
    if (self != nil) {
        _className = [className copy];
        _methodName = [methodName copy];
        _lineOfCode = lineOfCode;
        _columnOfCode = columnOfCode;
        _sourceFileName = [sourceFileName copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

@implementation AMAMutableCrashBacktraceFrame

@dynamic instructionAddress;
@dynamic symbolAddress;
@dynamic objectAddress;
@dynamic symbolName;
@dynamic objectName;
@dynamic stripped;

- (id)copyWithZone:(NSZone *)zone
{
    AMACrashBacktraceFrame *copy = [[AMACrashBacktraceFrame alloc] initWithClassName:self.className
                                                                         methodName:self.methodName
                                                                         lineOfCode:self.lineOfCode
                                                                       columnOfCode:self.columnOfCode
                                                                     sourceFileName:self.sourceFileName];
    copy.instructionAddress = self.instructionAddress;
    copy.symbolAddress = self.symbolAddress;
    copy.objectAddress = self.objectAddress;
    copy.symbolName = self.symbolName;
    copy.objectName = self.objectName;
    copy.stripped = self.stripped;
    return copy;
}

@end
