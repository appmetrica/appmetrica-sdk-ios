
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

#import "AMACrashReportDecoder.h"
#import "KSCrashReportFields.h"
#import "AMADecodedCrash.h"
#import "AMAInfo.h"
#import "AMABinaryImage.h"
#import "AMASystem.h"
#import "AMAMemory.h"
#import "AMAApplicationStatistics.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMAMach.h"
#import "AMASignal.h"
#import "AMANSException.h"
#import "AMACppException.h"
#import "AMAThread.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMARegistersContainer.h"
#import "AMARegister.h"
#import "AMAStack.h"
#import "AMACrashContext.h"
#import "AMAVirtualMachineInfo.h"

SPEC_BEGIN(AMACrashReportDecoderTests)

describe(@"AMACrashReportDecoder", ^{

    NSNumber *const crashID = @42;
    
    NSMutableDictionary *__block root = nil;
    KWCaptureSpy *__block decodedCrashSpy = nil;
    KWCaptureSpy *__block errorSpy = nil;
    NSObject<AMACrashReportDecoderDelegate> *__block delegateMock = nil;
    AMACrashReportDecoder *__block decoder = nil;
    AMADateProviderMock *__block dateProvider = nil;
    
    NSString *const kNormalReportFileName = @"8980AE83-1607-4566-BC5E-7D0DAF3414C9-SHORT";
    NSString *const kANRErrorFileName = @"anr_error";

    beforeEach(^{
        delegateMock = [KWMock mockForProtocol:@protocol(AMACrashReportDecoderDelegate)];
        SEL callbackSelector = @selector(crashReportDecoder:didDecodeCrash:withError:);
        decodedCrashSpy = [delegateMock captureArgument:callbackSelector atIndex:1];
        errorSpy = [delegateMock captureArgument:callbackSelector atIndex:2];
        dateProvider = [[AMADateProviderMock alloc] init];
        decoder = [[AMACrashReportDecoder alloc] initWithCrashID:crashID dateProvider:dateProvider];
        decoder.delegate = delegateMock;

        NSString *path = [AMAModuleBundleProvider.moduleBundle pathForResource:kNormalReportFileName ofType:@"plist"];
        root = [[[NSDictionary alloc] initWithContentsOfFile:path] mutableCopy];
        root[@KSCrashField_Report] = [root[@KSCrashField_Report] mutableCopy];
        root[@KSCrashField_System] = [root[@KSCrashField_System] mutableCopy];
        root[@KSCrashField_Crash] = [root[@KSCrashField_Crash] mutableCopy];
        root[@KSCrashField_User] = [root[@KSCrashField_User] mutableCopy];
        root[@KSCrashField_Crash][@KSCrashField_Error] = [root[@KSCrashField_Crash][@KSCrashField_Error] mutableCopy];
        root[@KSCrashField_Crash][@KSCrashField_Error][@KSCrashField_Signal] =
            [root[@KSCrashField_Crash][@KSCrashField_Error][@KSCrashField_Signal] mutableCopy];
    });
    
    AMADecodedCrash *(^decodedCrash)(NSDictionary *report) = ^(NSDictionary *report){
        [decoder decode:report];
        return decodedCrashSpy.argument;
    };
    
    context(@"Error reporting", ^{
        
        it(@"Should report of error if decoded crash is nil", ^{
            [decoder decode:nil];
            [[errorSpy.argument shouldNot] beNil];
        });
        
        it(@"Should report of error if decoded crash contains incomplete key", ^{
            root[@KSCrashField_Incomplete] = @YES;
            [decoder decode:root];
            [[errorSpy.argument shouldNot] beNil];
        });

        it(@"Should report of recrash if decoded crash contains recrash report", ^{
            root[@KSCrashField_RecrashReport] = [KWMock nullMock];
            [decoder decode:root];
            [[errorSpy.argument shouldNot] beNil];
        });
    });
    
    context(@"Should decode crash report", ^{
        
        context(@"Should decode report", ^{
            
            NSMutableDictionary *__block report = nil;
            
            beforeEach(^{
                report = root[@KSCrashField_Report];
            });
            
            it(@"Should decode version", ^{
                [[decodedCrash(root).info.version should] equal:report[@KSCrashField_Version]];
            });
            
            it(@"Should decode old version format", ^{
                [decoder stub:@selector(supportedVersionsConstaints) andReturn:@[ @"3.0.0" ]];
                report[@KSCrashField_Version] = @3;
                NSString *expectedVersion = @"3.0.0";
                [[decodedCrash(root).info.version should] equal:expectedVersion];
            });
            
            it(@"Should decode very old vesrion format", ^{
                report[@KSCrashField_Version] = @{ @"major" : @3, @"minor" : @2 };
                NSString *expectedVersion = @"3.2.0";
                [[decodedCrash(root).info.version should] equal:expectedVersion];
            });
            
            it(@"Should decode id", ^{
                [[decodedCrash(root).info.identifier should] equal:report[@KSCrashField_ID]];
            });
            
            it(@"Should decode 3.2.0 timestamp fromat", ^{
                report[@KSCrashField_Version] = @"3.2.0";
                report[@KSCrashField_Timestamp] = @"2019-03-11T12:56:51Z";
                [[decodedCrash(root).info.timestamp should] equal:[[NSDate alloc]
                                                                   initWithTimeIntervalSince1970:1552309011]];
            });
            
            it(@"Should decode 3.3.0 timestamp fromat", ^{
                report[@KSCrashField_Version] = @"3.3.0";
                report[@KSCrashField_Timestamp] = @"2019-03-11T12:56:51.123456Z";
                [[decodedCrash(root).info.timestamp should] equal:[[NSDate alloc]
                                                                   initWithTimeIntervalSince1970:1552309011.123456]];
            });
            
            it(@"Should set current time if 3.2.0 timestamp was not parsed", ^{
                report[@KSCrashField_Version] = @"3.2.0";
                report[@KSCrashField_Timestamp] = @"18:31:42-03:30";
                [dateProvider freeze];
                [[decodedCrash(root).info.timestamp should] equal:[dateProvider currentDate]];
            });
            
            it(@"Should set current time if 3.3.0 timestamp was not parsed", ^{
                report[@KSCrashField_Version] = @"3.3.0";
                report[@KSCrashField_Timestamp] = @"18:31:42-03:30";
                [dateProvider freeze];
                [[decodedCrash(root).info.timestamp should] equal:[dateProvider currentDate]];
            });
            
            it(@"Should set current time if there is no timestamp", ^{
                [report removeObjectForKey:@KSCrashField_Timestamp];
                [dateProvider freeze];
                [[decodedCrash(root).info.timestamp should] equal:[dateProvider currentDate]];
            });

            it(@"Should not fill virtual machine info", ^{
                [[decodedCrash(root).info.virtualMachineInfo should] beNil];
            });


            it(@"Should not raise if version is 3.2.0", ^{
                report[@KSCrashField_Version] = @"3.2.0";
                [[theBlock(^{ decodedCrash(root); }) shouldNot] raise];
            });
            
            it(@"Should not raise if version is 3.3.0", ^{
                report[@KSCrashField_Version] = @"3.3.0";
                [[theBlock(^{ decodedCrash(root); }) shouldNot] raise];
            });
            
            it(@"Should not raise if version is one of the supported", ^{
                [decoder stub:@selector(supportedVersionsConstaints) andReturn:@[ @"3.0", @"4.0" ]];
                report[@KSCrashField_Version] = @"3.0.2";
                [[theBlock(^{ decodedCrash(root); }) shouldNot] raise];
            });
            
            it(@"Should raise if version is unsupported", ^{
                [decoder stub:@selector(supportedVersionsConstaints) andReturn:@[ @"3.0.0" ]];
                report[@KSCrashField_Version] = @"3.3.0";
                [[theBlock(^{ decodedCrash(root); }) should] raise];
            });
        });
        
        context(@"Should decode user info", ^{
            
            NSMutableDictionary *__block userInfo = nil;
            
            beforeEach(^{
                userInfo = root[@KSCrashField_User];
            });
            
            it(@"Should use provided app version", ^{
                NSString *testVersion = @"Test app vestion";
                userInfo[kAMACrashContextAppVersionKey] = testVersion;
                [[decodedCrash(root).appState.appVersionName should] equal:testVersion];
            });
            
            it(@"Should use provided build number", ^{
                NSNumber *testBuildNumber = @123;
                userInfo[kAMACrashContextAppBuildNumberKey] = testBuildNumber;
                [[decodedCrash(root).appState.appBuildNumber should] equal:[testBuildNumber stringValue]];
            });
            
            it(@"Should decode build UID", ^{
                [[decodedCrash(root).appBuildUID.stringValue should] equal:userInfo[kAMACrashContextAppBuildUIDKey]];
            });
            
            it(@"Should decode app enviroment", ^{
                [[decodedCrash(root).appEnvironment should] equal:userInfo[kAMACrashContextAppEnvironmentKey]];
            });
            
            it(@"Should decode error enviroment", ^{
                [[decodedCrash(root).errorEnvironment should] equal:userInfo[kAMACrashContextErrorEnvironmentKey]];
            });
        });
        
        context(@"Should decode binary images", ^{
            
            NSArray *__block binaryImages = nil;
            
            AMABinaryImage *(^binaryImage)(NSDictionary *) = ^AMABinaryImage *(NSDictionary *dict) {
                return [[AMABinaryImage alloc] initWithName:dict[@KSCrashField_Name]
                                                       UUID:dict[@KSCrashField_UUID]
                                                    address:[dict[@KSCrashField_ImageAddress] unsignedIntegerValue]
                                                       size:[dict[@KSCrashField_ImageSize] unsignedIntegerValue]
                                                  vmAddress:[dict[@KSCrashField_ImageVmAddress] unsignedIntegerValue]
                                                    cpuType:[dict[@KSCrashField_CPUType] unsignedIntegerValue]
                                                 cpuSubtype:[dict[@KSCrashField_CPUSubType] unsignedIntegerValue]
                                               majorVersion:[dict[@KSCrashField_ImageMajorVersion] intValue]
                                               minorVersion:[dict[@KSCrashField_ImageMinorVersion] intValue]
                                            revisionVersion:[dict[@KSCrashField_ImageRevisionVersion] intValue]
                                           crashInfoMessage:dict[@KSCrashField_ImageCrashInfoMessage]
                                          crashInfoMessage2:dict[@KSCrashField_ImageCrashInfoMessage2]];
            };
            
            beforeEach(^{
                binaryImages = root[@KSCrashField_BinaryImages];
            });
            
            it(@"Should contain the same number of binary imgaes", ^{
                [[[decodedCrash(root) should] have:binaryImages.count] binaryImages];
            });
            
            it(@"Should contain exact binary images", ^{
                NSDictionary *firstImage = binaryImages.firstObject;
                NSDictionary *secondImage = binaryImages.lastObject;
                AMABinaryImage *expectredFirstBinaryImage = binaryImage(firstImage);
                AMABinaryImage *expectredSecondBinaryImage = binaryImage(secondImage);
                
                [[decodedCrash(root).binaryImages should] contain:expectredFirstBinaryImage];
                [[decodedCrash(root).binaryImages should] contain:expectredSecondBinaryImage];
            });

            it(@"Should contain concrete image", ^{
                AMABinaryImage *expectedImage =
                    [[AMABinaryImage alloc] initWithName:@"/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer"
                                                    UUID:@"F7EE1BCF-1076-3614-90C2-AA0F4F6B7BD4"
                                                 address:6759378944
                                                    size:4395008
                                               vmAddress:6732328960
                                                 cpuType:16777228
                                              cpuSubtype:0
                                            majorVersion:1
                                            minorVersion:0
                                         revisionVersion:0
                                        crashInfoMessage:@"Crash Info Message"
                                       crashInfoMessage2:@"Crash Info Message 2"];
                [[decodedCrash(root).binaryImages should] contain:expectedImage];
            });
        });

        context(@"Should decode system dict", ^{

            AMASystem *__block system = nil;

            NSMutableDictionary *const systemExample = [@{
                @"appID" : @"10AC2E2D-150C-3C60-9D21-D209F47E11C2",
                @"appStartTime" : @"2019-04-22T12:51:58Z",
                @"binaryCPUSubType" : @3,
                @"binaryCPUType" : @16777223,
                @"bootTime" : @"2019-04-20T13:12:03Z",
                @"buildType" : @"simulator",
                @"bundleID" : @"io.appmetrica.sample",
                @"bundleName" : @"MetricaSample",
                @"bundleShortVersion" : @370,
                @"bundleVersion" : @0,
                @"cpuArchitecture" : @"x86",
                @"cpuSubType" : @8,
                @"cpuType" : @7,
                @"deviceAppHash" : @"5e8742639872c51263e17c820ab2722312ed4788",
                @"executableName" : @"MetricaSample",
                @"executablePath" : @"/Users/glinnik/Library/Developer/CoreSimulator/Devices/"
                                    "1A8EE980-4481-442C-86D5-D3BDC53A255C/data/Containers/Bundle/Application/"
                                    "33B44775-FA90-47DC-944C-A731C810ECE3/MetricaSample.app/MetricaSample",
                @"freeMemory" : @133062656,
                @"isJailbroken" : @0,
                @"kernelVersion" : @"Darwin Kernel Version 18.5.0: Mon Mar 11 20:40:32 PDT 2019; "
                                   "root:xnu-4903.251.3~3/RELEASE_X86_64",
                @"machine" : @"iPhone6,1",
                @"memorySize" : @17179869184,
                @"model" : @"simulator",
                @"osVersion" : @"18E226",
                @"parentProcessID" : @39356,
                @"processID" : @39355,
                @"processName" : @"MetricaSample",
                @"storageSize" : @250685575168,
                @"systemName" : @"iOS",
                @"systemVersion" : @"12.2",
                @"timezone" : @"GMT+3",
                @"usableMemory" : @14042402816,
            } mutableCopy];

            beforeEach(^{
                system = [decoder systemInfoForDictionary:systemExample];
            });

            it(@"Should decode kernel version", ^{
                [[system.kernelVersion should] equal:systemExample[kAMASysInfoKernelVersion]];
            });

            it(@"Should decode OS build number", ^{
                [[system.osBuildNumber should] equal:systemExample[kAMASysInfoOsVersion]];
            });

            it(@"Should decode boot timestamp", ^{
                [[system.bootTimestamp should] equal:[[NSDate alloc] initWithTimeIntervalSince1970:1555765923]];
            });

            it(@"Should decode app start timestamp", ^{
                [[system.appStartTimestamp should] equal:[[NSDate alloc] initWithTimeIntervalSince1970:1555937518]];
            });

            it(@"Should decode executable path", ^{
                [[system.executablePath should] equal:systemExample[kAMASysInfoExecutablePath]];
            });

            it(@"Should decode CPU architecture", ^{
                [[system.cpuArch should] equal:systemExample[kAMASysInfoCpuArchitecture]];
            });

            it(@"Should decode CPU type", ^{
                [[theValue(system.cpuType) should] equal:systemExample[kAMASysInfoCpuType]];
            });

            it(@"Should decode CPU subtype", ^{
                [[theValue(system.cpuSubtype) should] equal:systemExample[kAMASysInfoCpuSubType]];
            });

            it(@"Should decode CPU binary type", ^{
                [[theValue(system.binaryCpuType) should] equal:systemExample[kAMASysInfoBinaryCPUType]];
            });

            it(@"Should decode CPU binary subtype", ^{
                [[theValue(system.binaryCpuSubtype) should] equal:systemExample[kAMASysInfoBinaryCPUSubType]];
            });

            it(@"Should decode process name", ^{
                [[system.processName should] equal:systemExample[kAMASysInfoProcessName]];
            });

            it(@"Should decode process ID", ^{
                [[theValue(system.processId) should] equal:systemExample[kAMASysInfoProcessID]];
            });

            it(@"Should decode parent process ID", ^{
                [[theValue(system.parentProcessId) should] equal:systemExample[kAMASysInfoParentProcessID]];
            });

            it(@"Should decode storage", ^{
                [[theValue(system.storage) should] equal:systemExample[kAMASysInfoStorageSize]];
            });

            it(@"Should decode build type", ^{
                [[theValue(system.buildType) should] equal:theValue(AMABuildTypeSimulator)];
            });

            it(@"Should decode memory size", ^{
                [[theValue(system.memory.size) should] equal:systemExample[kAMASysInfoMemorySize]];
            });

            it(@"Should decode memory usable", ^{
                [[theValue(system.memory.usable) should] equal:systemExample[kAMASysInfoUsableMemory]];
            });

            it(@"Should decode memory free", ^{
                [[theValue(system.memory.free) should] equal:systemExample[kAMASysInfoFreeMemory]];
            });
        });

        context(@"Should decode system", ^{
            
            NSMutableDictionary *__block system = nil;
            
            beforeEach(^{
                system = root[@KSCrashField_System];
            });

            it(@"Should decode kernel version", ^{
                [[decodedCrash(root).system.kernelVersion should] equal:system[@KSCrashField_KernelVersion]];
            });
            
            it(@"Should decode OS build number", ^{
                [[decodedCrash(root).system.osBuildNumber should] equal:system[@KSCrashField_OSVersion]];
            });
            
            it(@"Should decode boot timestamp", ^{
                system[@KSCrashField_BootTime] = @"2019-03-11T12:56:51Z";
                [[decodedCrash(root).system.bootTimestamp should] equal:[[NSDate alloc] initWithTimeIntervalSince1970:1552309011]];
            });
            
            it(@"Should set current time if there is no boot timestamp", ^{
                [system removeObjectForKey:@KSCrashField_BootTime];
                [dateProvider freeze];
                [[decodedCrash(root).system.bootTimestamp should] equal:[dateProvider currentDate]];
            });
            
            it(@"Should decode app start timestamp", ^{
                system[@KSCrashField_AppStartTime] = @"2019-03-11T12:56:51Z";
                [[decodedCrash(root).system.appStartTimestamp should] equal:[[NSDate alloc] initWithTimeIntervalSince1970:1552309011]];
            });
            
            it(@"Should set current time if there is no app start timestamp", ^{
                [system removeObjectForKey:@KSCrashField_AppStartTime];
                [dateProvider freeze];
                [[decodedCrash(root).system.appStartTimestamp should] equal:[dateProvider currentDate]];
            });
            
            it(@"Should decode executable path", ^{
                [[decodedCrash(root).system.executablePath should] equal:system[@KSCrashField_ExecutablePath]];
            });
            
            it(@"Should decode CPU architecture", ^{
                [[decodedCrash(root).system.cpuArch should] equal:system[@KSCrashField_CPUArch]];
            });
            
            it(@"Should decode CPU type", ^{
                [[theValue(decodedCrash(root).system.cpuType) should] equal:system[@KSCrashField_CPUType]];
            });
            
            it(@"Should decode CPU subtype", ^{
                [[theValue(decodedCrash(root).system.cpuSubtype) should] equal:system[@KSCrashField_CPUSubType]];
            });
            
            it(@"Should decode CPU binary type", ^{
                [[theValue(decodedCrash(root).system.binaryCpuType) should] equal:system[@KSCrashField_BinaryCPUType]];
            });
            
            it(@"Should decode CPU binary subtype", ^{
                [[theValue(decodedCrash(root).system.binaryCpuSubtype) should] equal:system[@KSCrashField_BinaryCPUSubType]];
            });
            
            it(@"Should decode process name", ^{
                [[decodedCrash(root).system.processName should] equal:system[@KSCrashField_ProcessName]];
            });
            
            it(@"Should decode process ID", ^{
                [[theValue(decodedCrash(root).system.processId) should] equal:system[@KSCrashField_ProcessID]];
            });
            
            it(@"Should decode parent process ID", ^{
                [[theValue(decodedCrash(root).system.parentProcessId) should] equal:system[@KSCrashField_ParentProcessID]];
            });
            
            it(@"Should decode storage", ^{
                [[theValue(decodedCrash(root).system.storage) should] equal:system[@KSCrashField_Storage]];
            });
            
            it(@"Should decode build type", ^{
                system[@KSCrashField_BuildType] = @"debug";
                [[theValue(decodedCrash(root).system.buildType) should] equal:theValue(AMABuildTypeDebug)];
            });
            
            context(@"Should decode memory", ^{
               
                NSDictionary *__block memory = nil;
                
                beforeEach(^{
                    memory = system[@KSCrashField_Memory];
                });
            
                it(@"Should decode size", ^{
                    [[theValue(decodedCrash(root).system.memory.size) should] equal:memory[@KSCrashField_Size]];
                });
                
                it(@"Should decode usable", ^{
                    [[theValue(decodedCrash(root).system.memory.usable) should] equal:memory[@KSCrashField_Usable]];
                });
                
                it(@"Should decode free", ^{
                    [[theValue(decodedCrash(root).system.memory.free) should] equal:memory[@KSCrashField_Free]];
                });
            });
            
            context(@"Should decode application statistics", ^{
                
                NSDictionary *__block appStats = nil;
                
                beforeEach(^{
                    appStats = system[@KSCrashField_AppStats];
                });
                
                it(@"Should decode application active", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.applicationActive) should]
                        equal:appStats[@KSCrashField_AppActive]];
                });
                
                it(@"Should decode application in foreground", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.applicationInForeground) should]
                        equal:appStats[@KSCrashField_AppInFG]];
                });
                
                it(@"Should decode launches since last crash", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.launchesSinceLastCrash) should]
                        equal:appStats[@KSCrashField_LaunchesSinceCrash]];
                });
                
                it(@"Should decode sessions since last crash", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.sessionsSinceLastCrash) should]
                        equal:appStats[@KSCrashField_SessionsSinceCrash]];
                });
                
                it(@"Should decode active time since last crash", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.activeTimeSinceLastCrash) should]
                        equal:appStats[@KSCrashField_ActiveTimeSinceCrash]];
                });
                
                it(@"Should decode background time since last crash", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.backgroundTimeSinceLastCrash) should]
                        equal:appStats[@KSCrashField_BGTimeSinceCrash]];
                });
                
                it(@"Should decode sessions since launch", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.sessionsSinceLaunch) should]
                        equal:appStats[@KSCrashField_SessionsSinceLaunch]];
                });
                
                it(@"Should decode active time since launch", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.activeTimeSinceLaunch) should]
                        equal:appStats[@KSCrashField_ActiveTimeSinceLaunch]];
                });
                
                it(@"Should decode background time since launch", ^{
                    [[theValue(decodedCrash(root).system.applicationStats.backgroundTimeSinceLaunch) should]
                        equal:appStats[@KSCrashField_BGTimeSinceLaunch]];
                });
            });
        });
        
        context(@"Should decode crash", ^{
            
            NSMutableDictionary *__block crash = nil;
            
            beforeEach(^{
                crash = root[@KSCrashField_Crash];
            });
            
            context(@"Should decode error", ^{
               
                NSMutableDictionary *__block error = nil;
                
                beforeEach(^{
                    error = crash[@KSCrashField_Error];
                });
                
                it(@"Should decode address", ^{
                    [[theValue(decodedCrash(root).crash.error.address) should] equal:error[@KSCrashField_Address]];
                });
                
                it(@"Should decode reason", ^{
                    [[decodedCrash(root).crash.error.reason should] equal:error[@KSCrashField_Reason]];
                });
                
                it(@"Should decode type", ^{
                    error[@KSCrashField_Type] = @"mach";
                    [[theValue(decodedCrash(root).crash.error.type) should] equal:theValue(AMACrashTypeMachException)];
                });
                
                context(@"Should decode mach exception", ^{
                    
                    NSDictionary *__block mach = nil;
                    
                    beforeEach(^{
                        mach = error[@KSCrashField_Mach];
                    });
                    
                    it(@"Should decode exception type", ^{
                        [[theValue(decodedCrash(root).crash.error.mach.exceptionType) should] equal:mach[@KSCrashField_Exception]];
                    });
                    
                    it(@"Should decode code", ^{
                        [[theValue(decodedCrash(root).crash.error.mach.code) should] equal:mach[@KSCrashField_Code]];
                    });
                    
                    it(@"Should decode subcode", ^{
                        [[theValue(decodedCrash(root).crash.error.mach.subcode) should] equal:mach[@KSCrashField_Subcode]];
                    });
                });
                
                context(@"Should decode signal", ^{
                    
                    NSMutableDictionary *__block signal = nil;
                    
                    beforeEach(^{
                        signal = error[@KSCrashField_Signal];
                    });
                    
                    it(@"Should decode signal", ^{
                        [[theValue(decodedCrash(root).crash.error.signal.signal) should] equal:signal[@KSCrashField_Signal]];
                    });
                    
                    it(@"Should decode signal as 0 if signal not exists", ^{
                        [signal removeObjectForKey:@KSCrashField_Signal];
                        [[theValue(decodedCrash(root).crash.error.signal.signal) should] equal:theValue(0)];
                    });
                    
                    it(@"Should decode code", ^{
                        [[theValue(decodedCrash(root).crash.error.signal.code) should] equal:signal[@KSCrashField_Code]];
                    });
                });
                
                context(@"Should decode NSExeption", ^{
                    
                    NSDictionary *__block nsException = nil;
                    
                    beforeEach(^{
                        nsException = error[@KSCrashExcType_NSException];
                    });
                    
                    it(@"Should decode name", ^{
                        [[decodedCrash(root).crash.error.nsException.name should] equal:nsException[@KSCrashField_Name]];
                    });
                    
                    it(@"Should decode user info", ^{
                        [[decodedCrash(root).crash.error.nsException.userInfo should] equal:nsException[@KSCrashField_UserInfo]];
                    });
                });
                
                it(@"Should decode C++ exception", ^{
                    [[decodedCrash(root).crash.error.cppException.name should] equal:error[@KSCrashField_CPPException][@KSCrashField_Name]];
                });
            });
            
            context(@"ANR report handling", ^{
                
                NSDictionary *__block anrError = nil;
                
                beforeEach(^{
                    NSString *path = [AMAModuleBundleProvider.moduleBundle pathForResource:kANRErrorFileName ofType:@"plist"];
                    anrError = [[NSDictionary alloc] initWithContentsOfFile:path];
                    crash[@KSCrashField_Error] = anrError;
                    SEL callbackSelector = @selector(crashReportDecoder:didDecodeANR:withError:);
                    decodedCrashSpy = [delegateMock captureArgument:callbackSelector atIndex:1];
                });
                
                it(@"Should change crash type to MAIN_THREAD_DEADLOCK", ^{
                    AMACrashType type = decodedCrash(root).crash.error.type;
                    [[theValue(type) should] equal:theValue(AMACrashTypeMainThreadDeadlock)];
                });
                
                it(@"Should change crashed thread to main", ^{
                    NSUInteger index = [decodedCrash(root).crash.threads indexOfObjectPassingTest:
                                            ^BOOL(AMAThread *obj, NSUInteger idx, BOOL *stop) {
                                                return obj.crashed;
                                            }];
                    [[theValue(decodedCrash(root).crash.threads[index].index) should] equal:@0];
                });
            });
            
            context(@"Should decode threads", ^{
                
                NSArray *__block threads = nil;
                
                beforeEach(^{
                    threads = crash[@KSCrashField_Threads];
                });
                
                it(@"Should decode all threads", ^{
                    [[[decodedCrash(root).crash should] have:threads.count] threads];
                });
                
                context(@"Should decode thread", ^{
                   
                    NSDictionary *__block thread = nil;
                    
                    beforeEach(^{
                        thread = threads.firstObject;
                    });
                    
                    it(@"Should decode index", ^{
                        [[theValue(decodedCrash(root).crash.threads.firstObject.index) should]
                            equal:thread[@KSCrashField_Index]];
                    });
                    
                    it(@"Should decode crashed", ^{
                        [[theValue(decodedCrash(root).crash.threads.firstObject.crashed) should]
                            equal:thread[@KSCrashField_Crashed]];
                    });
                    
                    context(@"Should decode backtrace", ^{
                        
                        NSArray *__block frames = nil;
                        
                        beforeEach(^{
                            frames = thread[@KSCrashField_Backtrace][@KSCrashField_Contents];
                        });
                        
                        it(@"Should decode all frames", ^{
                            [[[decodedCrash(root).crash.threads.firstObject.backtrace should] have:frames.count] frames];
                        });
                        
                        context(@"Should decode frames", ^{
                            
                            NSDictionary *__block firstFrame = nil;
                            NSDictionary *__block secondFrame = nil;
                            
                            beforeEach(^{
                                firstFrame = frames.firstObject;
                                secondFrame = frames.lastObject;
                            });
                            
                            it(@"Should decode instruction address", ^{
                                AMABacktraceFrame *backtraceFrame =
                                    decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.instructionAddress should] equal:firstFrame[@KSCrashField_InstructionAddr]];
                            });
                            
                            it(@"Should decode object name", ^{
                                AMABacktraceFrame *backtraceFrame =
                                    decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.objectName should] equal:firstFrame[@KSCrashField_ObjectName]];
                            });
                            
                            it(@"Should decode object address", ^{
                                AMABacktraceFrame *backtraceFrame =
                                    decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.objectAddress should] equal:firstFrame[@KSCrashField_ObjectAddr]];
                            });
                            
                            it(@"Should decode object address", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.objectAddress should] equal:firstFrame[@KSCrashField_ObjectAddr]];
                            });
                            
                            it(@"Should decode symbol name", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.symbolName should] equal:firstFrame[@KSCrashField_SymbolName]];
                            });
                            
                            it(@"Should decode symbol address", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.symbolAddress should] equal:firstFrame[@KSCrashField_SymbolAddr]];
                            });
                            
                            it(@"Should decode line of code", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[backtraceFrame.lineOfCode should] equal:firstFrame[@KSCrashField_LineOfCode]];
                            });
                            
                            it(@"The first frame should not be stripped", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.firstObject;
                                [[theValue(backtraceFrame.stripped) should] beNo];
                            });
                            
                            it(@"The second frame should be stripped", ^{
                                AMABacktraceFrame *backtraceFrame =
                                decodedCrash(root).crash.threads.firstObject.backtrace.frames.lastObject;
                                [[theValue(backtraceFrame.stripped) should] beYes];
                            });
                        });
                    });
                    
                    context(@"Should decode registers", ^{
                        
                        NSDictionary *__block basicRegisters = nil;
                        NSDictionary *__block exceptionRegisters = nil;
                        
                        beforeEach(^{
                            basicRegisters = thread[@KSCrashField_Registers][@KSCrashField_Basic];
                            exceptionRegisters = thread[@KSCrashField_Registers][@KSCrashField_Exception];
                        });
                        
                        it(@"Should decode all basic registers", ^{
                            NSMutableArray<AMARegister *> *expectedBasic = [NSMutableArray array];
                            
                            [basicRegisters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                                AMARegister *reg = [[AMARegister alloc] initWithName:key value:[obj unsignedLongLongValue]];
                                [expectedBasic addObject:reg];
                            }];
                            
                            NSArray *basicArray = decodedCrash(root).crash.threads.firstObject.registers.basic;
                            [[expectedBasic should] containObjectsInArray:basicArray];
                        });
                        
                        it(@"Should decode all exception registers", ^{
                            NSMutableArray<AMARegister *> *expectedException = [NSMutableArray array];
                            
                            [exceptionRegisters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                                AMARegister *reg = [[AMARegister alloc] initWithName:key value:[obj unsignedLongLongValue]];
                                [expectedException addObject:reg];
                            }];
                            
                            NSArray *exceptionArray = decodedCrash(root).crash.threads.firstObject.registers.exception;
                            [[expectedException should] containObjectsInArray:exceptionArray];
                        });
                    });
                    
                    context(@"Should decode stack", ^{
                       
                        NSDictionary *__block stackDict = nil;
                        
                        beforeEach(^{
                            stackDict = thread[@KSCrashField_Stack];
                        });
                        
                        it(@"Should decode grow direction", ^{
                            AMAGrowDirection expectedGrowth = AMAGrowDirectionMinus;
                            
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            [[theValue(stack.growDirection) should] equal:theValue(expectedGrowth)];
                        });
                        
                        it(@"Should decode dump start", ^{
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            [[theValue(stack.dumpStart) should] equal:stackDict[@KSCrashField_DumpStart]];
                        });
                        
                        it(@"Should decode dump end", ^{
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            [[theValue(stack.dumpEnd) should] equal:stackDict[@KSCrashField_DumpEnd]];
                        });
                        
                        it(@"Should decode stack pointer", ^{
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            [[theValue(stack.stackPointer) should] equal:stackDict[@KSCrashField_StackPtr]];
                        });
                        
                        it(@"Should decode overflow", ^{
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            [[theValue(stack.overflow) should] equal:stackDict[@KSCrashField_Overflow]];
                        });
                        
                        it(@"Should decode contents", ^{
                            AMAStack *stack = decodedCrash(root).crash.threads.firstObject.stack;
                            const char *bytes = stack.contents.bytes;
                            NSMutableString *stackString = [NSMutableString string];
                            for (NSUInteger i = 0; i < stack.contents.length; i++) {
                                [stackString appendFormat:@"%02.2hhX", bytes[i]];
                            }
                            [[stackString should] equal:stackDict[@KSCrashField_Contents]];
                        });
                    });
                });
            });
        });
    });
});

SPEC_END
