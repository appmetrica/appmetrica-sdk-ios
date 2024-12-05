
#import <Foundation/Foundation.h>

@class AMAInternalEventsReporter;

@interface AMAAppEnvironmentValidator : NSObject

- (instancetype)initWithInternalReporter:(AMAInternalEventsReporter *)reporter;

- (BOOL)validateAppEnvironmentKey:(id)object;
- (BOOL)validateAppEnvironmentValue:(id)object;

@end
