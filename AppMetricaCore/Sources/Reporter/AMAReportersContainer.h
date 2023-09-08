
#import <Foundation/Foundation.h>

@class AMAReporter;

@interface AMAReportersContainer : NSObject

- (AMAReporter *)reporterForApiKey:(NSString *)apiKey;

- (void)start;
- (void)shutdown;
- (void)startNewSession;
- (void)setReporter:(AMAReporter *)reporter forApiKey:(NSString *)apiKey;

@end
