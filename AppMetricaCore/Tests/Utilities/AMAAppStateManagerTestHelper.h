
#import <Foundation/Foundation.h>

@interface AMAAppStateManagerTestHelper : NSObject

@property (nonatomic, copy) NSString *appVersionName;
@property (nonatomic, assign) BOOL appDebuggable;
@property (nonatomic, copy) NSString *kitVersion;
@property (nonatomic, copy) NSString *kitVersionName;
@property (nonatomic, assign) NSUInteger kitBuildNumber;
@property (nonatomic, copy) NSString *kitBuildType;
@property (nonatomic, copy) NSString *OSVersion;
@property (nonatomic, assign) NSInteger OSAPILevel;
@property (nonatomic, copy) NSString *locale;
@property (nonatomic, assign) BOOL isRooted;
@property (nonatomic, copy) NSString *UUID;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *IFV;
@property (nonatomic, copy) NSString *IFA;
@property (nonatomic, assign) BOOL LAT;
@property (nonatomic, assign) uint32_t appBuildNumber;

- (void)stubApplicationState;
- (void)destubApplicationState;

@end
