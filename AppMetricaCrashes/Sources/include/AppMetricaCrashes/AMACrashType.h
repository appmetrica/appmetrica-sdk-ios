
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AMACrashType) {
    AMACrashTypeMachException,
    AMACrashTypeSignal,
    AMACrashTypeCppException,
    AMACrashTypeNsException,
    AMACrashTypeMainThreadDeadlock,
    AMACrashTypeUserReported,
    AMACrashTypeNonFatal,
    AMACrashTypeVirtualMachineCrash,
    AMACrashTypeVirtualMachineError,
    AMACrashTypeVirtualMachineCustomError,
} NS_SWIFT_NAME(CrashType);
