
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashBacktraceFrame)
@interface AMACrashBacktraceFrame : NSObject <NSCopying>

@property (nonatomic, strong, readonly, nullable) NSNumber *lineOfCode;
@property (nonatomic, strong, readonly, nullable) NSNumber *columnOfCode;
@property (nonatomic, strong, readonly, nullable) NSNumber *instructionAddress;
@property (nonatomic, strong, readonly, nullable) NSNumber *symbolAddress;
@property (nonatomic, strong, readonly, nullable) NSNumber *objectAddress;

@property (nonatomic, copy, readonly, nullable) NSString *symbolName;
@property (nonatomic, copy, readonly, nullable) NSString *objectName;
@property (nonatomic, copy, readonly, nullable) NSString *className;
@property (nonatomic, copy, readonly, nullable) NSString *methodName;
@property (nonatomic, copy, readonly, nullable) NSString *sourceFileName;

@property (nonatomic, assign, readonly) BOOL stripped;

- (instancetype)initWithClassName:(nullable NSString *)className
                       methodName:(nullable NSString *)methodName
                       lineOfCode:(nullable NSNumber *)lineOfCode
                     columnOfCode:(nullable NSNumber *)columnOfCode
                   sourceFileName:(nullable NSString *)sourceFileName;

@end

/** Mutable version of the `AMACrashBacktraceFrame` class. */
NS_SWIFT_NAME(MutableCrashBacktraceFrame)
@interface AMAMutableCrashBacktraceFrame : AMACrashBacktraceFrame

@property (nonatomic, strong, nullable) NSNumber *instructionAddress;
@property (nonatomic, strong, nullable) NSNumber *symbolAddress;
@property (nonatomic, strong, nullable) NSNumber *objectAddress;

@property (nonatomic, copy, nullable) NSString *symbolName;
@property (nonatomic, copy, nullable) NSString *objectName;

@property (nonatomic, assign) BOOL stripped;

@end

NS_ASSUME_NONNULL_END
