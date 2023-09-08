
#import "AMAUserImagesUUIDProvider.h"

#import "AMASymbolsExtractor.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMABinaryImage.h"

@implementation AMAUserImagesUUIDProvider

- (NSArray<NSString *> *)UUIDs
{
    return [AMACollectionUtilities mapArray:AMASymbolsExtractor.userApplicationImages
                                  withBlock:^id(AMABinaryImage *item) {
        return item.UUID;
    }];
}

@end
