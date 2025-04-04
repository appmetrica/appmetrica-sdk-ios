
#import "AMAProtoConversionUtility.h"

@implementation AMAProtoConversionUtility

+ (BOOL)fillBoolValue:(ama_protobuf_c_boolean *)value withOptionalBool:(AMAOptionalBool)optionalBool
{
    if (optionalBool == AMAOptionalBoolUndefined) {
        return NO;
    }
    *value = optionalBool == AMAOptionalBoolTrue;
    return YES;
}

+ (Ama__ReportMessage__Session__Event__EventSource)eventSourceToLocalProto:(AMAEventSource)model
{
    switch (model)
    {
        case AMAEventSourceJs:
            return AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__JS;
        case AMAEventSourceSDKSystem:
            return AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__SDK_SYSTEM;
        case AMAEventSourceNative:
        default:
            return AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__NATIVE;
    }
}

+ (Ama__EventData__EventSource)eventSourceToServerProto:(AMAEventSource)model
{
    switch (model)
    {
        case AMAEventSourceJs:
            return AMA__EVENT_DATA__EVENT_SOURCE__JS;
        case AMAEventSourceSDKSystem:
            return AMA__EVENT_DATA__EVENT_SOURCE__SDK_SYSTEM;
        case AMAEventSourceNative:
        default:
            return AMA__EVENT_DATA__EVENT_SOURCE__NATIVE;
    }
}

+ (AMAEventSource)eventSourceToModel:(Ama__EventData__EventSource)proto
{
    switch (proto)
    {
        case AMA__EVENT_DATA__EVENT_SOURCE__JS:
            return AMAEventSourceJs;
        case AMA__EVENT_DATA__EVENT_SOURCE__SDK_SYSTEM:
            return AMAEventSourceSDKSystem;
        case AMA__EVENT_DATA__EVENT_SOURCE__NATIVE:
        default:
            return AMAEventSourceNative;
    }
}

+ (AMAOptionalBool)optionalBoolForBoolValue:(ama_protobuf_c_boolean)value hasValue:(ama_protobuf_c_boolean)hasValue
{
    if (hasValue == false) {
        return AMAOptionalBoolUndefined;
    }
    return value ? AMAOptionalBoolTrue : AMAOptionalBoolFalse;
}

@end
