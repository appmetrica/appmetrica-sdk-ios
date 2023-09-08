
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMALocaleMock : NSObject

@property (nonatomic, copy, readonly) NSString *languageCode;
@property (nonatomic, copy, nullable) NSString *countryCode;
@property (nonatomic, copy, nullable) NSString *scriptCode;

- (instancetype)initWithLanguageCode:(NSString *)languageCode;
- (nullable id)objectForKey:(id)key;

@end

NS_ASSUME_NONNULL_END
