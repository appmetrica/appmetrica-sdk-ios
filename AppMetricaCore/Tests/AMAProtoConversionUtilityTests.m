#import <Kiwi/Kiwi.h>
#import "AMAProtoConversionUtility.h"

SPEC_BEGIN(AMAProtoConversionUtilityTests)

describe(@"AMAProtoConversionUtility", ^{
    
    __block protobuf_c_boolean testValue;
    __block AMAOptionalBool testOptionalBool;
    __block AMAEventSource testEventSource;
    __block Ama__EventData__EventSource testProtoEventSource;
    
    context(@"when filling bool value with optional bool", ^{
        
        it(@"should return NO and not modify the value for AMAOptionalBoolUndefined", ^{
            testOptionalBool = AMAOptionalBoolUndefined;
            BOOL result = [AMAProtoConversionUtility fillBoolValue:&testValue withOptionalBool:testOptionalBool];
            [[theValue(result) should] beFalse];
        });
        
        it(@"should return YES and set value to true for AMAOptionalBoolTrue", ^{
            testOptionalBool = AMAOptionalBoolTrue;
            BOOL result = [AMAProtoConversionUtility fillBoolValue:&testValue withOptionalBool:testOptionalBool];
            [[theValue(result) should] beTrue];
            [[theValue(testValue) should] beTrue];
        });
        
        it(@"should return YES and set value to false for AMAOptionalBoolFalse", ^{
            testOptionalBool = AMAOptionalBoolFalse;
            BOOL result = [AMAProtoConversionUtility fillBoolValue:&testValue withOptionalBool:testOptionalBool];
            [[theValue(result) should] beTrue];
            [[theValue(testValue) should] beFalse];
        });
    });
    
    context(@"when converting event source to local proto", ^{
        it(@"should convert JS source to local proto JS", ^{
            testEventSource = AMAEventSourceJs;
            Ama__ReportMessage__Session__Event__EventSource result = [AMAProtoConversionUtility eventSourceToLocalProto:testEventSource];
            [[theValue(result) should] equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__JS)];
        });
        
        it(@"should convert native source (or default) to local proto native", ^{
            testEventSource = AMAEventSourceNative;
            Ama__ReportMessage__Session__Event__EventSource result = [AMAProtoConversionUtility eventSourceToLocalProto:testEventSource];
            [[theValue(result) should] equal:theValue(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__NATIVE)];
        });
    });
    
    context(@"when converting event source to server proto", ^{
        it(@"should convert JS source to server proto JS", ^{
            testEventSource = AMAEventSourceJs;
            Ama__EventData__EventSource result = [AMAProtoConversionUtility eventSourceToServerProto:testEventSource];
            [[theValue(result) should] equal:theValue(AMA__EVENT_DATA__EVENT_SOURCE__JS)];
        });
        
        it(@"should convert native source (or default) to server proto native", ^{
            testEventSource = AMAEventSourceNative;
            Ama__EventData__EventSource result = [AMAProtoConversionUtility eventSourceToServerProto:testEventSource];
            [[theValue(result) should] equal:theValue(AMA__EVENT_DATA__EVENT_SOURCE__NATIVE)];
        });
    });
    
    context(@"when converting event source to model", ^{
        it(@"should convert proto JS to model JS", ^{
            testProtoEventSource = AMA__EVENT_DATA__EVENT_SOURCE__JS;
            AMAEventSource result = [AMAProtoConversionUtility eventSourceToModel:testProtoEventSource];
            [[theValue(result) should] equal:theValue(AMAEventSourceJs)];
        });
        
        it(@"should convert proto native (or default) to model native", ^{
            testProtoEventSource = AMA__EVENT_DATA__EVENT_SOURCE__NATIVE;
            AMAEventSource result = [AMAProtoConversionUtility eventSourceToModel:testProtoEventSource];
            [[theValue(result) should] equal:theValue(AMAEventSourceNative)];
        });
    });
    
    context(@"when getting optional bool for bool value", ^{
        it(@"should return undefined for false hasValue", ^{
            protobuf_c_boolean hasValue = false;
            AMAOptionalBool result = [AMAProtoConversionUtility optionalBoolForBoolValue:testValue hasValue:hasValue];
            [[theValue(result) should] equal:theValue(AMAOptionalBoolUndefined)];
        });
        
        it(@"should return true for true value and true hasValue", ^{
            testValue = true;
            protobuf_c_boolean hasValue = true;
            AMAOptionalBool result = [AMAProtoConversionUtility optionalBoolForBoolValue:testValue hasValue:hasValue];
            [[theValue(result) should] equal:theValue(AMAOptionalBoolTrue)];
        });
        
        it(@"should return false for false value and true hasValue", ^{
            testValue = false;
            protobuf_c_boolean hasValue = true;
            AMAOptionalBool result = [AMAProtoConversionUtility optionalBoolForBoolValue:testValue hasValue:hasValue];
            [[theValue(result) should] equal:theValue(AMAOptionalBoolFalse)];
        });
    });
});

SPEC_END
