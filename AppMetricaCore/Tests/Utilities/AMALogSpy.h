
#import <Foundation/Foundation.h>
#import <AppMetricaLog/AppMetricaLog.h>

@interface AMALogMessageSpy : NSObject <NSCopying>

@property (nonatomic, strong, readonly) AMALogChannel channel;
@property (nonatomic, strong, readonly) NSNumber *level;
@property (nonatomic, copy, readonly) NSString *file;
@property (nonatomic, copy, readonly) NSString *function;
@property (nonatomic, strong, readonly) NSNumber *line;
@property (nonatomic, strong, readonly) NSNumber *addBacktrace;
@property (nonatomic, copy, readonly) NSString *text;

+ (instancetype)messageWithText:(NSString *)text;
+ (instancetype)messageWithText:(NSString *)text channel:(AMALogChannel)channel;
+ (instancetype)messageWithText:(NSString *)text channel:(AMALogChannel)channel level:(AMALogLevel)level;

- (instancetype)initWithChannel:(AMALogChannel)channel
                          level:(NSNumber *)level
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSNumber *)line
                   addBacktrace:(NSNumber *)addBacktrace
                           text:(NSString *)text;

@end

@interface AMALogSpy : NSObject

@property (nonatomic, copy, readonly) NSArray *messages;

- (void)logMessageToChannel:(AMALogChannel)channel
                      level:(AMALogLevel)level
                       file:(const char *)file
                   function:(const char *)function
                       line:(NSUInteger)line
               addBacktrace:(BOOL)addBacktrace
                     format:(NSString *)format, ...;

@end
