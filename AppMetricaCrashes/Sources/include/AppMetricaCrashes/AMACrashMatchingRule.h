
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Container with rules for crash matching.

 AppMetrica SDK collects symbols (addresses) of methods of classes declared in this rule, in runtime,
 once per application build. If a crash report contains any collected symbol, it will be sent to the 
 reporter registered this rule for crash matching. AppMetrica SDK symbolicates crash symbols extracted 
 with this rule.

 "False-positive" crash matching is not allowed, but "false-negative" is. It means that crash in the class 
 declared in this rule may not be matched, but every matched crash contains a method of some declared class 
 in the crashed thread stacktrace.

 Additionally, names of dynamic framework binaries could be provided to match crashes. Symbolication for this
 type of matching is not guaranteed, but accuracy is much greater. Collisions are possible only if there are
 more than one dynamic framework with the same name what is pretty unlikely.

 Correct matching of system classes and their extensions is not guaranteed.
 */
NS_SWIFT_NAME(CrashMatchingRule)
@interface AMACrashMatchingRule : NSObject<NSCopying>

/** Classes for crash matching.
 */
@property (nonatomic, copy, nullable, readonly) NSArray<Class> *classes;

/** Class prefixes for crash matching.
 All classes with these prefixes will be processed like if they where in property "classes" of this rule.
 */
@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *classPrefixes;

/** Names of dynamic framework binaries for crash matching.
 */
@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *dynamicBinaryNames;

/** Initialize crash matching rule with specific classes and class prefixes.
 @param classes Classes for crash matching.
 @param classPrefixes Class prefixes for crash matching.
 */
- (instancetype)initWithClasses:(nullable NSArray<Class> *)classes
                  classPrefixes:(nullable NSArray<NSString *> *)classPrefixes;

/** Initialize crash matching rule with specific classes, class prefixes and dynamic binary names.
 @param classes Classes for crash matching.
 @param classPrefixes Class prefixes for crash matching.
 @param dynamicBinaryNames Names of dynamic framework binaries for crash matching.
 */
- (instancetype)initWithClasses:(nullable NSArray<Class> *)classes
                  classPrefixes:(nullable NSArray<NSString *> *)classPrefixes
             dynamicBinaryNames:(nullable NSArray<NSString *> *)dynamicBinaryNames;

@end

NS_ASSUME_NONNULL_END
