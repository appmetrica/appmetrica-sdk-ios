#import "AMAAppMetricaMock.h"
#import <os/lock.h>

static id<AMAAsyncExecuting, AMASyncExecuting> _sharedExecutor = nil;
static AMAAppMetricaImpl *_sharedImpl = nil;
static AMAMetricaConfiguration *_metricaConfiguration = nil;

static os_unfair_lock _lock = OS_UNFAIR_LOCK_INIT;

static NSMutableArray<AMAAdRevenueInfo *> *_capturedAdRevenues = nil;
static NSMutableArray<NSNumber *>         *_capturedIsAutocollected = nil;
static NSMutableArray<NSString *>         *_capturedNativeSources = nil;

@implementation AMAAppMetricaMock

+ (id<AMAAsyncExecuting, AMASyncExecuting>)sharedExecutor
{
    os_unfair_lock_lock(&_lock);
    id<AMAAsyncExecuting, AMASyncExecuting> value = _sharedExecutor;
    os_unfair_lock_unlock(&_lock);
    return value;
}

+ (void)setSharedExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)sharedExecutor
{
    os_unfair_lock_lock(&_lock);
    _sharedExecutor = sharedExecutor;
    os_unfair_lock_unlock(&_lock);
}

+ (AMAAppMetricaImpl *)sharedImpl
{
    os_unfair_lock_lock(&_lock);
    AMAAppMetricaImpl *value = _sharedImpl;
    os_unfair_lock_unlock(&_lock);
    return value;
}

+ (void)setSharedImpl:(AMAAppMetricaImpl *)sharedImpl
{
    os_unfair_lock_lock(&_lock);
    _sharedImpl = sharedImpl;
    os_unfair_lock_unlock(&_lock);
}

+ (AMAMetricaConfiguration *)metricaConfiguration
{
    os_unfair_lock_lock(&_lock);
    AMAMetricaConfiguration *value = _metricaConfiguration;
    os_unfair_lock_unlock(&_lock);
    return value;
}

+ (void)setMetricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration
{
    os_unfair_lock_lock(&_lock);
    _metricaConfiguration = metricaConfiguration;
    os_unfair_lock_unlock(&_lock);
}

+ (void)resetSharedDependencies
{
    os_unfair_lock_lock(&_lock);
    _sharedExecutor = nil;
    _sharedImpl = nil;
    _metricaConfiguration = nil;
    os_unfair_lock_unlock(&_lock);
}

// MARK: - Ad revenue capture

+ (NSMutableArray<AMAAdRevenueInfo *> *)capturedAdRevenues   { return _capturedAdRevenues; }
+ (NSMutableArray<NSNumber *> *)capturedIsAutocollected       { return _capturedIsAutocollected; }
+ (NSMutableArray<NSString *> *)capturedNativeSources         { return _capturedNativeSources; }

+ (void)resetCaptures
{
    _capturedAdRevenues      = [NSMutableArray array];
    _capturedIsAutocollected = [NSMutableArray array];
    _capturedNativeSources   = [NSMutableArray array];
}

@end
