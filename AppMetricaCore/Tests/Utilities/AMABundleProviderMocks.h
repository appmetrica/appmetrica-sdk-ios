
#import <Foundation/Foundation.h>

@interface LSApplicationWorkspaceMock : NSObject

@property (nonatomic, copy, readonly) NSArray *allInstalledApplications;
@property (nonatomic, copy, readonly) NSArray *installedPlugins;

- (instancetype)initWithAllInstalledApplications:(NSArray *)allInstalledApplications
                                installedPlugins:(NSArray *)installedPlugins;
+ (instancetype)defaultWorkspace;

@end

@interface LSApplicationBundleMock : NSObject

@property (nonatomic, copy, readonly) NSString *applicationIdentifier;
@property (nonatomic, copy, readonly) NSString *bundleType;
@property (nonatomic, strong, readonly) NSDate *registeredDate;

- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                                   bundleType:(NSString *)bundleType
                               registeredDate:(NSDate *)registeredDate;

@end

@interface LSPluginKitBundleMock : NSObject

@property (nonatomic, readonly) LSApplicationBundleMock *containingBundle;

- (instancetype)initWithContainingBundle:(LSApplicationBundleMock *)containingBundle;

@end

@interface MCMAppDataContainerMock : NSObject

+ (instancetype)containerWithIdentifier:(NSString *)identifier error:(NSError *)error;

@end
