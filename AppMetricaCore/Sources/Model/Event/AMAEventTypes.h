
typedef NS_ENUM(NSUInteger, AMAEventType) {
    AMAEventTypeInit = 1,
    AMAEventTypeStart = 2,
    AMAEventTypeCrash __deprecated = 3,
    AMAEventTypeClient = 4,
    AMAEventTypeReferrer = 5,
    AMAEventTypeError __deprecated = 6,
    AMAEventTypeAlive = 7,
    AMAEventTypeAccount = 12,
    AMAEventTypeFirst = 13,
    AMAEventTypeOpen = 16,
    AMAEventTypeUpdate = 17,
    AMAEventTypePermissions = 18,
    AMAEventTypeProfile = 20,
    AMAEventTypeRevenue = 21,
    AMAEventTypeProtobufANR = 25, // TODO: remove Crashes reference here
    AMAEventTypeProtobufCrash = 26, // TODO: remove Crashes reference here
    AMAEventTypeProtobufError = 27, // TODO: remove Crashes reference here
    AMAEventTypeCleanup = 29, // Excluded from AMAEventCountDispatchStrategy
    AMAEventTypeECommerce = 35,
    AMAEventTypeASAToken = 37,
    AMAEventTypeWebViewSync = 38,
    AMAEventTypeAttribution = 39,
    AMAEventTypeAdRevenue = 40,
};
