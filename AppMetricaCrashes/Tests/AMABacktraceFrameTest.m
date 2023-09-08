
#import <Kiwi/Kiwi.h>
#import "AMABacktraceFrame.h"

SPEC_BEGIN(AMABacktraceFrameTest)

describe(@"AMABacktraceFrame", ^{

    context(@"Native constructor", ^{
        NSNumber *line = @56;
        NSNumber *instructionAddress = @345;
        NSNumber *symbolAddress = @1212;
        NSNumber *objectAddress = @3333;
        NSString *symbolName = @"my symbol";
        NSString *objectName = @"my object";
        BOOL stripped = YES;
        AMABacktraceFrame *__block frame;
        beforeEach(^{
            frame = [[AMABacktraceFrame alloc] initWithLineOfCode:line
                                               instructionAddress:instructionAddress
                                                    symbolAddress:symbolAddress
                                                    objectAddress:objectAddress
                                                       symbolName:symbolName
                                                       objectName:objectName
                                                         stripped:stripped];
        });
        it(@"Should fill line of code", ^{
            [[frame.lineOfCode should] equal:line];
        });
        it(@"Should fill instruction address", ^{
            [[frame.instructionAddress should] equal:instructionAddress];
        });
        it(@"Should fill symbol address", ^{
            [[frame.symbolAddress should] equal:symbolAddress];
        });
        it(@"Should fill object address", ^{
            [[frame.objectAddress should] equal:objectAddress];
        });
        it(@"Should fill symbol name", ^{
            [[frame.symbolName should] equal:symbolName];
        });
        it(@"Should fill object name", ^{
            [[frame.objectName should] equal:objectName];
        });
        it(@"Should fill stripped", ^{
            [[theValue(frame.stripped) should] equal:theValue(stripped)];
        });
        it(@"Should not fill column of code", ^{
            [[frame.columnOfCode should] beNil];
        });
        it(@"Should not fill method name", ^{
            [[frame.methodName should] beNil];
        });
        it(@"Should not fill class name", ^{
            [[frame.className should] beNil];
        });
        it(@"Should not fill source file name", ^{
            [[frame.sourceFileName should] beNil];
        });
    });

    context(@"Plugin constructor", ^{
        NSNumber *line = @856;
        NSNumber *column = @45;
        NSString *className = @"my class";
        NSString *methodName = @"my method";
        NSString *sourceFileName = @"my file";
        AMABacktraceFrame *__block frame;
        beforeEach(^{
            frame = [[AMABacktraceFrame alloc] initWithClassName:className
                                                      methodName:methodName
                                                      lineOfCode:line
                                                    columnOfcode:column
                                                  sourceFileName:sourceFileName];
        });
        it(@"Should fill line of code", ^{
            [[frame.lineOfCode should] equal:line];
        });
        it(@"Should fill column of code", ^{
            [[frame.columnOfCode should] equal:column];
        });
        it(@"Should fill class name", ^{
            [[frame.className should] equal:className];
        });
        it(@"Should fill method name", ^{
            [[frame.methodName should] equal:methodName];
        });
        it(@"Should fill source file name", ^{
            [[frame.sourceFileName should] equal:sourceFileName];
        });
        it(@"Should not fill instruction address", ^{
            [[frame.instructionAddress should] beNil];
        });
        it(@"Should not fill symbol address", ^{
            [[frame.symbolAddress should] beNil];
        });
        it(@"Should not fill object address", ^{
            [[frame.objectAddress should] beNil];
        });
        it(@"Should not fill object name", ^{
            [[frame.objectName should] beNil];
        });
        it(@"Should not fill symbol name", ^{
            [[frame.symbolName should] beNil];
        });
        it(@"Should not fill stripped", ^{
            [[theValue(frame.stripped) should] beNo];
        });

    });
});

SPEC_END
