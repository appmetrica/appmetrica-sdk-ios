
#import <Foundation/Foundation.h>

@protocol AMACrashLoaderDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol AMACrashLoading <NSObject>

@property (nonatomic, weak, nullable) id<AMACrashLoaderDelegate> delegate;

- (void)loadCrashReports;

@end

NS_ASSUME_NONNULL_END
