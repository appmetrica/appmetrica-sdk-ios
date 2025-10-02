
#import "AMAFMDatabaseQueryRecorderMock.h"

@interface AMAFMDatabaseQueryRecorderMock ()

@property (nonatomic, copy, readwrite) NSArray<NSString *> *executedStatements;

@end

@implementation AMAFMDatabaseQueryRecorderMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.executedStatements = [NSArray array];
    }
    return self;
}

- (BOOL)executeStatements:(NSString *)sql
{
    NSMutableArray *new = [self.executedStatements mutableCopy] ?: [NSMutableArray array];
    [new addObject:sql];
    self.executedStatements = new;
    
    return YES;
}

@end
