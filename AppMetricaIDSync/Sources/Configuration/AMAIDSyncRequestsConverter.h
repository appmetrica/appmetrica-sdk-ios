
#import <Foundation/Foundation.h>

@class AMAIDSyncRequest;

extern NSUInteger const kAMAIDSyncDefaultValidResendInterval;
extern NSUInteger const kAMAIDSyncDefaultInvalidResendInterval;

@interface AMAIDSyncRequestsConverter : NSObject

- (NSArray<AMAIDSyncRequest *> *)convertDictToRequests:(NSArray<NSDictionary *> *)requests;

@end
