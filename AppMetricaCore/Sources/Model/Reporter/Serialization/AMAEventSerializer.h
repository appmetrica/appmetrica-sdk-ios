
#import <Foundation/Foundation.h>

@class AMAEvent;
@protocol AMAReporterDatabaseEncoderProviding;

NS_ASSUME_NONNULL_BEGIN

@interface AMAEventSerializer : NSObject

- (instancetype)initWithEncoderFactory:(id<AMAReporterDatabaseEncoderProviding>)encoderFactory;

- (NSDictionary *)dictionaryForEvent:(AMAEvent *)event error:(NSError **)error;
- (nullable AMAEvent *)eventForDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
