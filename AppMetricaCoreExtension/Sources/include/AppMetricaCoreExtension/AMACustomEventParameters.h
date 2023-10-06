
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMAApplicationState;

typedef NS_ENUM(NSUInteger, AMAEventValueType) {
    AMAEventValueTypeString,
    AMAEventValueTypeBinary,
    AMAEventValueTypeFile
};

@interface AMACustomEventParameters: NSObject

@property (nonatomic) NSUInteger eventType;
@property (nonatomic, nullable) NSString *name;
@property (nonatomic, nullable) NSData *data;
/// If creationDate is nil, current date is used
@property (nonatomic, nullable) NSDate *creationDate;
/// Event value type. Default is AMAEventValueTypeString.
@property (nonatomic) AMAEventValueType valueType;
@property (nonatomic, nullable) NSString *fileName;
/// Flag to indicate if gzip compression should be used. Default is YES.
@property (nonatomic) BOOL GZipped;
/// Flag to indicate if truncation should be used. Default is YES.
@property (nonatomic) BOOL truncated;
/// Flag to indicate if encryption should be used. Default is NO.
@property (nonatomic) BOOL encrypted;
@property (nonatomic, copy, nullable) NSDictionary *appEnvironment;
@property (nonatomic, copy, nullable) NSDictionary *errorEnvironment;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSData *> *extras;
/// Takes effect in session fetching if the event is in the past
@property (nonatomic, nullable) AMAApplicationState *appState;
/// Flag to indicate if the event is in the past. Default is NO.
@property (nonatomic) BOOL isPast; // TODO: (glinnik) remove this feature
/// In case you use some kind of own truncator. The value will be added to truncated bytes number inside. Defaut is 0.
@property (nonatomic, assign) NSUInteger bytesTruncated;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithEventType:(NSUInteger)eventType;

@end


NS_ASSUME_NONNULL_END
