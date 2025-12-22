
#import <Foundation/Foundation.h>

#ifndef NS_SWIFT_NAME
#define NS_SWIFT_NAME(name)
#endif

NS_ASSUME_NONNULL_BEGIN

/** This class indicates user profile update.
 */
NS_SWIFT_NAME(UserProfileUpdate)
@interface AMAUserProfileUpdate : NSObject

@end

/** The name attribute protocol.
 It enables setting user name for the profile.

 @warning The maximum length of the user profile name is 100 characters.
 */
NS_SWIFT_NAME(NameAttribute)
@protocol AMANameAttribute <NSObject>

/** Updates the name attribute with the specified value.

 @param value Name attribute. It can contain up to 100 characters
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(nullable NSString *)value;

/** Resets the name attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** Gender enumeration.
 */
typedef NS_ENUM(NSUInteger, AMAGenderType) {

/** Male gender type.
 */
    AMAGenderTypeMale,

/** Female gender type.
 */
    AMAGenderTypeFemale,

/** Other gender type.
 You can set the `AMAGenderTypeOther` value to the gender attribute and pass additional info using the custom attribute.
 */
    AMAGenderTypeOther,
} NS_SWIFT_NAME(GenderType);

/** The gender attribute protocol.
 It enables linking user gender with the profile.
 */
NS_SWIFT_NAME(GenderAttribute)
@protocol AMAGenderAttribute <NSObject>

/** Updates the gender attribute with the specified value.

 @param value One of the `AMAGenderType` enumeration values
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(AMAGenderType)value;

/** Resets the gender attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** The birth date attribute protocol.
 It enables linking user birth date with the profile.
 */
NS_SWIFT_NAME(BirthDateAttribute)
@protocol AMABirthDateAttribute <NSObject>

/** Updates the birth date attribute with the specified value.
 It calculates the birth year by using the following formula:

    Birth Year = currentYear - age.

 @param value Age of the user
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withAge:(NSUInteger)value;

/** Updates the birth date attribute with the specified value.
 This method sets the year of birth date.

 @param year Year of birth
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withYear:(NSUInteger)year NS_SWIFT_NAME(withDate(year:));

/** Updates the birth date attribute with the specified values.
 This method sets the year and month of the birth date.

 @param year Year of birth
 @param month Month of birth
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withYear:(NSUInteger)year
                             month:(NSUInteger)month NS_SWIFT_NAME(withDate(year:month:));

/** Updates the birth date attribute with the specified values.
 This methods sets year, month and day of the month of the birth date.

 @param year Year of birth
 @param month Month of birth
 @param day Day of the month of birth
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withYear:(NSUInteger)year
                             month:(NSUInteger)month
                               day:(NSUInteger)day NS_SWIFT_NAME(withDate(year:month:day:));

/** Updates the birth date attribute with the specified value.

 @param dateComponents Birth date value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withDateComponents:(NSDateComponents *)dateComponents NS_SWIFT_NAME(withDate(dateComponents:));

/** Resets the birth date attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** The NotificationsEnabled attribute protocol.
 It indicates whether the user has enabled notifications for the application.
 It enables setting notification status for the profile.
 */
NS_SWIFT_NAME(NotificationsEnabledAttribute)
@protocol AMANotificationsEnabledAttribute <NSObject>

/** Updates the NotificationsEnabled attribute with the specified value.
 It indicates whether the user has enabled notifications for the application.

 @param value Notification state value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(BOOL)value;

/** Resets the NotificationsEnabled attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** The string attribute protocol.
 It enables creating custom string attribute for the profile.

 @warning The maximum length of the custom string attribute value is 200 characters.
 */
NS_SWIFT_NAME(CustomStringAttribute)
@protocol AMACustomStringAttribute <NSObject>

/** Updates the string attribute with the specified value.

 @param value String value. It can contain up to 200 characters
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(nullable NSString *)value;

/** Updates the attribute with the specified value only if the attribute value is undefined.
 The method doesn't affect the value if it has been set earlier.

 @param value String value. It can contain up to 200 characters
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueIfUndefined:(nullable NSString *)value;

/** Resets the attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** The number attribute protocol.
 It enables creating custom number attribute for the profile.
 */
NS_SWIFT_NAME(CustomNumberAttribute)
@protocol AMACustomNumberAttribute <NSObject>

/** Updates the number attribute with the specified value.

 @param value Number value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(double)value;

/** Updates the attribute with the specified value only if the attribute value is undefined.
 The method doesn't affect the value if it has been set earlier.

 @param value Number value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueIfUndefined:(double)value;

/** Resets the attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/** The counter attribute protocol.
 It enables creating custom counter for the profile.
 */
NS_SWIFT_NAME(CustomCounterAttribute)
@protocol AMACustomCounterAttribute <NSObject>
/** Updates the counter attribute value with the specified delt a value.

 @param value Delta value to change the counter attribute value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withDelta:(double)value;

@end

/** The boolean attribute protocol.
 It enables creating custom boolean attribute for the profile.
 */
NS_SWIFT_NAME(CustomBoolAttribute)
@protocol AMACustomBoolAttribute <NSObject>

