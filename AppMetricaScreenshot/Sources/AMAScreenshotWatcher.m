#import "AMAScreenshotWatcher.h"
#import <AppMetricaCore/AppMetricaCore.h>
#import "AMAScreenshotReporting.h"
#import <UIKit/UIKit.h>


@interface AMAScreenshotWatcher ()

@property (nonatomic, strong, nonnull, readonly) id<AMAScreenshotReporting> reporter;
@property (nonatomic, strong, nonnull, readonly) NSNotificationCenter *notificationCenter;

@end

@implementation AMAScreenshotWatcher

@synthesize isStarted = _isStarted;

- (instancetype)initWithReporter:(id<AMAScreenshotReporting>)reporter
{
    return [self initWithReporter:reporter notificationCenter:[NSNotificationCenter defaultCenter]];
}

- (instancetype)initWithReporter:(id<AMAScreenshotReporting>)reporter
              notificationCenter:(NSNotificationCenter *)notificationCenter
{
    self = [super init];
    if (self) {
        _reporter = reporter;
        _notificationCenter = notificationCenter;
    }
    return self;
}

- (void)dealloc
{
    [self.notificationCenter removeObserver:self];
}

- (void)setIsStarted:(BOOL)isStarted
{
    @synchronized (self) {
        if (_isStarted == isStarted) {
            return;
        }
        
        if (isStarted) {
            [self.notificationCenter addObserver:self
                                        selector:@selector(handleNotification:)
                                            name:UIApplicationUserDidTakeScreenshotNotification
                                          object:nil];
        } else {
            [self.notificationCenter removeObserver:self];
        }
        
        _isStarted = isStarted;
    }
}

- (BOOL)isStarted
{
    @synchronized (self) {
        return _isStarted;
    }
}

- (void)handleNotification:(NSNotification*)notification
{
    [self.reporter reportScreenshot];
}

@end
