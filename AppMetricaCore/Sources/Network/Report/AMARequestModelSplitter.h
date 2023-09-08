
#import <Foundation/Foundation.h>

@class AMAReportRequestModel;

@interface AMARequestModelSplitter : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (NSArray<AMAReportRequestModel *> *)splitRequestModel:(AMAReportRequestModel *)requestModel
                                                inParts:(NSUInteger)numberOfParts;

@end
