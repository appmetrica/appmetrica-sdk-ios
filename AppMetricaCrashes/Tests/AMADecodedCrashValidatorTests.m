
#import "AMADecodedCrashValidator.h"
#import "AMADecodedCrash.h"
#import "AMAInfo.h"
#import "AMABinaryImage.h"
#import "AMASystemInfo.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMANSException.h"
#import "AMACppException.h"
#import "AMARegister.h"
#import "AMAMemory.h"
#import "AMAApplicationStatistics.h"
#import "AMABacktraceFrame.h"

#import <AppMetricaKiwi/AppMetricaKiwi.h>

SPEC_BEGIN(AMADecodedCrashValidatorTests)

describe(@"AMADecodedCrashValidator", ^{
    
    AMADecodedCrashValidator *__block validator = nil;
    
    id (^copyableMock)(void) = ^id(void) {
        id mock = [KWMock nullMock];
        [mock stub:@selector(copy) andReturn:mock];
        return mock;
    };
    
    void (^validatorShouldHaveCriticalCode)(void) = ^void(void) {
        [[theValue([validator result].code) should] equal:theValue(AMACrashValidatorErrorCodeCritical)];
    };
    
    void (^validatorShouldHaveSuspiciousCode)(void) = ^void(void) {
        [[theValue([validator result].code) should] equal:theValue(AMACrashValidatorErrorCodeSuspicious)];
    };
    
    void (^validatorShouldHaveNonCriticalCode)(void) = ^void(void) {
        [[theValue([validator result].code) should] equal:theValue(AMACrashValidatorErrorCodeNonCritical)];
    };
    
    beforeEach(^{
        validator = [[AMADecodedCrashValidator alloc] init];
    });
    
    context(@"Basic behaviour", ^{
        
        it(@"Should return nothing if nothing was submitted", ^{
            [[validator result] shouldBeNil];
        });
        
        it(@"Should return nothing if validator was reset", ^{
            [validator validateDecodedCrash:nil];
            [[validator result] shouldNotBeNil];
            [validator reset];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should override non-critical error code with suspicious", ^{
            [validator validateRegister:nil];
            validatorShouldHaveNonCriticalCode();
            [validator validateMemory:nil];
            validatorShouldHaveSuspiciousCode();
        });
        
        it(@"Should override suspicious error code with critical", ^{
            [validator validateMemory:nil];
            validatorShouldHaveSuspiciousCode();
            [validator validateDecodedCrash:nil];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should not override critical error code with suspicious", ^{
            [validator validateDecodedCrash:nil];
            validatorShouldHaveCriticalCode();
            [validator validateMemory:nil];
            validatorShouldHaveCriticalCode();
        });
    });
    
    context(@"AMADecodedCrash validation", ^{
        
        it(@"Should not report of any error if crash is valid", ^{
            AMADecodedCrash *decodedCrash = [[AMADecodedCrash alloc] initWithAppState:[KWMock nullMock]
                                                                          appBuildUID:[KWMock nullMock]
                                                                     errorEnvironment:[KWMock nullMock]
                                                                       appEnvironment:[KWMock nullMock]
                                                                                 info:[KWMock nullMock]
                                                                         binaryImages:@[ [KWMock nullMock] ]
                                                                               system:[KWMock nullMock]
                                                                                crash:[KWMock nullMock]];
            [[theValue([validator validateDecodedCrash:decodedCrash]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should not report of any error if crash doesn't have system", ^{
            AMADecodedCrash *decodedCrash = [[AMADecodedCrash alloc] initWithAppState:[KWMock nullMock]
                                                                          appBuildUID:[KWMock nullMock]
                                                                     errorEnvironment:[KWMock nullMock]
                                                                       appEnvironment:[KWMock nullMock]
                                                                                 info:[KWMock nullMock]
                                                                         binaryImages:@[ [KWMock nullMock] ]
                                                                               system:nil
                                                                                crash:[KWMock nullMock]];
            [[theValue([validator validateDecodedCrash:decodedCrash]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of critical error if crash doesn't have crash", ^{
            AMADecodedCrash *decodedCrash = [[AMADecodedCrash alloc] initWithAppState:[KWMock nullMock]
                                                                          appBuildUID:[KWMock nullMock]
                                                                     errorEnvironment:[KWMock nullMock]
                                                                       appEnvironment:[KWMock nullMock]
                                                                                 info:[KWMock nullMock]
                                                                         binaryImages:@[ [KWMock nullMock] ]
                                                                               system:[KWMock nullMock]
                                                                                crash:nil];
            [[theValue([validator validateDecodedCrash:decodedCrash]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should report of suspicious error if crash doesn't have binary images", ^{
            AMADecodedCrash *decodedCrash = [[AMADecodedCrash alloc] initWithAppState:[KWMock nullMock]
                                                                          appBuildUID:[KWMock nullMock]
                                                                     errorEnvironment:[KWMock nullMock]
                                                                       appEnvironment:[KWMock nullMock]
                                                                                 info:[KWMock nullMock]
                                                                         binaryImages:nil
                                                                               system:[KWMock nullMock]
                                                                                crash:[KWMock nullMock]];
            [[theValue([validator validateDecodedCrash:decodedCrash]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
    });
    
    context(@"AMAInfo validation", ^{
        
        it(@"Should not report of any error if info is valid", ^{
            AMAInfo *info = [[AMAInfo alloc] initWithVersion:copyableMock()
                                                  identifier:copyableMock()
                                                   timestamp:[KWMock nullMock]
                                          virtualMachineInfo:[KWMock nullMock]];
            [[theValue([validator validateInfo:info]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should not report of any error if info doesn't have version", ^{
            AMAInfo *info = [[AMAInfo alloc] initWithVersion:nil
                                                  identifier:copyableMock()
                                                   timestamp:[KWMock nullMock]
                                          virtualMachineInfo:[KWMock nullMock]];
            [[theValue([validator validateInfo:info]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of critical error if info doesn't have id", ^{
            AMAInfo *info = [[AMAInfo alloc] initWithVersion:copyableMock()
                                                  identifier:nil
                                                   timestamp:[KWMock nullMock]
                                          virtualMachineInfo:[KWMock nullMock]];
            [[theValue([validator validateInfo:info]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should report of critical error if info doesn't have timestamp", ^{
            AMAInfo *info = [[AMAInfo alloc] initWithVersion:copyableMock()
                                                  identifier:copyableMock()
                                                   timestamp:nil
                                          virtualMachineInfo:[KWMock nullMock]];
            [[theValue([validator validateInfo:info]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should not report of any error if does not have virtualMachineInfo", ^{
            AMAInfo *info = [[AMAInfo alloc] initWithVersion:copyableMock()
                                                  identifier:copyableMock()
                                                   timestamp:[KWMock nullMock]
                                          virtualMachineInfo:nil];
            [[theValue([validator validateInfo:info]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
    });
    
    context(@"AMABinaryImage validation", ^{
        
        it(@"Should not report of any error if image is valid", ^{
            AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:copyableMock()
                                                                    UUID:copyableMock()
                                                                 address:0x123
                                                                    size:123
                                                               vmAddress:456
                                                                 cpuType:1
                                                              cpuSubtype:2
                                                            majorVersion:3
                                                            minorVersion:2
                                                         revisionVersion:0
                                                        crashInfoMessage:nil
                                                       crashInfoMessage2:nil];
            [[theValue([validator validateBinaryImage:image]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of critical error if image doesn't have name", ^{
            AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:nil
                                                                    UUID:copyableMock()
                                                                 address:0x123
                                                                    size:123
                                                               vmAddress:456
                                                                 cpuType:1
                                                              cpuSubtype:2
                                                            majorVersion:3
                                                            minorVersion:2
                                                         revisionVersion:0
                                                        crashInfoMessage:nil
                                                       crashInfoMessage2:nil];
            [[theValue([validator validateBinaryImage:image]) should] beYes];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if image doesn't have UUID", ^{
            AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:copyableMock()
                                                                    UUID:nil
                                                                 address:0x123
                                                                    size:123
                                                               vmAddress:456
                                                                 cpuType:1
                                                              cpuSubtype:2
                                                            majorVersion:3
                                                            minorVersion:2
                                                         revisionVersion:0
                                                        crashInfoMessage:nil
                                                       crashInfoMessage2:nil];
            [[theValue([validator validateBinaryImage:image]) should] beYes];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of suspicious error if image has invalid address", ^{
            AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:copyableMock()
                                                                    UUID:copyableMock()
                                                                 address:0x0
                                                                    size:123
                                                               vmAddress:456
                                                                 cpuType:1
                                                              cpuSubtype:2
                                                            majorVersion:3
                                                            minorVersion:2
                                                         revisionVersion:0
                                                        crashInfoMessage:nil
                                                       crashInfoMessage2:nil];
            [[theValue([validator validateBinaryImage:image]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
        
        it(@"Should report of suspicious error if image has invalid size", ^{
            AMABinaryImage *image = [[AMABinaryImage alloc] initWithName:copyableMock()
                                                                    UUID:copyableMock()
                                                                 address:0x123
                                                                    size:0
                                                               vmAddress:456
                                                                 cpuType:1
                                                              cpuSubtype:2
                                                            majorVersion:3
                                                            minorVersion:2
                                                         revisionVersion:0
                                                        crashInfoMessage:nil
                                                       crashInfoMessage2:nil];
            [[theValue([validator validateBinaryImage:image]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
    });
    
    context(@"AMASystemInfo validation", ^{
        
        it(@"Should not report of any error if system is valid", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of non-critical error if there is no kernel version", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:nil
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no OS build number", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:nil
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no boot timestamp", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:nil
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no app start timestamp", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:nil
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no executable path", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:nil
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no cpuArch", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:nil
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no process name", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:nil
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no memory", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:nil
                                                                applicationStats:copyableMock()];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
        
        it(@"Should report of non-critical error if there is no application stats", ^{
            AMASystemInfo *system = [[AMASystemInfo alloc] initWithKernelVersion:copyableMock()
                                                                   osBuildNumber:copyableMock()
                                                                   bootTimestamp:copyableMock()
                                                               appStartTimestamp:copyableMock()
                                                                  executablePath:copyableMock()
                                                                         cpuArch:copyableMock()
                                                                         cpuType:1
                                                                      cpuSubtype:2
                                                                   binaryCpuType:1
                                                                binaryCpuSubtype:2
                                                                     processName:copyableMock()
                                                                       processId:3
                                                                 parentProcessId:2
                                                                       buildType:AMABuildTypeUnknown
                                                                         storage:2
                                                                          memory:copyableMock()
                                                                applicationStats:nil];
            
            [[theValue([validator validateSystem:system]) should] beNo];
            validatorShouldHaveNonCriticalCode();
        });
    });
    
    context(@"AMACrashReportCrash validation", ^{
        
        it(@"Should not report of any error if crash is valid", ^{
            AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:[KWMock nullMock]
                                                                            threads:@[ copyableMock() ]];
            [[theValue([validator validateCrash:crash]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of critical error if there is no error", ^{
            AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:nil
                                                                            threads:@[ copyableMock() ]];
            [[theValue([validator validateCrash:crash]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should not report of any error if there is no threads", ^{
            AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:[KWMock nullMock]
                                                                            threads:@[]];
            [[theValue([validator validateCrash:crash]) should] beNo];
            [[[validator result] should] beNil];
        });
    });
    
    context(@"AMACrashReportError validation", ^{
        
        it(@"Should not report of any error if error is valid", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x123
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeMachException
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:[KWMock nullMock]];
            [[theValue([validator validateError:error]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of critical error if there is no mach codes", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x123
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeMachException
                                                                                 mach:nil
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:[KWMock nullMock]];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should report of critical error if there is no BSD signal codes", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x123
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeSignal
                                                                                 mach:[KWMock nullMock]
                                                                               signal:nil
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should report of critical error if there is no Non Fatal and the type is AMACrashTypeNonFatal", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x0
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeNonFatal
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        it(@"Should report of critical error if there is no Non Fatal and the type is AMACrashTypeVirtualMachineError", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x0
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeVirtualMachineError
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        it(@"Should report of critical error if there is no Non Fatal and the type is AMACrashTypeVirtualMachineCustomError", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x0
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeVirtualMachineCustomError
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
        
        it(@"Should not report of any error if instruction address is invalid", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x0
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeSignal
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beNo];
            [[[validator result] should] beNil];
        });
        
        it(@"Should report of critical error if there is no virtual machine crash and the type is AMACrashTypeVirtualMachineCrash", ^{
            AMACrashReportError *error = [[AMACrashReportError alloc] initWithAddress:0x0
                                                                               reason:@"Something happened"
                                                                                 type:AMACrashTypeVirtualMachineCrash
                                                                                 mach:[KWMock nullMock]
                                                                               signal:[KWMock nullMock]
                                                                          nsexception:nil
                                                                         cppException:nil
                                                                       nonFatalsChain:nil
                                                                  virtualMachineCrash:nil];
            [[theValue([validator validateError:error]) should] beYes];
            validatorShouldHaveCriticalCode();
        });
    });
    
    context(@"AMARegister validation", ^{
        
        it(@"Should not report of any error if register is valid", ^{
            AMARegister *amaRegister = [[AMARegister alloc] initWithName:@"ax" value:12345];
            
            [[theValue([validator validateRegister:amaRegister]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of non-critical error if there is no register name", ^{
            AMARegister *amaRegister = [[AMARegister alloc] initWithName:nil value:12345];
            
            [[theValue([validator validateRegister:amaRegister]) should] beYes];
            validatorShouldHaveNonCriticalCode();
        });
    });
    
    context(@"AMAMemory validation", ^{
        
        it(@"Should not report of any error if memory is valid", ^{
            AMAMemory *memory = [[AMAMemory alloc] initWithSize:1024
                                                         usable:512
                                                           free:512];
            
            [[theValue([validator validateMemory:memory]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of suspicious error if memory size is invalid", ^{
            AMAMemory *memory = [[AMAMemory alloc] initWithSize:0
                                                         usable:512
                                                           free:512];
            
            [[theValue([validator validateMemory:memory]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
        
        it(@"Should report of suspicious error if free memory size is invalid", ^{
            AMAMemory *memory = [[AMAMemory alloc] initWithSize:1024
                                                         usable:512
                                                           free:0];
            
            [[theValue([validator validateMemory:memory]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
        
        it(@"Should report of suspicious error if usable memory size is invalid", ^{
            AMAMemory *memory = [[AMAMemory alloc] initWithSize:1024
                                                         usable:0
                                                           free:512];
            
            [[theValue([validator validateMemory:memory]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
    });
    
    context(@"AMAApplicationStatistics validation", ^{
        
        it(@"Should not report of any error if app stats are valid", ^{
            AMAApplicationStatistics *appStats = [[AMAApplicationStatistics alloc] initWithApplicationActive:YES
                                                                                     applicationInForeground:NO
                                                                                      launchesSinceLastCrash:0
                                                                                      sessionsSinceLastCrash:0
                                                                                    activeTimeSinceLastCrash:0
                                                                                backgroundTimeSinceLastCrash:0
                                                                                         sessionsSinceLaunch:1
                                                                                       activeTimeSinceLaunch:1234
                                                                                   backgroundTimeSinceLaunch:123];
            
            [[theValue([validator validateAppStats:appStats]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should report of suspicious error if active time since launch is 0", ^{
            AMAApplicationStatistics *appStats = [[AMAApplicationStatistics alloc] initWithApplicationActive:YES
                                                                                     applicationInForeground:NO
                                                                                      launchesSinceLastCrash:0
                                                                                      sessionsSinceLastCrash:0
                                                                                    activeTimeSinceLastCrash:0
                                                                                backgroundTimeSinceLastCrash:0
                                                                                         sessionsSinceLaunch:1
                                                                                       activeTimeSinceLaunch:0
                                                                                   backgroundTimeSinceLaunch:123];
            
            [[theValue([validator validateAppStats:appStats]) should] beNo];
            validatorShouldHaveSuspiciousCode();
        });
    });
    
    context(@"AMABacktraceFrame validation", ^{
        
        it(@"Should not report of any error if backtrace frame is valid", ^{
            AMABacktraceFrame *frame = [[AMABacktraceFrame alloc] initWithLineOfCode:nil
                                                                  instructionAddress:@0x0012fe0b
                                                                       symbolAddress:@0x0012fe00
                                                                       objectAddress:@0x00120000
                                                                          symbolName:@"Foundation.framework"
                                                                          objectName:nil
                                                                            stripped:NO];
            
            [[theValue([validator validateBacktraceFrame:frame]) should] beNo];
            [[validator result] shouldBeNil];
        });
        
        it(@"Should not report of any error if everything is empty", ^{
            AMABacktraceFrame *frame = [[AMABacktraceFrame alloc] initWithLineOfCode:nil
                                                                  instructionAddress:@0x0
                                                                       symbolAddress:nil
                                                                       objectAddress:nil
                                                                          symbolName:nil
                                                                          objectName:nil
                                                                            stripped:NO
                                                                        columnOfCode:nil
                                                                           className:nil
                                                                          methodName:nil
                                                                      sourceFileName:nil];
            
            [[theValue([validator validateBacktraceFrame:frame]) should] beNo];
            [[[validator result] should] beNil];
        });
    });
});

SPEC_END
