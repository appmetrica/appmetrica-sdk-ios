
#import <Foundation/Foundation.h>

@protocol AMAKSCrashReportDecoderDelegate;
@protocol AMADateProviding;
@class AMADecodedCrash;
@class AMASystemInfo;

extern NSString *const kAMASysInfoSystemName;
extern NSString *const kAMASysInfoSystemVersion;
extern NSString *const kAMASysInfoMachine;
extern NSString *const kAMASysInfoModel;
extern NSString *const kAMASysInfoKernelVersion;
extern NSString *const kAMASysInfoOsVersion;
extern NSString *const kAMASysInfoIsJailbroken;
extern NSString *const kAMASysInfoBootTime;
extern NSString *const kAMASysInfoAppStartTime;
extern NSString *const kAMASysInfoExecutablePath;
extern NSString *const kAMASysInfoExecutableName;
extern NSString *const kAMASysInfoBundleID;
extern NSString *const kAMASysInfoBundleName;
extern NSString *const kAMASysInfoBundleVersion;
extern NSString *const kAMASysInfoBundleShortVersion;
extern NSString *const kAMASysInfoAppID;
extern NSString *const kAMASysInfoCpuArchitecture;
extern NSString *const kAMASysInfoCpuType;
extern NSString *const kAMASysInfoCpuSubType;
extern NSString *const kAMASysInfoBinaryCPUType;
extern NSString *const kAMASysInfoBinaryCPUSubType;
extern NSString *const kAMASysInfoTimezone;
extern NSString *const kAMASysInfoProcessName;
extern NSString *const kAMASysInfoProcessID;
extern NSString *const kAMASysInfoParentProcessID;
extern NSString *const kAMASysInfoDeviceAppHash;
extern NSString *const kAMASysInfoBuildType;
extern NSString *const kAMASysInfoStorageSize;
extern NSString *const kAMASysInfoMemorySize;
extern NSString *const kAMASysInfoFreeMemory;
extern NSString *const kAMASysInfoUsableMemory;

@interface AMAKSCrashReportDecoder : NSObject

@property (nonatomic, weak) id<AMAKSCrashReportDecoderDelegate> delegate;
@property (nonatomic, strong, readonly) NSNumber *crashID;
@property (nonatomic, strong, readonly) NSArray *supportedVersionsConstaints;

- (instancetype)initWithCrashID:(NSNumber *)crashID dateProvider:(id<AMADateProviding>)dateProvider;

- (instancetype)initWithCrashID:(NSNumber *)crashID;

- (void)decode:(NSDictionary *)report;

- (AMASystemInfo *)systemInfoForDictionary:(NSDictionary *)system;

@end

@protocol AMAKSCrashReportDecoderDelegate <NSObject>

- (void)crashReportDecoder:(AMAKSCrashReportDecoder *)decoder
            didDecodeCrash:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error;

- (void)crashReportDecoder:(AMAKSCrashReportDecoder *)decoder
              didDecodeANR:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error;

@end
