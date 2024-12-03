
#import "AMABundleInfoMock.h"

@implementation AMABundleInfoMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mockedInfo = [NSDictionary dictionary];
    }
    return self;
}

- (id)objectForInfoDictionaryKey:(NSString *)key
{
    return self.mockedInfo[key];
}

@end
