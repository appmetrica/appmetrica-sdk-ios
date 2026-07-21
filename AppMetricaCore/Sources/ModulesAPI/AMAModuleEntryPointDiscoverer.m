#import "AMAModuleEntryPointDiscoverer.h"

static NSArray<NSString *> *AMADefaultModuleEntryPointClassNames(void)
{
    NSMutableArray<NSString *> *names = [@[
        @"AMAAppMetricaCrashesEntryPoint",
        @"AMAAdSupportModuleEntryPoint",
        @"AMAIDSyncModuleEntryPoint",
        @"AMAScreenshotModuleEntryPoint",
        @"AMAAppLovinMaxModuleEntryPoint",
        @"AMAIronSourceModuleEntryPoint",
    ] mutableCopy];

    Class provider = NSClassFromString(@"AMAInternalEntryPointProvider");
    SEL selector = NSSelectorFromString(@"entryPointClassNames");
    if ([provider respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSArray<NSString *> *internalNames = [provider performSelector:selector];
#pragma clang diagnostic pop
        if ([internalNames isKindOfClass:NSArray.class]) {
            [names addObjectsFromArray:internalNames];
        }
    }
    return [names copy];
}

@interface AMAModuleEntryPointDiscoverer ()

@property (nonatomic, copy, readonly) NSArray<NSString *> *candidateClassNames;
@property (nonatomic, copy, readonly, nullable) Class (^classLookup)(NSString *className);

@end

@implementation AMAModuleEntryPointDiscoverer

- (instancetype)initWithClassLookup:(Class (^)(NSString *))classLookup
{
    return [self initWithCandidateClassNames:AMADefaultModuleEntryPointClassNames()
                                 classLookup:classLookup];
}

- (instancetype)initWithCandidateClassNames:(NSArray<NSString *> *)candidateClassNames
                                 classLookup:(Class (^)(NSString *))classLookup
{
    self = [super init];
    if (self != nil) {
        _candidateClassNames = [[NSOrderedSet orderedSetWithArray:candidateClassNames] array];
        _classLookup = [classLookup copy];
    }
    return self;
}

- (NSArray<id<AMAModuleEntryPoint>> *)discoverEntryPoints
{
    NSMutableArray<id<AMAModuleEntryPoint>> *entryPoints = [NSMutableArray array];
    for (NSString *className in self.candidateClassNames) {
        Class entryPointClass = self.classLookup != nil
            ? self.classLookup(className)
            : NSClassFromString(className);
        if (entryPointClass == Nil) {
            continue;
        }
        if ([entryPointClass conformsToProtocol:@protocol(AMAModuleEntryPoint)] == NO) {
            AMALogInfo(@"[AMAModuleEntryPointDiscoverer] Class %@ does not conform to AMAModuleEntryPoint",
                       className);
            continue;
        }

        id<AMAModuleEntryPoint> entryPoint = nil;
        @try {
            entryPoint = [[entryPointClass alloc] init];
        }
        @catch (NSException *exception) {
            AMALogError(@"[AMAModuleEntryPointDiscoverer] Failed to initialize %@: %@",
                        className,
                        exception);
        }
        if (entryPoint == nil) {
            AMALogInfo(@"[AMAModuleEntryPointDiscoverer] Class %@ returned nil from init", className);
            continue;
        }
        [entryPoints addObject:entryPoint];
    }
    return entryPoints;
}

@end
