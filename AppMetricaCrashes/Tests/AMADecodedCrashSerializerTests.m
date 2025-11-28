#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMADecodedCrashSerializer.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import "AMAApplicationStatistics.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMABinaryImage.h"
#import "AMACppException.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashValidator.h"
#import "AMAErrorCustomData.h"
#import "AMAErrorModel.h"
#import "AMAErrorNSErrorData.h"
#import "AMAInfo.h"
#import "AMAMach.h"
#import "AMAMemory.h"
#import "AMANSException.h"
#import "AMANonFatal.h"
#import "AMARegister.h"
#import "AMARegistersContainer.h"
#import "AMASignal.h"
#import "AMAStack.h"
#import "AMASystem.h"
#import "AMAThread.h"
#import "AMAVirtualMachineCrash.h"
#import "AMAVirtualMachineError.h"
#import "AMAVirtualMachineInfo.h"
#import "Crash.pb-c.h"
#import "AMABuildUID.h"

SPEC_BEGIN(AMADecodedCrashSerializerTests)

describe(@"AMADecodedCrashSerializer", ^{

    AMAVirtualMachineInfo *const virtualMachineInfo = [[AMAVirtualMachineInfo alloc]
        initWithPlatform:@"flutter"
                 version:@"1.3.5"
             environment:@{ @"some key" : @"some value", @"another key" : @"another value" }];

    AMAInfo *const info = [[AMAInfo alloc] initWithVersion:@"1.2.3"
                                                identifier:@"Test id" timestamp:[NSDate date]
                                        virtualMachineInfo:virtualMachineInfo];

    AMABinaryImage *const binaryImage = [[AMABinaryImage alloc] initWithName:@"Image name"
                                                                        UUID:@"1234-abcd-456-efgh"
                                                                     address:123456789
                                                                        size:123
                                                                   vmAddress:123456788
                                                                     cpuType:12
                                                                  cpuSubtype:0
                                                                majorVersion:1
                                                                minorVersion:2
                                                             revisionVersion:3
                                                            crashInfoMessage:@"Crash Info Message"
                                                           crashInfoMessage2:@"Crash Info Sub Message"];

    AMAMemory *const memory = [[AMAMemory alloc] initWithSize:1245 usable:245 free:1000];

    AMAApplicationStatistics *const appStats = [[AMAApplicationStatistics alloc] initWithApplicationActive:YES
                                                                                   applicationInForeground:NO
                                                                                    launchesSinceLastCrash:1
                                                                                    sessionsSinceLastCrash:2
                                                                                  activeTimeSinceLastCrash:1234
                                                                              backgroundTimeSinceLastCrash:6
                                                                                       sessionsSinceLaunch:7
                                                                                     activeTimeSinceLaunch:6543
                                                                                 backgroundTimeSinceLaunch:3];

    AMASystem *const system = [[AMASystem alloc] initWithKernelVersion:@"XNU"
                                                         osBuildNumber:@"1234"
                                                         bootTimestamp:[NSDate date]
                                                     appStartTimestamp:[NSDate dateWithTimeIntervalSinceNow:2]
                                                        executablePath:@"/path/to/executable"
                                                               cpuArch:@"arm64"
                                                               cpuType:12
                                                            cpuSubtype:0
                                                         binaryCpuType:13
                                                      binaryCpuSubtype:0
                                                           processName:@"Process name"
                                                             processId:123
                                                       parentProcessId:122
                                                             buildType:AMABuildTypeAppStore
                                                               storage:345678956
                                                                memory:memory
                                                      applicationStats:appStats];

    AMAMach *const mach = [[AMAMach alloc] initWithExceptionType:1 code:2 subcode:3];

    AMASignal *const signal = [[AMASignal alloc] initWithSignal:1 code:2];

    AMANSException *const excpetion = [[AMANSException alloc] initWithName:@"NSSomethingWentWrong"
                                                                  userInfo:@"Something went wrong"];

    AMACppException *const cppException = [[AMACppException alloc] initWithName:@"C++ did fail too"];

    AMAVirtualMachineCrash *const virtualMachineCrash = [[AMAVirtualMachineCrash alloc] initWithClassName:@"AMADecodedCrashSerializer"
                                                                                                  message:@"Unexpected nil"];

    AMABacktraceFrame *const backtraceFrame = [[AMABacktraceFrame alloc] initWithLineOfCode:@12
                                                                         instructionAddress:@12345
                                                                              symbolAddress:@123456
                                                                              objectAddress:@124
                                                                                 symbolName:@"__symbol"
                                                                                 objectName:@"__object"
                                                                                   stripped:NO
                                                                               columnOfCode:@88
                                                                                  className:@"AMAMetricaConfiguration"
                                                                                 methodName:@"activate"
                                                                             sourceFileName:@"AMAMetricaConfiguration.m"];

    AMABacktrace *const backtrace = [[AMABacktrace alloc] initWithFrames:[@[ backtraceFrame ] mutableCopy]];

    AMAErrorCustomData *const nonFatalCustomData = [[AMAErrorCustomData alloc] initWithIdentifier:@"com.custom"
                                                                                          message:@"Non Fatal"
                                                                                        className:@"AMAMyError"];

    AMAErrorNSErrorData *const nonFatalNSErrorData = [[AMAErrorNSErrorData alloc] initWithDomain:@"com.ns.error"
                                                                                            code:42];
    AMAVirtualMachineError *virtualMachineError = [[AMAVirtualMachineError alloc] initWithClassName:@"AMAAppMetrica"
                                                                                            message:@"my message"];

    AMAErrorModel *const errorModel = [[AMAErrorModel alloc] initWithType:AMAErrorModelTypeNSError
                                                               customData:nonFatalCustomData
                                                              nsErrorData:nonFatalNSErrorData
                                                         parametersString:@"{\"foo\":\"bar\"}"
                                                      reportCallBacktrace:nil
                                                    userProvidedBacktrace:nil
                                                      virtualMachineError:virtualMachineError
                                                          underlyingError:nil
                                                           bytesTruncated:0];

    AMANonFatal *const nonFatal = [[AMANonFatal alloc] initWithModel:errorModel
                                                           backtrace:backtrace];
     
    AMACrashReportError *const crashError = [[AMACrashReportError alloc] initWithAddress:1234
                                                                                  reason:@"Something went wrong"
                                                                                    type:AMACrashTypeNsException
                                                                                    mach:mach
                                                                                  signal:signal
                                                                             nsexception:excpetion
                                                                            cppException:cppException
                                                                          nonFatalsChain:@[ nonFatal ]
                                                                     virtualMachineCrash:virtualMachineCrash];

    AMARegister *const ax = [[AMARegister alloc] initWithName:@"ax" value:12345678];
    AMARegister *const bx = [[AMARegister alloc] initWithName:@"bx" value:987654321];
    AMARegister *const cx = [[AMARegister alloc] initWithName:@"cx" value:654345675];
    AMARegister *const dx = [[AMARegister alloc] initWithName:@"dx" value:6545676878];

    AMARegistersContainer *const registers = [[AMARegistersContainer alloc] initWithBasic:@[ ax, bx ]
                                                                                exception:@[ cx, dx ]];

    AMAStack *const stack = [[AMAStack alloc] initWithGrowDirection:AMAGrowDirectionPlus
                                                          dumpStart:654545434
                                                            dumpEnd:5434345689
                                                       stackPointer:57898765
                                                           overflow:NO
                                                           contents:[@"0123456789ABCDEF"
                                                               dataUsingEncoding:NSUTF8StringEncoding]];

    AMAThread *const thread = [[AMAThread alloc] initWithBacktrace:backtrace
                                                         registers:registers
                                                             stack:stack
                                                             index:1
                                                           crashed:YES
                                                        threadName:@"thread_name"
                                                         queueName:@"queue_name"];

    AMACrashReportCrash *const crash = [[AMACrashReportCrash alloc] initWithError:crashError
                                                                    threads:@[ thread ]];

    AMAApplicationState *const appState = [[AMAApplicationState alloc] initWithAppVersionName:@"1.0.0"
                                                                        appDebuggable:NO
                                                                           kitVersion:@"2.0.0"
                                                                       kitVersionName:@"SampleKit"
                                                                       kitBuildNumber:100
                                                                         kitBuildType:@"Debug"
                                                                            OSVersion:@"15.0"
                                                                           OSAPILevel:30
                                                                               locale:@"en_US"
                                                                             isRooted:NO
                                                                                 UUID:[[NSUUID UUID] UUIDString]
                                                                             deviceID:@"SampleDeviceID"
                                                                                  IFV:@"SampleIFV"
                                                                                  IFA:@"SampleIFA"
                                                                                  LAT:NO
                                                                       appBuildNumber:@"100"];

    AMABuildUID *const appBuildUID = [[AMABuildUID alloc] initWithString:@"SampleBuildUIDString"];

    NSDictionary *const errorEnvironment = @{
        @"errorKey1": @"errorValue1",
        @"errorKey2": @"errorValue2"
    };

    NSDictionary *const appEnvironment = @{
        @"appKey1": @"appValue1",
        @"appKey2": @"appValue2"
    };

    AMADecodedCrash *const decodedCrash = [[AMADecodedCrash alloc] initWithAppState:appState
                                                                        appBuildUID:appBuildUID
                                                                   errorEnvironment:errorEnvironment
                                                                     appEnvironment:appEnvironment
                                                                               info:info
                                                                       binaryImages:@[ binaryImage ]
                                                                             system:system
                                                                              crash:crash];

    __block Ama__IOSCrashReport * report = NULL;
    __block NSError *error = NULL;

    __auto_type reportMessage = ^NSData *(AMADecodedCrash *crash) {
        AMADecodedCrashSerializer *serializer = [[AMADecodedCrashSerializer alloc] init];
        error = nil;
        NSData *data = [serializer dataForCrash:crash error:&error];
        report = ama__ioscrash_report__unpack(NULL, data.length, data.bytes);
        return data;
    };

    afterEach(^{
        if (report != NULL) {
            ama__ioscrash_report__free_unpacked(report, NULL);
        }
    });

    context(@"Report serialization", ^{

        context(@"Info serialization", ^{

            it(@"Should serialize version", ^{
                reportMessage(decodedCrash);
                NSString *version = [AMAProtobufUtilities stringForBinaryData:&report->info->version];
                [[version should] equal:info.version];
            });

            it(@"Should serialize id", ^{
                reportMessage(decodedCrash);
                NSString *idValue = [AMAProtobufUtilities stringForBinaryData:&report->info->id];
                [[idValue should] equal:info.identifier];
            });

            it(@"Should serialize timestamp", ^{
                reportMessage(decodedCrash);
                NSTimeInterval timestamp = [info.timestamp timeIntervalSince1970];
                [[theValue(report->info->timestamp) should] equal:timestamp withDelta:0.1];
            });

            context(@"Virtual machine info", ^{
                beforeEach(^{
                    reportMessage(decodedCrash);
                });
                it(@"Should serialize platform", ^{
                    NSString *virtualMachine = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->virtual_machine];
                    [[virtualMachine should] equal:info.virtualMachineInfo.platform];
                });
                it(@"Should serialize virtual machine version", ^{
                    NSString *virtualMachineVersion = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->virtual_machine_version];
                    [[virtualMachineVersion should] equal:info.virtualMachineInfo.virtualMachineVersion];
                });
                it(@"Should serialize environment", ^{
                    [[theValue(report->info->virtual_machine_info->n_plugin_environment) should] equal:theValue(info.virtualMachineInfo.environment.count)];
                    NSString *key1 = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->plugin_environment[0]->key];
                    NSString *value1 = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->plugin_environment[0]->value];
                    NSString *key2 = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->plugin_environment[1]->key];
                    NSString *value2 = [AMAProtobufUtilities stringForBinaryData:&report->info->virtual_machine_info->plugin_environment[1]->value];
                    NSDictionary *actualMap = @{ key1 : value1, key2 : value2 };
                    [[actualMap should] equal:info.virtualMachineInfo.environment];
                });
            });

            context(@"Nullable fields", ^{
                AMAInfo *const nullableInfo = [[AMAInfo alloc] initWithVersion:nil
                                                                    identifier:@"id"
                                                                     timestamp:[NSDate date]
                                                            virtualMachineInfo:nil];
                AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                    appBuildUID:nil
                                                                               errorEnvironment:nil
                                                                                 appEnvironment:nil
                                                                                           info:nullableInfo
                                                                                   binaryImages:@[ binaryImage ]
                                                                                         system:system
                                                                                          crash:crash];
                beforeEach(^{
                    reportMessage(nullableDecodedCrash);
                });
                it(@"Should not have version", ^{
                    [[theValue(report->info->has_version) should] beNo];
                    NSString *actualVersion = [AMAProtobufUtilities stringForBinaryData:&report->info->version];
                    [[theValue(actualVersion.length) should] beZero];
                });
                it(@"Should not have virtual machine info", ^{
                    [[theValue(report->info->virtual_machine_info == NULL) should] beYes];
                });
            });
        });

        context(@"Binary image serialization", ^{

            it(@"Should serialize all binary images", ^{
                reportMessage(decodedCrash);
                [[theValue(report->n_binary_images) should] equal:theValue(decodedCrash.binaryImages.count)];
            });

            it(@"Should serialize address", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->address) should] equal:theValue(binaryImage.address)];
            });

            it(@"Should serialize size", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->size) should] equal:theValue(binaryImage.size)];
            });

            it(@"Should serialize cpu type", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->cpu_type) should] equal:theValue(binaryImage.cpuType)];
            });

            it(@"Should serialize cpu subtype", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->cpu_subtype) should] equal:theValue(binaryImage.cpuSubtype)];
            });

            it(@"Should serialize major version", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->major_version) should] equal:theValue(binaryImage.majorVersion)];
            });

            it(@"Should serialize minor version", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->minor_version) should] equal:theValue(binaryImage.minorVersion)];
            });

            it(@"Should serialize revision version", ^{
                reportMessage(decodedCrash);
                [[theValue(report->binary_images[0]->revision_version) should] equal:theValue(
                    binaryImage.revisionVersion)];
            });

            it(@"Should serialize path", ^{
                reportMessage(decodedCrash);
                NSString *path = [AMAProtobufUtilities stringForBinaryData:&report->binary_images[0]->path];
                [[path should] equal:binaryImage.name];
            });

            it(@"Should serialize UUID", ^{
                reportMessage(decodedCrash);
                NSString *uuid = [AMAProtobufUtilities stringForBinaryData:&report->binary_images[0]->uuid];
                [[uuid should] equal:binaryImage.UUID];
            });

            it(@"Should serialize crash info message", ^{
                reportMessage(decodedCrash);
                NSString *message =
                    [AMAProtobufUtilities stringForBinaryData:&report->binary_images[0]->crash_info_message];
                [[message should] equal:binaryImage.crashInfoMessage];
            });

            it(@"Should serialize crash info sub message", ^{
                reportMessage(decodedCrash);
                NSString *message =
                    [AMAProtobufUtilities stringForBinaryData:&report->binary_images[0]->crash_info_message2];
                [[message should] equal:binaryImage.crashInfoMessage2];
            });
        });

        context(@"System serialization", ^{

            it(@"Should serialize kernel version", ^{
                reportMessage(decodedCrash);
                NSString *kernelVersion = [AMAProtobufUtilities stringForBinaryData:&report->system->kernel_version];
                [[kernelVersion should] equal:system.kernelVersion];
                [[theValue(report->system->has_kernel_version) should] beYes];
            });

            it(@"Should serialize OS build number", ^{
                reportMessage(decodedCrash);
                NSString *osBuildNumber = [AMAProtobufUtilities stringForBinaryData:&report->system->os_build_number];
                [[osBuildNumber should] equal:system.osBuildNumber];
                [[theValue(report->system->has_os_build_number) should] beYes];
            });

            it(@"Should serialize boot timestamp", ^{
                reportMessage(decodedCrash);
                NSTimeInterval timestamp = [system.bootTimestamp timeIntervalSince1970];
                [[theValue(report->system->boot_timestamp) should] equal:timestamp withDelta:0.1];
                [[theValue(report->system->has_boot_timestamp) should] beYes];
            });

            it(@"Should serialize app start timestamp", ^{
                reportMessage(decodedCrash);
                NSTimeInterval timestamp = [system.appStartTimestamp timeIntervalSince1970];
                [[theValue(report->system->app_start_timestamp) should] equal:timestamp withDelta:0.1];
                [[theValue(report->system->has_app_start_timestamp) should] beYes];
            });

            it(@"Should serialize executable path", ^{
                reportMessage(decodedCrash);
                NSString *executablePath = [AMAProtobufUtilities stringForBinaryData:&report->system->executable_path];
                [[executablePath should] equal:system.executablePath];
                [[theValue(report->system->has_executable_path) should] beYes];
            });

            it(@"Should serialize CPU arch", ^{
                reportMessage(decodedCrash);
                NSString *cpuArch = [AMAProtobufUtilities stringForBinaryData:&report->system->cpu_arch];
                [[cpuArch should] equal:system.cpuArch];
                [[theValue(report->system->has_cpu_arch) should] beYes];
            });

            it(@"Should serialize CPU type", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->cpu_type) should] equal:theValue(system.cpuType)];
                [[theValue(report->system->has_cpu_type) should] beYes];
            });

            it(@"Should serialize CPU subtype", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->cpu_subtype) should] equal:theValue(system.cpuSubtype)];
                [[theValue(report->system->has_cpu_subtype) should] beYes];
            });

            it(@"Should serialize binary CPU type", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->binary_cpu_type) should] equal:theValue(system.binaryCpuType)];
                [[theValue(report->system->has_binary_cpu_type) should] beYes];
            });

            it(@"Should serialize binary CPU subtype", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->binary_cpu_subtype) should] equal:theValue(system.binaryCpuSubtype)];
                [[theValue(report->system->has_binary_cpu_subtype) should] beYes];
            });

            it(@"Should serialize process name", ^{
                reportMessage(decodedCrash);
                NSString *processName = [AMAProtobufUtilities stringForBinaryData:&report->system->process_name];
                [[processName should] equal:system.processName];
                [[theValue(report->system->has_process_name) should] beYes];
            });

            it(@"Should serialize process ID", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->process_id) should] equal:theValue(system.processId)];
                [[theValue(report->system->has_process_id) should] beYes];
            });

            it(@"Should serialize parent process ID", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->parent_process_id) should] equal:theValue(system.parentProcessId)];
                [[theValue(report->system->has_parent_process_id) should] beYes];
            });

            it(@"Should serialize build type", ^{
                reportMessage(decodedCrash);
                Ama__IOSCrashReport__System__BuildType expected = AMA__IOSCRASH_REPORT__SYSTEM__BUILD_TYPE__APP_STORE;
                [[theValue(report->system->build_type) should] equal:theValue(expected)];
                [[theValue(report->system->has_build_type) should] beYes];
            });

            it(@"Should serialize storage type", ^{
                reportMessage(decodedCrash);
                [[theValue(report->system->storage) should] equal:theValue(system.storage)];
                [[theValue(report->system->has_storage) should] beYes];
            });

            context(@"Memory serialization", ^{

                it(@"Should serialize size", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->memory->size) should] equal:theValue(memory.size)];
                });

                it(@"Should serialize usable", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->memory->usable) should] equal:theValue(memory.usable)];
                });

                it(@"Should serialize free", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->memory->free) should] equal:theValue(memory.free)];
                });
            });

            context(@"Application statistics serialization", ^{

                it(@"Should serialize application active", ^{
                    reportMessage(decodedCrash);
                    [[theValue((BOOL)report->system->application_stats->application_active) should]
                        equal:theValue(appStats.applicationActive)];
                });

                it(@"Should serialize application in foreground", ^{
                    reportMessage(decodedCrash);
                    [[theValue((BOOL)report->system->application_stats->application_in_foreground) should]
                        equal:theValue(appStats.applicationInForeground)];
                });

                it(@"Should serialize launches since last crash", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->launches_since_last_crash) should]
                        equal:theValue(appStats.launchesSinceLastCrash)];
                });

                it(@"Should serialize sessions since last crash", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->sessions_since_last_crash) should]
                        equal:theValue(appStats.sessionsSinceLastCrash)];
                });

                it(@"Should serialize active time since last crash", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->active_time_since_last_crash) should]
                        equal:theValue(appStats.activeTimeSinceLastCrash)];
                });

                it(@"Should serialize active time since last crash", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->active_time_since_last_crash) should]
                        equal:theValue(appStats.activeTimeSinceLastCrash)];
                });

                it(@"Should serialize sessions since launch", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->sessions_since_launch) should]
                        equal:theValue(appStats.sessionsSinceLaunch)];
                });

                it(@"Should serialize active time since launch", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->active_time_since_launch) should]
                        equal:theValue(appStats.activeTimeSinceLaunch)];
                });

                it(@"Should serialize background time since launch", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->system->application_stats->background_time_since_launch) should]
                        equal:theValue(appStats.backgroundTimeSinceLaunch)];
                });
            });
        });

        context(@"System serialization", ^{

            AMADecodedCrash *__block nullableDecodedCrash = nil;
            beforeEach(^{
                nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                     appBuildUID:nil
                                                                errorEnvironment:nil
                                                                  appEnvironment:nil
                                                                            info:info
                                                                    binaryImages:@[ binaryImage ]
                                                                          system:[AMASystem nullMock]
                                                                           crash:crash];
            });

            it(@"Should not serialize kernel version", ^{
                reportMessage(nullableDecodedCrash);
                NSString *kernelVersion = [AMAProtobufUtilities stringForBinaryData:&report->system->kernel_version];
                [[theValue(kernelVersion.length) should] beZero];
                [[theValue(report->system->has_kernel_version) should] beNo];
            });

            it(@"Should not serialize OS build number", ^{
                reportMessage(nullableDecodedCrash);
                NSString *osBuildNumber = [AMAProtobufUtilities stringForBinaryData:&report->system->os_build_number];
                [[theValue(osBuildNumber.length) should] beZero];
                [[theValue(report->system->has_os_build_number) should] beNo];
            });

            it(@"Should serialize boot timestamp", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->boot_timestamp) should] beZero];
                [[theValue(report->system->has_boot_timestamp) should] beYes];
            });

            it(@"Should serialize app start timestamp", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->app_start_timestamp) should] beZero];
                [[theValue(report->system->has_app_start_timestamp) should] beYes];
            });

            it(@"Should not serialize executable path", ^{
                reportMessage(nullableDecodedCrash);
                NSString *executablePath = [AMAProtobufUtilities stringForBinaryData:&report->system->executable_path];
                [[theValue(executablePath.length) should] beZero];
                [[theValue(report->system->has_executable_path) should] beNo];
            });

            it(@"Should not serialize CPU arch", ^{
                reportMessage(nullableDecodedCrash);
                NSString *cpuArch = [AMAProtobufUtilities stringForBinaryData:&report->system->cpu_arch];
                [[theValue(cpuArch.length) should] beZero];
                [[theValue(report->system->has_cpu_arch) should] beNo];
            });

            it(@"Should serialize CPU type", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->cpu_type) should] beZero];
                [[theValue(report->system->has_cpu_type) should] beYes];
            });

            it(@"Should serialize CPU subtype", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->cpu_subtype) should] beZero];
                [[theValue(report->system->has_cpu_subtype) should] beYes];
            });

            it(@"Should serialize binary CPU type", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->binary_cpu_type) should] beZero];
                [[theValue(report->system->has_binary_cpu_type) should] beYes];
            });

            it(@"Should serialize binary CPU subtype", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->binary_cpu_subtype) should] beZero];
                [[theValue(report->system->has_binary_cpu_subtype) should] beYes];
            });

            it(@"Should not serialize process name", ^{
                reportMessage(nullableDecodedCrash);
                NSString *processName = [AMAProtobufUtilities stringForBinaryData:&report->system->process_name];
                [[theValue(processName.length) should] beZero];
                [[theValue(report->system->has_process_name) should] beNo];
            });

            it(@"Should serialize process ID", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->process_id) should] beZero];
                [[theValue(report->system->has_process_id) should] beYes];
            });

            it(@"Should serialize parent process ID", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->parent_process_id) should] beZero];
                [[theValue(report->system->has_parent_process_id) should] beYes];
            });

            it(@"Should serialize build type", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->build_type) should] beZero];
                [[theValue(report->system->has_build_type) should] beYes];
            });

            it(@"Should serialize storage type", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->storage) should] beZero];
                [[theValue(report->system->has_storage) should] beYes];
            });

            it (@"Should not serialize memory", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->memory == NULL) should] beYes];
            });

            it (@"Should not serialize app stats", ^{
                reportMessage(nullableDecodedCrash);
                [[theValue(report->system->application_stats == NULL) should] beYes];
            });
        });

        context(@"Crash serialization", ^{

            context(@"Error serialization", ^{

                context(@"Types", ^{

                    __auto_type createCrashWithType = ^AMADecodedCrash *(AMACrashType type) {
                        AMACrashReportError *crashErrorWithType = [[AMACrashReportError alloc] initWithAddress:12
                                                                                                        reason:@"reason"
                                                                                                          type:type
                                                                                                          mach:mach
                                                                                                        signal:signal
                                                                                                   nsexception:nil
                                                                                                  cppException:cppException
                                                                                                nonFatalsChain:@[ nonFatal ]
                                                                                           virtualMachineCrash:virtualMachineCrash];
                        AMACrashReportCrash *const crashWithType = [[AMACrashReportCrash alloc] initWithError:crashErrorWithType
                                                                                                      threads:@[ thread ]];

                        return [[AMADecodedCrash alloc] initWithAppState:nil
                                                             appBuildUID:nil
                                                        errorEnvironment:nil
                                                          appEnvironment:nil
                                                                    info:info
                                                            binaryImages:@[ binaryImage ]
                                                                  system:system
                                                                   crash:crashWithType];
                    };
                    it(@"Should convert AMACrashTypeMachException", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeMachException);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__MACH_EXCEPTION)];
                    });
                    it(@"Should convert AMACrashTypeSignal", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeSignal);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__SIGNAL)];
                    });
                    it(@"Should convert AMACrashTypeCppException", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeCppException);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__CPP_EXCEPTION)];
                    });
                    it(@"Should convert AMACrashTypeNsException", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeNsException);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__NSEXCEPTION)];
                    });
                    it(@"Should convert AMACrashTypeMainThreadDeadlock", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeMainThreadDeadlock);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__MAIN_THREAD_DEADLOCK)];
                    });
                    it(@"Should convert AMACrashTypeUserReported", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeUserReported);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__USER_REPORTED)];
                    });
                    it(@"Should convert AMACrashTypeNonFatal", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeNonFatal);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__NON_FATAL)];
                    });
                    it(@"Should convert AMACrashTypeVirtualMachineCrash", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeVirtualMachineCrash);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__VIRTUAL_MACHINE_CRASH)];
                    });
                    it(@"Should convert AMACrashTypeVirtualMachineError", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeVirtualMachineError);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__VIRTUAL_MACHINE_ERROR)];
                    });
                    it(@"Should convert AMACrashTypeVirtualMachineCustomError", ^{
                        AMADecodedCrash *crashWithType = createCrashWithType(AMACrashTypeVirtualMachineCustomError);
                        reportMessage(crashWithType);
                        [[theValue(report->crash->error->type) should] equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__VIRTUAL_MACHINE_CUSTOM_ERROR)];
                    });
                });

                it(@"Should serialize address", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->error->has_address) should] beYes];
                    [[theValue(report->crash->error->address) should] equal:theValue(crashError.address)];
                });

                it(@"Should serialize reason", ^{
                    reportMessage(decodedCrash);
                    NSString *reason = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->reason];
                    [[reason should] equal:crashError.reason];
                });

                it(@"Should serialize crash type", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Error__CrashType expected =
                        AMA__IOSCRASH_REPORT__CRASH__ERROR__CRASH_TYPE__NSEXCEPTION;
                    [[theValue(report->crash->error->type) should] equal:theValue(expected)];
                });

                context(@"Mach serialization", ^{

                    it(@"Should serialize exception type", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->mach->exception_type) should]
                            equal:theValue(mach.exceptionType)];
                    });

                    it(@"Should serialize code", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->mach->code) should] equal:theValue(mach.code)];
                    });

                    it(@"Should serialize subcode", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->mach->subcode) should] equal:theValue(mach.subcode)];
                    });
                });

                context(@"Signal serialization", ^{

                    it(@"Should serialize signal", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->signal->signal) should] equal:theValue(signal.signal)];
                    });

                    it(@"Should serialize code", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->signal->code) should] equal:theValue(signal.code)];
                    });
                });

                context(@"NSException serialization", ^{

                    it(@"Should serialize name", ^{
                        reportMessage(decodedCrash);
                        NSString *name =
                            [AMAProtobufUtilities stringForBinaryData:&report->crash->error->nsexception->name];
                        [[name should] equal:excpetion.name];
                    });

                    it(@"Should serialize user info", ^{
                        reportMessage(decodedCrash);
                        NSString *userInfo =
                            [AMAProtobufUtilities stringForBinaryData:&report->crash->error->nsexception->user_info];
                        [[userInfo should] equal:excpetion.userInfo];
                    });
                });

                context(@"С++ exception serialization", ^{

                    it(@"Should serialize name", ^{
                        reportMessage(decodedCrash);
                        NSString *name =
                            [AMAProtobufUtilities stringForBinaryData:&report->crash->error->cpp_exception->name];
                        [[name should] equal:cppException.name];
                    });
                });

                context(@"Virtual machine crash serialization", ^{
                    beforeEach(^{
                        reportMessage(decodedCrash);
                    });
                    it(@"Should serialize class name", ^{
                        NSString *className = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->virtual_machine_crash->class_name];
                        [[theValue(report->crash->error->virtual_machine_crash->has_class_name) should] beYes];
                        [[className should] equal:virtualMachineCrash.className];
                    });
                    it(@"Should serialize message", ^{
                        NSString *message = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->virtual_machine_crash->message];
                        [[theValue(report->crash->error->virtual_machine_crash->has_message) should] beYes];
                        [[message should] equal:virtualMachineCrash.message];
                    });
                    it(@"Should have NULL cause", ^{
                        [[theValue(report->crash->error->virtual_machine_crash->cause == NULL) should] beYes];
                    });

                    context(@"Nullable", ^{
                        AMAVirtualMachineCrash *nullableVirtualMachineCrash =
                            [[AMAVirtualMachineCrash alloc] initWithClassName:nil
                                                                      message:nil];
                        AMACrashReportError *const nullableCrashError =
                            [[AMACrashReportError alloc] initWithAddress:1234
                                                                  reason:@"Something went wrong"
                                                                    type:AMACrashTypeNsException
                                                                    mach:mach
                                                                  signal:signal
                                                             nsexception:excpetion
                                                            cppException:cppException
                                                          nonFatalsChain:@[ nonFatal ]
                                                     virtualMachineCrash:nullableVirtualMachineCrash];

                        AMACrashReportCrash *const nullableCrash = [[AMACrashReportCrash alloc] initWithError:nullableCrashError
                                                                                                      threads:@[ thread ]];

                        AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                                    appBuildUID:nil
                                                                                               errorEnvironment:nil
                                                                                                 appEnvironment:nil
                                                                                                           info:info
                                                                                                   binaryImages:@[ binaryImage ]
                                                                                                         system:system
                                                                                                          crash:nullableCrash];
                        beforeEach(^{
                            reportMessage(nullableDecodedCrash);
                        });
                        it(@"Should not have class name", ^{
                            NSString *className = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->virtual_machine_crash->class_name];
                            [[theValue(report->crash->error->virtual_machine_crash->has_class_name) should] beNo];
                            [[theValue(className.length) should] beZero];
                        });
                        it(@"Should not have message", ^{
                            NSString *message = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->virtual_machine_crash->message];
                            [[theValue(report->crash->error->virtual_machine_crash->has_message) should] beNo];
                            [[theValue(message.length) should] beZero];
                        });
                        it(@"Should have NULL cause", ^{
                            [[theValue(report->crash->error->virtual_machine_crash->cause == NULL) should] beYes];
                        });
                    });
                });

                context(@"Non Fatal chain serialization", ^{

                    it(@"Should serialize chain size", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->error->n_non_fatals_chain) should] equal:theValue(1)];
                    });

                    context(@"Non Fatal serialization", ^{
                        Ama__IOSCrashReport__Crash__Error__NonFatal *__block nonFatalData = NULL;
                        beforeEach(^{
                            reportMessage(decodedCrash);
                            nonFatalData = report->crash->error->non_fatals_chain[0];
                        });

                        context(@"Types", ^{
                            __auto_type createCrashWithType = ^AMADecodedCrash *(AMAErrorModelType type) {
                                AMAErrorModel *modelWithType = [[AMAErrorModel alloc] initWithType:type
                                                                                        customData:nonFatalCustomData
                                                                                       nsErrorData:nonFatalNSErrorData
                                                                                  parametersString:@"parameters"
                                                                               reportCallBacktrace:nil
                                                                             userProvidedBacktrace:nil
                                                                               virtualMachineError:virtualMachineError
                                                                                   underlyingError:nil
                                                                                    bytesTruncated:0];
                                AMANonFatal *nonFatalWithType = [[AMANonFatal alloc] initWithModel:modelWithType
                                                                                         backtrace:nil];
                                AMACrashReportError *crashErrorWithType =
                                    [[AMACrashReportError alloc] initWithAddress:12
                                                                          reason:@"reason"
                                                                            type:AMACrashTypeNonFatal
                                                                            mach:mach
                                                                          signal:signal
                                                                     nsexception:nil
                                                                    cppException:cppException
                                                                  nonFatalsChain:@[ nonFatalWithType ]
                                                             virtualMachineCrash:virtualMachineCrash];
                             AMACrashReportCrash *const crashWithType = [[AMACrashReportCrash alloc] initWithError:crashErrorWithType
                                                                                                          threads:@[ thread ]];
                             return [[AMADecodedCrash alloc] initWithAppState:nil
                                                                 appBuildUID:nil
                                                            errorEnvironment:nil
                                                              appEnvironment:nil
                                                                        info:info
                                                                binaryImages:@[ binaryImage ]
                                                                      system:system
                                                                       crash:crashWithType];
                            };

                            it(@"Should convert AMAErrorModelTypeCustom", ^{
                                AMADecodedCrash *crashWithType = createCrashWithType(AMAErrorModelTypeCustom);
                                reportMessage(crashWithType);
                                [[theValue(report->crash->error->non_fatals_chain[0]->type) should]
                                    equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__NON_FATAL__NON_FATAL_TYPE__CUSTOM)];
                            });
                            it(@"Should convert AMAErrorModelTypeNSError", ^{
                                AMADecodedCrash *crashWithType = createCrashWithType(AMAErrorModelTypeNSError);
                                reportMessage(crashWithType);
                                [[theValue(report->crash->error->non_fatals_chain[0]->type) should]
                                    equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__NON_FATAL__NON_FATAL_TYPE__NSERROR)];
                            });
                            it(@"Should convert AMAErrorModelTypeVirtualMachine", ^{
                                AMADecodedCrash *crashWithType = createCrashWithType(AMAErrorModelTypeVirtualMachine);
                                reportMessage(crashWithType);
                                [[theValue(report->crash->error->non_fatals_chain[0]->type) should]
                                    equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__NON_FATAL__NON_FATAL_TYPE__VIRTUAL_MACHINE)];
                            });
                            it(@"Should convert AMAErrorModelTypeVirtualMachineCustom", ^{
                                AMADecodedCrash *crashWithType = createCrashWithType(AMAErrorModelTypeVirtualMachineCustom);
                                reportMessage(crashWithType);
                                [[theValue(report->crash->error->non_fatals_chain[0]->type) should]
                                    equal:theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__NON_FATAL__NON_FATAL_TYPE__VIRTUAL_MACHINE_CUSTOM)];
                            });
                        });

                        it(@"Should serialize type", ^{
                            id expected =
                                theValue(AMA__IOSCRASH_REPORT__CRASH__ERROR__NON_FATAL__NON_FATAL_TYPE__NSERROR);
                            [[theValue(nonFatalData->type) should] equal:expected];
                        });

                        context(@"Custom data", ^{
                            Ama__IOSCrashReport__Crash__Error__NonFatal__Custom *__block customData = NULL;
                            beforeEach(^{
                                customData = nonFatalData->custom;
                            });

                            it(@"Should not be null", ^{
                                [[theValue(customData) shouldNot] equal:theValue(NULL)];
                            });

                            it(@"Should serialize identifier", ^{
                                NSString *identifier =
                                    [AMAProtobufUtilities stringForBinaryData:&customData->identifier];
                                [[identifier should] equal:nonFatalCustomData.identifier];
                            });

                            it(@"Should serialize has_message", ^{
                                [[theValue(customData->has_message) should] beYes];
                            });

                            it(@"Should serialize message", ^{
                                NSString *message =
                                    [AMAProtobufUtilities stringForBinaryData:&customData->message];
                                [[message should] equal:nonFatalCustomData.message];
                            });

                            it(@"Should serialize has_class_name", ^{
                                [[theValue(customData->has_class_name) should] beYes];
                            });

                            it(@"Should serialize message", ^{
                                NSString *className =
                                    [AMAProtobufUtilities stringForBinaryData:&customData->class_name];
                                [[className should] equal:nonFatalCustomData.className];
                            });
                        });

                        context(@"NSError data", ^{
                            Ama__IOSCrashReport__Crash__Error__NonFatal__NsError *__block nsErrorData = NULL;
                            beforeEach(^{
                                nsErrorData = nonFatalData->nserror;
                            });

                            it(@"Should not be null", ^{
                                [[theValue(nsErrorData) shouldNot] equal:theValue(NULL)];
                            });

                            it(@"Should serialize domain", ^{
                                NSString *domain =
                                    [AMAProtobufUtilities stringForBinaryData:&nsErrorData->domain];
                                [[domain should] equal:nonFatalNSErrorData.domain];
                            });

                            it(@"Should serialize code", ^{
                                [[theValue(nsErrorData->code) should] equal:theValue(nonFatalNSErrorData.code)];
                            });
                        });

                        context(@"Virtual machine error serialization", ^{
                            Ama__IOSCrashReport__Crash__Error__NonFatal__VirtualMachineError *__block protoVirtualMachineError = NULL;
                            beforeEach(^{
                                protoVirtualMachineError = nonFatalData->virtual_machine_error;
                            });
                            it(@"Should have class name", ^{
                                [[theValue(protoVirtualMachineError->has_class_name) should] beYes];
                                NSString *className =
                                    [AMAProtobufUtilities stringForBinaryData:&protoVirtualMachineError->class_name];
                                [[className should] equal:virtualMachineError.className];
                            });
                            it(@"Should have message", ^{
                                [[theValue(protoVirtualMachineError->has_message) should] beYes];
                                NSString *message =
                                    [AMAProtobufUtilities stringForBinaryData:&protoVirtualMachineError->message];
                                [[message should] equal:virtualMachineError.message];
                            });
                            context(@"Nullable fields", ^{
                                AMAVirtualMachineError *nullableVirtualMachineError = [[AMAVirtualMachineError alloc] initWithClassName:nil
                                                                                                                                message:nil];
                                AMAErrorModel *nullableModel = [[AMAErrorModel alloc] initWithType:AMAErrorModelTypeVirtualMachine
                                                                                        customData:nonFatalCustomData
                                                                                       nsErrorData:nonFatalNSErrorData
                                                                                  parametersString:@"parameters"
                                                                               reportCallBacktrace:nil
                                                                             userProvidedBacktrace:nil
                                                                               virtualMachineError:nullableVirtualMachineError
                                                                                   underlyingError:nil
                                                                                    bytesTruncated:0];
                                AMANonFatal *nullableNonFatal = [[AMANonFatal alloc] initWithModel:nullableModel
                                                                                         backtrace:backtrace];
                                AMACrashReportError *const nullableCrashError =
                                    [[AMACrashReportError alloc] initWithAddress:1234
                                                                          reason:@"Something went wrong"
                                                                            type:AMACrashTypeNsException
                                                                            mach:mach
                                                                          signal:signal
                                                                     nsexception:excpetion
                                                                    cppException:cppException
                                                                  nonFatalsChain:@[ nullableNonFatal ]
                                                             virtualMachineCrash:virtualMachineCrash];

                                AMACrashReportCrash *const nullableCrash = [[AMACrashReportCrash alloc] initWithError:nullableCrashError
                                                                                                              threads:@[ thread ]];

                                AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                                            appBuildUID:nil
                                                                                                       errorEnvironment:nil
                                                                                                         appEnvironment:nil
                                                                                                                   info:info
                                                                                                           binaryImages:@[ binaryImage ]
                                                                                                                 system:system
                                                                                                                  crash:nullableCrash];
                                beforeEach(^{
                                    reportMessage(nullableDecodedCrash);
                                    protoVirtualMachineError = report->crash->error->non_fatals_chain[0]->virtual_machine_error;
                                });

                                it(@"Should not have class name", ^{
                                    [[theValue(protoVirtualMachineError->has_class_name) should] beNo];
                                    NSString *className =
                                        [AMAProtobufUtilities stringForBinaryData:&protoVirtualMachineError->class_name];
                                    [[theValue(className.length) should] beZero];
                                });
                                it(@"Should not have message", ^{
                                    [[theValue(protoVirtualMachineError->has_message) should] beNo];
                                    NSString *message =
                                        [AMAProtobufUtilities stringForBinaryData:&protoVirtualMachineError->message];
                                    [[theValue(message.length) should] beZero];
                                });
                            });
                        });

                        it(@"Should serialize has_parameters", ^{
                            [[theValue(nonFatalData->has_parameters) should] beYes];
                        });

                        it(@"Should serialize parameters", ^{
                            NSString *parameters =
                                [AMAProtobufUtilities stringForBinaryData:&nonFatalData->parameters];
                            [[parameters should] equal:errorModel.parametersString];
                        });

                        it(@"Should have backtrace", ^{
                            [[theValue(nonFatalData->backtrace) shouldNot] equal:theValue(NULL)];
                        });

                        context(@"Backtrace serialization", ^{
                            Ama__IOSCrashReport__Crash__Backtrace *__block backtraceData = NULL;
                            beforeEach(^{
                                backtraceData = nonFatalData->backtrace;
                            });

                            it(@"Should serialize all frames", ^{
                                [[theValue(backtraceData->n_frames) should] equal:theValue(1)];
                            });

                            it(@"Should serialize instruction address", ^{
                                [[theValue(backtraceData->frames[0]->has_instruction_addr) should] beYes];
                                [[theValue(backtraceData->frames[0]->instruction_addr) should] equal:backtraceFrame.instructionAddress];
                            });

                            it(@"Should serialize object name", ^{
                                [[theValue(backtraceData->frames[0]->has_object_name) should] beYes];
                                NSString *objectName = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->object_name];
                                [[objectName should] equal:backtraceFrame.objectName];
                            });

                            it(@"Should serialize object address", ^{
                                [[theValue(backtraceData->frames[0]->has_object_addr) should] beYes];
                                [[theValue(backtraceData->frames[0]->object_addr) should] equal:backtraceFrame.objectAddress];
                            });

                            it(@"Should serialize symbol name", ^{
                                [[theValue(backtraceData->frames[0]->has_symbol_name) should] beYes];
                                NSString *symbolName = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->symbol_name];
                                [[symbolName should] equal:backtraceFrame.symbolName];
                            });

                            it(@"Should serialize symbol address", ^{
                                [[theValue(backtraceData->frames[0]->has_symbol_addr) should] beYes];
                                [[theValue(backtraceData->frames[0]->symbol_addr) should] equal:backtraceFrame.symbolAddress];
                            });

                            it(@"Should serialize line of code", ^{
                                [[theValue(backtraceData->frames[0]->has_line_of_code) should] beYes];
                                [[theValue(backtraceData->frames[0]->line_of_code) should] equal:backtraceFrame.lineOfCode];
                            });

                            it(@"Should serialize column of code", ^{
                                [[theValue(backtraceData->frames[0]->has_column_of_code) should] beYes];
                                [[theValue(backtraceData->frames[0]->column_of_code) should] equal:backtraceFrame.columnOfCode];
                            });
                            it(@"Should serialize class name", ^{
                                [[theValue(backtraceData->frames[0]->has_class_name) should] beYes];
                                NSString *className = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->class_name];
                                [[className should] equal:backtraceFrame.className];
                            });
                            it(@"Should serialize method name", ^{
                                [[theValue(backtraceData->frames[0]->has_method_name) should] beYes];
                                NSString *methodName = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->method_name];
                                [[methodName should] equal:backtraceFrame.methodName];
                            });
                            it(@"Should serialize file name", ^{
                                [[theValue(backtraceData->frames[0]->has_source_file_name) should] beYes];
                                NSString *fileName = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->source_file_name];
                                [[fileName should] equal:backtraceFrame.sourceFileName];
                            });
                            context(@"Nullable fields", ^{
                                AMABacktraceFrame *nullableFrame = [[AMABacktraceFrame alloc] initWithLineOfCode:nil
                                                                                              instructionAddress:nil
                                                                                                   symbolAddress:nil
                                                                                                   objectAddress:nil
                                                                                                      symbolName:nil
                                                                                                      objectName:nil
                                                                                                        stripped:NO
                                                                                                    columnOfCode:nil
                                                                                                       className:nil
                                                                                                      methodName:nil
                                                                                                  sourceFileName:nil];
                                AMABacktrace *nullableBacktrace = [[AMABacktrace alloc] initWithFrames:@[ nullableFrame ].mutableCopy];
                                AMANonFatal *nullableNonFatal = [[AMANonFatal alloc] initWithModel:errorModel
                                                                                         backtrace:nullableBacktrace];
                                AMACrashReportError *const nullableCrashError =
                                    [[AMACrashReportError alloc] initWithAddress:1234
                                                                          reason:@"Something went wrong"
                                                                            type:AMACrashTypeNsException
                                                                            mach:mach
                                                                          signal:signal
                                                                     nsexception:excpetion
                                                                    cppException:cppException
                                                                  nonFatalsChain:@[ nullableNonFatal ]
                                                             virtualMachineCrash:virtualMachineCrash];

                                AMACrashReportCrash *const nullableCrash = [[AMACrashReportCrash alloc] initWithError:nullableCrashError
                                                                                                              threads:@[ thread ]];

                                AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                                            appBuildUID:nil
                                                                                                       errorEnvironment:nil
                                                                                                         appEnvironment:nil
                                                                                                                   info:info
                                                                                                           binaryImages:@[ binaryImage ]
                                                                                                                 system:system
                                                                                                                  crash:nullableCrash];

                                beforeEach(^{
                                    reportMessage(nullableDecodedCrash);
                                    backtraceData = report->crash->error->non_fatals_chain[0]->backtrace;
                                });
                                it(@"Should not have instruction address", ^{
                                    [[theValue(backtraceData->frames[0]->has_instruction_addr) should] beNo];
                                    [[theValue(backtraceData->frames[0]->instruction_addr) should] beZero];
                                });
                                it(@"Should not have line of code", ^{
                                    [[theValue(backtraceData->frames[0]->has_line_of_code) should] beNo];
                                    [[theValue(backtraceData->frames[0]->line_of_code) should] beZero];
                                });
                                it(@"Should not have symbol address", ^{
                                    [[theValue(backtraceData->frames[0]->has_symbol_addr) should] beNo];
                                    [[theValue(backtraceData->frames[0]->symbol_addr) should] beZero];
                                });
                                it(@"Should not have object address", ^{
                                    [[theValue(backtraceData->frames[0]->has_object_addr) should] beNo];
                                    [[theValue(backtraceData->frames[0]->object_addr) should] beZero];
                                });
                                it(@"Should not have column of code", ^{
                                    [[theValue(backtraceData->frames[0]->has_column_of_code) should] beNo];
                                    [[theValue(backtraceData->frames[0]->column_of_code) should] beZero];
                                });
                                it(@"Should not have symbol name", ^{
                                    [[theValue(backtraceData->frames[0]->has_symbol_name) should] beNo];
                                    NSString *actual = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->symbol_name];
                                    [[theValue(actual.length) should] beZero];
                                });
                                it(@"Should not have object name", ^{
                                    [[theValue(backtraceData->frames[0]->has_object_name) should] beNo];
                                    NSString *actual = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->object_name];
                                    [[theValue(actual.length) should] beZero];
                                });
                                it(@"Should not have class name", ^{
                                    [[theValue(backtraceData->frames[0]->has_class_name) should] beNo];
                                    NSString *actual = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->class_name];
                                    [[theValue(actual.length) should] beZero];
                                });
                                it(@"Should not have method name", ^{
                                    [[theValue(backtraceData->frames[0]->has_method_name) should] beNo];
                                    NSString *actual = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->method_name];
                                    [[theValue(actual.length) should] beZero];
                                });
                                it(@"Should not have file name", ^{
                                    [[theValue(backtraceData->frames[0]->has_source_file_name) should] beNo];
                                    NSString *actual = [AMAProtobufUtilities stringForBinaryData:&backtraceData->frames[0]->source_file_name];
                                    [[theValue(actual.length) should] beZero];
                                });

                            });
                        });

                        context(@"Nullable fields", ^{
                            AMAErrorModel *nullableModel = [[AMAErrorModel alloc] initWithType:AMAErrorModelTypeVirtualMachine
                                                                                    customData:nil
                                                                                   nsErrorData:nil
                                                                              parametersString:nil
                                                                           reportCallBacktrace:nil
                                                                         userProvidedBacktrace:nil
                                                                           virtualMachineError:nil
                                                                               underlyingError:nil
                                                                                bytesTruncated:0];
                            AMANonFatal *nullableNonFatal = [[AMANonFatal alloc] initWithModel:nullableModel
                                                                                     backtrace:nil];
                            AMACrashReportError *const nullableCrashError =
                                [[AMACrashReportError alloc] initWithAddress:1234
                                                                      reason:@"Something went wrong"
                                                                        type:AMACrashTypeNsException
                                                                        mach:mach
                                                                      signal:signal
                                                                 nsexception:excpetion
                                                                cppException:cppException
                                                              nonFatalsChain:@[ nullableNonFatal ]
                                                         virtualMachineCrash:virtualMachineCrash];

                            AMACrashReportCrash *const nullableCrash = [[AMACrashReportCrash alloc] initWithError:nullableCrashError
                                                                                                          threads:@[ thread ]];

                            AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                                        appBuildUID:nil
                                                                                                   errorEnvironment:nil
                                                                                                     appEnvironment:nil
                                                                                                               info:info
                                                                                                       binaryImages:@[ binaryImage ]
                                                                                                             system:system
                                                                                                              crash:nullableCrash];

                            Ama__IOSCrashReport__Crash__Error__NonFatal *__block protoNonFatal = NULL;
                            beforeEach(^{
                                reportMessage(nullableDecodedCrash);
                                protoNonFatal = report->crash->error->non_fatals_chain[0];
                            });
                            it(@"Should not have parameters", ^{
                                [[theValue(protoNonFatal->has_parameters) should] beNo];
                                NSString *actual = [AMAProtobufUtilities stringForBinaryData:&protoNonFatal->parameters];
                                [[theValue(actual.length) should] beZero];
                            });
                            it(@"Should not have backtrace", ^{
                                [[theValue(protoNonFatal->backtrace == NULL) should] beYes];
                            });
                            it(@"Should not have custom", ^{
                                [[theValue(protoNonFatal->custom == NULL) should] beYes];
                            });
                            it(@"Should not have nserror", ^{
                                [[theValue(protoNonFatal->nserror == NULL) should] beYes];
                            });
                            it(@"Should not have virtual_machine_error", ^{
                                [[theValue(protoNonFatal->virtual_machine_error == NULL) should] beYes];
                            });
                        });
                    });
                });

                context(@"Nullable fields", ^{
                    AMACrashReportError *const nullableCrashError =
                        [[AMACrashReportError alloc] initWithAddress:0x0
                                                              reason:nil
                                                                type:AMACrashTypeNsException
                                                                mach:nil
                                                              signal:nil
                                                         nsexception:nil
                                                        cppException:nil
                                                      nonFatalsChain:nil
                                                 virtualMachineCrash:nil];

                    AMACrashReportCrash *const nullableCrash = [[AMACrashReportCrash alloc] initWithError:nullableCrashError
                                                                                                  threads:@[ thread ]];

                    AMADecodedCrash *const nullableDecodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                                                                appBuildUID:nil
                                                                                           errorEnvironment:nil
                                                                                             appEnvironment:nil
                                                                                                       info:info
                                                                                               binaryImages:@[ binaryImage ]
                                                                                                     system:system
                                                                                                      crash:nullableCrash];
                    beforeEach(^{
                        reportMessage(nullableDecodedCrash);
                    });
                    it(@"Should have 0x0 address", ^{
                        [[theValue(report->crash->error->has_address) should] beNo];
                        [[theValue(report->crash->error->address) should] equal:theValue(0x0)];
                    });
                    it(@"Should not have reason", ^{
                        [[theValue(report->crash->error->has_reason) should] beNo];
                        NSString *actual = [AMAProtobufUtilities stringForBinaryData:&report->crash->error->reason];
                        [[theValue(actual.length) should] beZero];
                    });
                    it(@"Should not have mach", ^{
                        [[theValue(report->crash->error->mach == NULL) should] beYes];
                    });
                    it(@"Should not have signal", ^{
                        [[theValue(report->crash->error->signal == NULL) should] beYes];
                    });
                    it(@"Should not have nsexception", ^{
                        [[theValue(report->crash->error->nsexception == NULL) should] beYes];
                    });
                    it(@"Should not have cpp_exception", ^{
                        [[theValue(report->crash->error->cpp_exception == NULL) should] beYes];
                    });
                    it(@"Should not have virtual machine crash", ^{
                        [[theValue(report->crash->error->virtual_machine_crash == NULL) should] beYes];
                    });
                    it(@"Should not have non fatals", ^{
                        [[theValue(report->crash->error->n_non_fatals_chain) should] beZero];
                        [[theValue(report->crash->error->non_fatals_chain == NULL) should] beYes];
                    });

                });
            });

            context(@"Thread serialization", ^{

                it(@"Should serialize all threads", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->n_threads) should] equal:theValue(crash.threads.count)];
                });

                it(@"Should serialize index", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->threads[0]->index) should] equal:theValue(thread.index)];
                });

                it(@"Should serialize crashed", ^{
                    reportMessage(decodedCrash);
                    [[theValue((BOOL)report->crash->threads[0]->crashed) should] equal:theValue(thread.crashed)];
                });
            });

            context(@"Stack serialization", ^{

                it(@"Should serialize grow direction", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Thread__Stack__GrowDirection excpected =
                        AMA__IOSCRASH_REPORT__CRASH__THREAD__STACK__GROW_DIRECTION__PLUS;
                    [[theValue(report->crash->threads[0]->stack->grow_direction) should] equal:theValue(excpected)];
                });

                it(@"Should serialize dump start", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->threads[0]->stack->dump_start) should] equal:theValue(stack.dumpStart)];
                });

                it(@"Should serialize dump end", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->threads[0]->stack->dump_end) should] equal:theValue(stack.dumpEnd)];
                });

                it(@"Should serialize stack pointer", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->threads[0]->stack->stack_pointer) should]
                        equal:theValue(stack.stackPointer)];
                });

                it(@"Should serialize overflow", ^{
                    reportMessage(decodedCrash);
                    [[theValue((BOOL)report->crash->threads[0]->stack->overflow) should]
                        equal:theValue(stack.overflow)];
                });

                it(@"Should serialize contents", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Thread__Stack *proptoStack = report->crash->threads[0]->stack;
                    NSData *contents = [AMAProtobufUtilities dataForBinaryData:&proptoStack->contents];
                    [[contents should] equal:stack.contents];
                });
            });

            context(@"Backtrace serialization", ^{

                it(@"Should serialize all frames", ^{
                    reportMessage(decodedCrash);
                    [[theValue(report->crash->threads[0]->backtrace->n_frames) should]
                        equal:theValue(backtrace.frames.count)];
                });

                it(@"Should serialize instruction address", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    [[theValue(protoFrame->instruction_addr) should] equal:backtraceFrame.instructionAddress];
                });

                it(@"Should serialize onject name", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    NSString *objectName = [AMAProtobufUtilities stringForBinaryData:&protoFrame->object_name];
                    [[objectName should] equal:backtraceFrame.objectName];
                });

                it(@"Should serialize object address", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    [[theValue(protoFrame->object_addr) should] equal:backtraceFrame.objectAddress];
                });

                it(@"Should serialize symbol name", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    NSString *symbolName = [AMAProtobufUtilities stringForBinaryData:&protoFrame->symbol_name];
                    [[symbolName should] equal:backtraceFrame.symbolName];
                });

                it(@"Should serialize symbol address", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    [[theValue(protoFrame->symbol_addr) should] equal:backtraceFrame.symbolAddress];
                });

                it(@"Should serialize line of code", ^{
                    reportMessage(decodedCrash);
                    Ama__IOSCrashReport__Crash__Backtrace__Frame *protoFrame =
                        report->crash->threads[0]->backtrace->frames[0];
                    [[theValue(protoFrame->line_of_code) should] equal:backtraceFrame.lineOfCode];
                });

                it(@"Should serialize thread name", ^{
                    reportMessage(decodedCrash);
                    NSString *threadName = [AMAProtobufUtilities stringForBinaryData:&report->crash->threads[0]->name];
                    [[threadName should] equal:thread.threadName];
                });

                it(@"Should serialize queue name", ^{
                    reportMessage(decodedCrash);
                    NSString *queueName =
                        [AMAProtobufUtilities stringForBinaryData:&report->crash->threads[0]->dispatch_queue_name];
                    [[queueName should] equal:thread.queueName];
                });
            });

            context(@"Registers serialization", ^{

                context(@"Basic registers serialization", ^{

                    it(@"Should serialize all registers", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->threads[0]->registers->n_basic) should]
                            equal:theValue(registers.basic.count)];
                    });

                    it(@"Should contain all registers", ^{
                        reportMessage(decodedCrash);
                        Ama__IOSCrashReport__Crash__Thread__Registers *regArray = report->crash->threads[0]->registers;
                        NSMutableArray *registerArray = [NSMutableArray arrayWithCapacity:regArray->n_basic];
                        for (NSUInteger i = 0; i < regArray->n_basic; i++) {
                            NSString *name = [AMAProtobufUtilities stringForBinaryData:&regArray->basic[i]->name];
                            AMARegister *reg = [[AMARegister alloc] initWithName:name value:regArray->basic[i]->value];
                            [registerArray addObject:reg];
                        }
                        [[registerArray should] containObjectsInArray:registers.basic];
                    });
                });

                context(@"Exception registers serialization", ^{

                    it(@"Should serialize all registers", ^{
                        reportMessage(decodedCrash);
                        [[theValue(report->crash->threads[0]->registers->n_exception) should]
                            equal:theValue(registers.exception.count)];
                    });

                    it(@"Should contain all registers", ^{
                        reportMessage(decodedCrash);
                        Ama__IOSCrashReport__Crash__Thread__Registers *regArray = report->crash->threads[0]->registers;
                        NSMutableArray *registerArray = [NSMutableArray arrayWithCapacity:regArray->n_exception];
                        for (NSUInteger i = 0; i < regArray->n_exception; i++) {
                            NSString *name = [AMAProtobufUtilities stringForBinaryData:&regArray->exception[i]->name];
                            AMARegister *reg =
                                [[AMARegister alloc] initWithName:name value:regArray->exception[i]->value];
                            [registerArray addObject:reg];
                        }
                        [[registerArray should] containObjectsInArray:registers.exception];
                    });
                });
            });
        });
    });

    context(@"Error reporting", ^{
        
        let(validator, ^{
            AMADecodedCrashValidator *validator = [AMADecodedCrashValidator nullMock];
            [AMADecodedCrashValidator stub:@selector(alloc) andReturn:validator];
            return validator;
        });
        
        afterEach(^{
            [AMADecodedCrashValidator clearStubs];
        });

        it(@"Should return nil and set critical NSError", ^{
            NSError *criticalError = [NSError errorWithDomain:@"test.error.domain"
                                                          code:AMACrashValidatorErrorCodeCritical
                                                      userInfo:@{}];
            [validator stub:@selector(result) andReturn:criticalError];
            NSData *data = reportMessage(decodedCrash);
            
            [[data should] beNil];
            [[error should] equal:criticalError];
        });

        it(@"Should return data and set suspicious NSError", ^{
            NSError *suspiciousError = [NSError errorWithDomain:@"test.error.domain"
                                                           code:AMACrashValidatorErrorCodeSuspicious
                                                       userInfo:@{}];
            [validator stub:@selector(result) andReturn:suspiciousError];
            NSData *data = reportMessage(decodedCrash);
            
            [[data shouldNot] beNil];
            [[error should] equal:suspiciousError];
        });

        it(@"Should return data and set non-critical NSError", ^{
            NSError *nonCriticalError = [NSError errorWithDomain:@"test.error.domain"
                                                             code:AMACrashValidatorErrorCodeNonCritical
                                                         userInfo:@{}];
            [validator stub:@selector(result) andReturn:nonCriticalError];
            NSData *data = reportMessage(decodedCrash);
            
            [[data shouldNot] beNil];
            [[error should] equal:nonCriticalError];
        });

        it(@"Should return data and not set NSError if validation is successful", ^{
            [validator stub:@selector(result) andReturn:nil];
            NSData *data = reportMessage(decodedCrash);
            
            [[data shouldNot] beNil];
            [[error should] beNil];
        });
    });

    context(@"AMADecodedCrashSerializer (CustomEventParameters)", ^{
        
        let(serializer, ^{ return [[AMADecodedCrashSerializer alloc] init]; });
        let(validator, ^{
            AMADecodedCrashValidator *validator = [AMADecodedCrashValidator nullMock];
            [AMADecodedCrashValidator stub:@selector(alloc) andReturn:validator];
            return validator;
        });
        
        __block NSError *error = nil;
        
        afterEach(^{
            [AMADecodedCrashValidator clearStubs];
            report = NULL;
        });

        context(@"-eventParametersFromDecodedData:error:", ^{
            
            it(@"Should return nil and set critical NSError", ^{
                NSError *criticalError = [NSError errorWithDomain:@"test.error.domain"
                                                             code:AMACrashValidatorErrorCodeCritical
                                                         userInfo:@{}];
                [validator stub:@selector(result) andReturn:criticalError];
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:&error];

                [[result should] beNil];
                [[error should] equal:criticalError];
            });

            it(@"Should return AMAEventPollingParameters and set suspicious NSError", ^{
                NSError *suspiciousError = [NSError errorWithDomain:@"test.error.domain"
                                                              code:AMACrashValidatorErrorCodeSuspicious
                                                          userInfo:@{}];
                [validator stub:@selector(result) andReturn:suspiciousError];
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:&error];

                [[result shouldNot] beNil];
                [[error should] equal:suspiciousError];
            });

            it(@"Should return AMAEventPollingParameters and set non-critical NSError", ^{
                NSError *nonCriticalError = [NSError errorWithDomain:@"test.error.domain"
                                                               code:AMACrashValidatorErrorCodeNonCritical
                                                           userInfo:@{}];
                [validator stub:@selector(result) andReturn:nonCriticalError];
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:&error];

                [[result shouldNot] beNil];
                [[error should] equal:nonCriticalError];
            });
            
            it(@"Should return AMAEventPollingParameters and not set NSError if validation is successful", ^{
                [validator stub:@selector(result) andReturn:nil];
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:&error];

                [[result shouldNot] beNil];
                [[error should] beNil];
            });
        });
        
        context(@"Event types", ^{
            it(@"Should use Crash event type", ^{
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[theValue(result.eventType) should] equal:theValue(AMACrashEventTypeCrash)];
            });
            
            it(@"Should use ANR event type in case of Deadlock", ^{
                [crashError stub:@selector(type) andReturn:theValue(AMACrashTypeMainThreadDeadlock)];
                AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[theValue(result.eventType) should] equal:theValue(AMACrashEventTypeANR)];
            });
        });
    });
    
    context(@"Custom event parameters", ^{

        let(serializer, ^{ return [[AMADecodedCrashSerializer alloc] init]; });
        __block AMAEventPollingParameters *result = nil;
        
        afterEach(^{
            report = NULL;
        });
        
        context(@"eventParametersFromDecodedData:forEventType:", ^{
            it(@"Should generate correct event parameters for given type", ^{
                AMACrashEventType eventType = AMACrashEventTypeANR;
                result = [serializer eventParametersFromDecodedData:decodedCrash forEventType:eventType error:NULL];
                
                [[theValue(result.eventType) should] equal:theValue(eventType)];
                [[result.data should] equal:[serializer dataForCrash:decodedCrash error:NULL]];
                [[result.creationDate should] equal:decodedCrash.info.timestamp];
                [[result.appState should] equal:decodedCrash.appState];
                [[result.eventEnvironment should] equal:decodedCrash.errorEnvironment];
                [[result.appEnvironment should] equal:decodedCrash.appEnvironment];
            });
        });
        
        context(@"eventParametersFromDecodedData:", ^{
            it(@"Should use correct event type for MainThreadDeadlock", ^{
                [decodedCrash.crash.error stub:@selector(type) andReturn:theValue(AMACrashTypeMainThreadDeadlock)];
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                
                [[theValue(result.eventType) should] equal:theValue(AMACrashEventTypeANR)];
            });
            
            it(@"Should use correct event type for other crash types", ^{
                [decodedCrash.crash.error stub:@selector(type) andReturn:theValue(AMACrashTypeUserReported)];
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                
                [[theValue(result.eventType) should] equal:theValue(AMACrashEventTypeCrash)];
            });
            
            it(@"Should set correct data from decoded crash", ^{
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[result.data should] equal:[serializer dataForCrash:decodedCrash error:NULL]];
            });
            
            it(@"Should set correct creationDate from decoded crash", ^{
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[result.creationDate should] equal:decodedCrash.info.timestamp];
            });
            
            it(@"Should set correct appState from decoded crash", ^{
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[result.appState should] equal:decodedCrash.appState];
            });
            
            it(@"Should set correct errorEnvironment from decoded crash", ^{
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[result.eventEnvironment should] equal:decodedCrash.errorEnvironment];
            });
            
            it(@"Should set correct appEnvironment from decoded crash", ^{
                result = [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                [[result.appEnvironment should] equal:decodedCrash.appEnvironment];
            });
        });
        
        context(@"Edge Cases and Corner Cases", ^{

            context(@"eventParametersFromDecodedData:forEventType:", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
                it(@"Should handle nil decodedCrash gracefully", ^{
                    [[theBlock(^{
                        [serializer eventParametersFromDecodedData:nil forEventType:AMACrashEventTypeANR error:NULL];
                    }) shouldNot] raise];
                });
                
            });

            context(@"eventParametersFromDecodedData:", ^{
                
                it(@"Should handle nil decodedCrash gracefully", ^{
                    [[theBlock(^{
                        [serializer eventParametersFromDecodedData:nil error:NULL];
                    }) shouldNot] raise];
                });
#pragma clang diagnostic pop
                it(@"Should default to AMACrashEventTypeCrash for unknown crash types", ^{
                    [decodedCrash.crash.error stub:@selector(type) andReturn:theValue(9999)];
                    AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash
                                                                                            error:NULL];
                    [[theValue(result.eventType) should] equal:theValue(AMACrashEventTypeCrash)];
                });
                
                it(@"Should handle nil data from dataForCrash: gracefully", ^{
                    [serializer stub:@selector(dataForCrash:error:) andReturn:nil];
                    AMAEventPollingParameters *result = [serializer eventParametersFromDecodedData:decodedCrash
                                                                                            error:NULL];
                    [[result.data should] beNil];
                });
                
                it(@"Should handle missing properties in decodedCrash gracefully", ^{
                    [decodedCrash stub:@selector(info) andReturn:nil];
                    [[theBlock(^{
                        [serializer eventParametersFromDecodedData:decodedCrash error:NULL];
                    }) shouldNot] raise];
                });
                
            });
        });
    });
});

SPEC_END
