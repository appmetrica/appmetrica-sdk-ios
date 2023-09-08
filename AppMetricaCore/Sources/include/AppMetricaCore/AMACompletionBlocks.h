
NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMAUUIDKey;
extern NSString *const kAMADeviceIDKey;
extern NSString *const kAMADeviceIDHashKey;

/** Identifiers callback block

 @param identifiers  Contains any combination of following identifiers on success:
     kAMAUUIDKey
     kAMADeviceIDKey
     kAMADeviceIDHashKey (requires startup request)
     and any other custom keys that are defined in startup
 Empty dictionary may be returned if server by any reason did not provide any of above listed
 identifiers.

 @param error Error of NSURLErrorDomain. In a case of error identifiers param is nil.
 */
typedef void(^AMAIdentifiersCompletionBlock)(NSDictionary<NSString *, id> * _Nullable identifiers,
                                             NSError * _Nullable error);

/** Identifiers callback block

 @param appMetricaDeviceID Contains retrieved appMetricaDeviceID
 Empty appMetricaDeviceID may be returned if server by any reason did not provide identifier.

 @param error Error of NSURLErrorDomain. In a case of error appMetricaDeviceID param is nil.
 */
typedef void(^AMAAppMetricaDeviceIDRetrievingBlock)(NSString * _Nullable appMetricaDeviceID, NSError * _Nullable error);

NS_ASSUME_NONNULL_END