/** Updates the bool attribute with the specified value.

 @param value Bool value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValue:(BOOL)value;

/** Updates the attribute with the specified value only if the attribute value is undefined.
 The method doesn't affect the value if it has been set earlier.

 @param value Bool value
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueIfUndefined:(BOOL)value;

/** Resets the attribute value.

 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withValueReset;

@end

/**
 * Attribute for setting the user's phone number hash.
 * The phone values will be normalized and hashed using SHA-256 before sending.
 * Supports setting multiple phone values (up to 10).
 */
NS_SWIFT_NAME(FirstPartyDataPhoneSha256Attribute)
@protocol AMAFirstPartyDataPhoneSha256Attribute <NSObject>

/** Sets multiple phone values for the attribute.
 The values will be normalized and hashed using SHA-256 before sending.
 Maximum number of values is limited to 10.
 Drops any values above the limit.
 
 @param values phone values to set
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withPhoneValues:(NSArray<NSString *> *)values;

@end

/**
 * Attribute for setting the user's email address hash.
 * The email values will be normalized and hashed using SHA-256 before sending.
 * Supports setting multiple email values (up to 10).
 */
NS_SWIFT_NAME(FirstPartyDataEmailSha256Attribute)
@protocol AMAFirstPartyDataEmailSha256Attribute <NSObject>

/** Sets multiple email values for the attribute from an iterable.
 The values will be normalized and hashed using SHA-256 before sending.
 Maximum number of values is limited to 10.
 Drops any values above the limit.
 
 @param values email values to set
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withEmailValues:(NSArray<NSString *> *)values;

@end

/**
 * Attribute for setting the user's Telegram login hash.
 * The Telegram login values will be normalized and hashed using SHA-256 before sending.
 * Supports setting multiple Telegram login values (up to 10).
 */
NS_SWIFT_NAME(FirstPartyDataTelegramLoginSha256Attribute)
@protocol AMAFirstPartyDataTelegramLoginSha256Attribute <NSObject>

/** Sets multiple Telegram login values for the attribute.
 The values will be normalized and hashed using SHA-256 before sending.
 Maximum number of values is limited to 10.
 Drops any values above the limit.

 @param values Telegram login values to set
 @return The `AMAUserProfileUpdate` object
 */
- (AMAUserProfileUpdate *)withTelegramLoginValues:(NSArray<NSString *> *)values;

@end

/** The attribute class
 Attribute is a property of the user profile.
 You can use predefined attributes (e.g. name, gender, etc.) or create your own.
 AppMetrica allows you to create up to 100 custom attributes.
 */
NS_SWIFT_NAME(ProfileAttribute)
@interface AMAProfileAttribute : NSObject

/** Creates a name attribute.

 @return The `AMANameAttribute` object
 */
+ (id<AMANameAttribute>)name;

/** Creates a gender attribute.

 @return The `AMAGenderAttribute` object
 */
+ (id<AMAGenderAttribute>)gender;

/** Creates a birth date attribute.

 @return The `AMABirthDateAttribute` object
 */
+ (id<AMABirthDateAttribute>)birthDate;

/** Creates a NotificationsEnabled attribute.
 It indicates whether the user has enabled notifications for the application.

 @return The `AMANotificationsEnabledAttribute` object
 */
+ (id<AMANotificationsEnabledAttribute>)notificationsEnabled;

/** Creates an attribute for setting the user's phone number hash.
 The value will be normalized and hashed using SHA-256 before sending.

 @return The `AMAFirstPartyDataPhoneSha256Attribute` object
 */
+ (id<AMAFirstPartyDataPhoneSha256Attribute>)phoneHash;

/** Creates an attribute for setting the user's email address hash.
 The value will be normalized and hashed using SHA-256 before sending.

 @return The `AMAFirstPartyDataEmailSha256Attribute` object
 */
+ (id<AMAFirstPartyDataEmailSha256Attribute>)emailHash;

/** Creates an attribute for setting the user's Telegram login hash.
 The value will be normalized and hashed using SHA-256 before sending.

 @return The `AMAFirstPartyDataTelegramLoginSha256Attribute` object
 */
+ (id<AMAFirstPartyDataTelegramLoginSha256Attribute>)telegramLoginHash;

/** Creates a custom string attribute.

 @param name Attribute name. It can contain up to 200 characters
 @return The `AMACustomStringAttribute` object
 */
+ (id<AMACustomStringAttribute>)customString:(NSString *)name;

/** Creates a custom number attribute.

 @param name Attribute name. It can contain up to 200 characters
 @return The `AMACustomNumberAttribute` object
 */
+ (id<AMACustomNumberAttribute>)customNumber:(NSString *)name;

/** Creates a custom counter attribute.

 @param name Attribute name. It can contain up to 200 characters
 @return The `AMACustomCounterAttribute` object
 */
+ (id<AMACustomCounterAttribute>)customCounter:(NSString *)name;

/** Creates a custom boolean attribute.

 @param name Attribute name. It can contain up to 200 characters
 @return The `AMACustomBoolAttribute` object
 */
+ (id<AMACustomBoolAttribute>)customBool:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
