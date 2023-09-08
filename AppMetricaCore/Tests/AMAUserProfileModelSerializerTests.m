
#import <Kiwi/Kiwi.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import "AMAUserProfileModelSerializer.h"
#import "AMAUserProfileModel.h"
#import "AMAAttributeKey.h"
#import "AMAAttributeValue.h"
#import "Profile.pb-c.h"

SPEC_BEGIN(AMAUserProfileModelSerializerTests)

describe(@"AMAUserProfileModelSerializer", ^{

    double const AMA_EPSILON = 0.000001;

    AMAProtobufAllocator *__block allocator = nil;
    Ama__Profile *__block profile = NULL;
    AMAUserProfileModelSerializer *__block serializer = nil;

    beforeAll(^{
        allocator = [[AMAProtobufAllocator alloc] init];
    });

    beforeEach(^{
        serializer = [[AMAUserProfileModelSerializer alloc] init];
    });

    Ama__Profile *(^sirializeAndDeserializeModel)(AMAUserProfileModel *) = ^(AMAUserProfileModel *model) {
        NSData *data = [serializer dataWithModel:model];
        return ama__profile__unpack([allocator protobufCAllocator], data.length, data.bytes);
    };

    NSString *(^stringForBinary)(ProtobufCBinaryData *) = ^(ProtobufCBinaryData *binaryData) {
        NSData *data = [NSData dataWithBytes:binaryData->data length:binaryData->len];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    };

    context(@"String attribute", ^{
        NSString *const expectedName = @"NAME";
        NSString *const expectedStringValue = @"VALUE";
        beforeAll(^{
            AMAUserProfileModel *model = [[AMAUserProfileModel alloc] init];
            AMAAttributeKey *key = [[AMAAttributeKey alloc] initWithName:expectedName type:AMAAttributeTypeString];
            AMAAttributeValue *value = [[AMAAttributeValue alloc] init];
            value.stringValue = expectedStringValue;
            model.attributes = [NSMutableDictionary dictionary];
            model.attributes[key] = value;
            profile = sirializeAndDeserializeModel(model);
        });
        it(@"Should have 1 attribute", ^{
            [[theValue(profile->n_attributes) should] equal:theValue(1)];
        });
        context(@"Attribute", ^{
            Ama__Profile__Attribute *__block attribute = NULL;
            beforeAll(^{
                attribute = profile->attributes[0];
            });
            it(@"Should set name", ^{
                [[stringForBinary(&(attribute->name)) should] equal:expectedName];
            });
            it(@"Should set type", ^{
                [[theValue(attribute->type) should] equal:theValue(AMA__PROFILE__ATTRIBUTE__TYPE__STRING)];
            });
            it(@"Should set has_string_value", ^{
                [[theValue(attribute->value->has_string_value) should] beYes];
            });
            it(@"Should set string_value", ^{
                [[stringForBinary(&(attribute->value->string_value)) should] equal:expectedStringValue];
            });
        });
    });
    context(@"Number attribute", ^{
        NSString *const expectedName = @"NAME";
        double const expectedNumberValue = 23.0;
        beforeAll(^{
            AMAUserProfileModel *model = [[AMAUserProfileModel alloc] init];
            AMAAttributeKey *key = [[AMAAttributeKey alloc] initWithName:expectedName
                                                                                type:AMAAttributeTypeNumber];
            AMAAttributeValue *value = [[AMAAttributeValue alloc] init];
            value.numberValue = @(expectedNumberValue);
            model.attributes = [NSMutableDictionary dictionary];
            model.attributes[key] = value;
            profile = sirializeAndDeserializeModel(model);
        });
        it(@"Should have 1 attribute", ^{
            [[theValue(profile->n_attributes) should] equal:theValue(1)];
        });
        context(@"Attribute", ^{
            Ama__Profile__Attribute *__block attribute = NULL;
            beforeAll(^{
                attribute = profile->attributes[0];
            });
            it(@"Should set name", ^{
                [[stringForBinary(&(attribute->name)) should] equal:expectedName];
            });
            it(@"Should set type", ^{
                [[theValue(attribute->type) should] equal:theValue(AMA__PROFILE__ATTRIBUTE__TYPE__NUMBER)];
            });
            it(@"Should set has_string_value", ^{
                [[theValue(attribute->value->has_number_value) should] beYes];
            });
            it(@"Should set string_value", ^{
                [[theValue(attribute->value->number_value) should] equal:expectedNumberValue withDelta:AMA_EPSILON];
            });
        });
    });
    context(@"Counter attribute", ^{
        NSString *const expectedName = @"NAME";
        double const expectedCounterValue = 42.0;
        beforeAll(^{
            AMAUserProfileModel *model = [[AMAUserProfileModel alloc] init];
            AMAAttributeKey *key = [[AMAAttributeKey alloc] initWithName:expectedName
                                                                                type:AMAAttributeTypeCounter];
            AMAAttributeValue *value = [[AMAAttributeValue alloc] init];
            value.counterValue = @(expectedCounterValue);
            model.attributes = [NSMutableDictionary dictionary];
            model.attributes[key] = value;
            profile = sirializeAndDeserializeModel(model);
        });
        it(@"Should have 1 attribute", ^{
            [[theValue(profile->n_attributes) should] equal:theValue(1)];
        });
        context(@"Attribute", ^{
            Ama__Profile__Attribute *__block attribute = NULL;
            beforeAll(^{
                attribute = profile->attributes[0];
            });
            it(@"Should set name", ^{
                [[stringForBinary(&(attribute->name)) should] equal:expectedName];
            });
            it(@"Should set type", ^{
                [[theValue(attribute->type) should] equal:theValue(AMA__PROFILE__ATTRIBUTE__TYPE__COUNTER)];
            });
            it(@"Should set has_string_value", ^{
                [[theValue(attribute->value->has_counter_modification) should] beYes];
            });
            it(@"Should set string_value", ^{
                [[theValue(attribute->value->counter_modification) should] equal:expectedCounterValue withDelta:AMA_EPSILON];
            });
        });
    });
    context(@"Reset", ^{
        NSString *const expectedName = @"NAME";
        beforeAll(^{
            AMAUserProfileModel *model = [[AMAUserProfileModel alloc] init];
            AMAAttributeKey *key = [[AMAAttributeKey alloc] initWithName:expectedName
                                                                                type:AMAAttributeTypeString];
            AMAAttributeValue *value = [[AMAAttributeValue alloc] init];
            value.reset = @YES;
            model.attributes = [NSMutableDictionary dictionary];
            model.attributes[key] = value;
            profile = sirializeAndDeserializeModel(model);
        });
        it(@"Should have 1 attribute", ^{
            [[theValue(profile->n_attributes) should] equal:theValue(1)];
        });
        context(@"Attribute", ^{
            Ama__Profile__Attribute *__block attribute = NULL;
            beforeAll(^{
                attribute = profile->attributes[0];
            });
            it(@"Should set name", ^{
                [[stringForBinary(&(attribute->name)) should] equal:expectedName];
            });
            it(@"Should set type", ^{
                [[theValue(attribute->type) should] equal:theValue(AMA__PROFILE__ATTRIBUTE__TYPE__STRING)];
            });
            it(@"Should set has_reset_value", ^{
                [[theValue(attribute->meta_info->has_reset) should] beYes];
            });
            it(@"Should set reset_value", ^{
                [[theValue(attribute->meta_info->reset) should] beYes];
            });
        });
    });
    context(@"Undefined", ^{
        NSString *const expectedName = @"NAME";
        beforeAll(^{
            AMAUserProfileModel *model = [[AMAUserProfileModel alloc] init];
            AMAAttributeKey *key = [[AMAAttributeKey alloc] initWithName:expectedName
                                                                    type:AMAAttributeTypeString];
            AMAAttributeValue *value = [[AMAAttributeValue alloc] init];
            value.setIfUndefined = @YES;
            model.attributes = [NSMutableDictionary dictionary];
            model.attributes[key] = value;
            profile = sirializeAndDeserializeModel(model);
        });
        it(@"Should have 1 attribute", ^{
            [[theValue(profile->n_attributes) should] equal:theValue(1)];
        });
        context(@"Attribute", ^{
            Ama__Profile__Attribute *__block attribute = NULL;
            beforeAll(^{
                attribute = profile->attributes[0];
            });
            it(@"Should set name", ^{
                [[stringForBinary(&(attribute->name)) should] equal:expectedName];
            });
            it(@"Should set type", ^{
                [[theValue(attribute->type) should] equal:theValue(AMA__PROFILE__ATTRIBUTE__TYPE__STRING)];
            });
            it(@"Should set has_set_if_undefined", ^{
                [[theValue(attribute->meta_info->has_set_if_undefined) should] beYes];
            });
            it(@"Should set set_if_undefined", ^{
                [[theValue(attribute->meta_info->set_if_undefined) should] beYes];
            });
        });
    });
    
});

SPEC_END
