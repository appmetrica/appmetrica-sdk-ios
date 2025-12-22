
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAFirstPartyDataSha256Attribute.h"
#import "AMAUserProfileUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAStringAttributeValueUpdate.h"
#import "AMAAttributeValueNormalizer.h"
#import "AMACompositeUserProfileUpdateProviding.h"
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAFirstPartyDataSha256AttributeTests)

describe(@"AMAFirstPartyDataSha256Attribute", ^{
    
    NSObject<AMACompositeUserProfileUpdateProviding> *__block userProfileUpdateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    NSObject<AMAAttributeValueNormalizer> *__block normalizer = nil;
    id<AMAStringTruncating> __block truncator = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAFirstPartyDataSha256Attribute *__block attribute = nil;
    
    AMAStringAttributeValueUpdate *__block stringAttributeValueUpdate = nil;
    AMAStringAttributeValueUpdate *__block allocedStringValueUpdate = nil;
    
    beforeEach(^{
        userProfileUpdateProvider = [KWMock nullMockForProtocol:@protocol(AMACompositeUserProfileUpdateProviding)];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];
        normalizer = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueNormalizer)];
        truncator = [KWMock nullMockForProtocol:@protocol(AMAStringTruncating)];
        userProfileUpdate = [AMAUserProfileUpdate nullMock];
        
        allocedStringValueUpdate = [AMAStringAttributeValueUpdate nullMock];
        stringAttributeValueUpdate = [AMAStringAttributeValueUpdate nullMock];
        [AMAStringAttributeValueUpdate stub:@selector(alloc) andReturn:allocedStringValueUpdate];
        
        attributeUpdate = [AMAAttributeUpdate nullMock];
        
        [truncationProvider stub:@selector(truncatorWithAttributeName:) andReturn:truncator];
        [userProfileUpdateProvider stub:@selector(profileUpdateWithAttributeUpdates:) andReturn:userProfileUpdate];
        
        attribute = [[AMAFirstPartyDataSha256Attribute alloc] initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                                                             truncationProvider:truncationProvider
                                                                                     normalizer:normalizer];
    });
    
    afterEach(^{
        [AMAStringAttributeValueUpdate clearStubs];
        [KWMock clearStubs];
    });
    
    context(@"Initialization", ^{
        it(@"Should have userProfileUpdateProvider", ^{
            [[(NSObject *)attribute.userProfileUpdateProvider should] equal:userProfileUpdateProvider];
        });
        
        it(@"Should have truncationProvider", ^{
            [[attribute.truncationProvider should] equal:truncationProvider];
        });
        
        it(@"Should have normalizer", ^{
            [[(NSObject *)attribute.normalizer should] equal:normalizer];
        });
    });
    
    void (^stubHasher)(NSString *, NSString *) = ^(NSString *input, NSString *output) {
        [AMAHashUtility stub:@selector(sha256HashForString:) andReturn:output withArguments:input];
    };
    
    context(@"withValues", ^{
        NSString *const hashedValue = @"hashed12345";
        NSString *const value = @"  TEST@EXAMPLE.COM  ";
        NSString *const normalized = @"  EXAMPLE@TEST.ORG  ";
        NSString *const expectedAttributeName = @"test_0";
        NSString *const invalidValue = @"???";
        
        beforeEach(^{
            [attribute stub:@selector(maxCount) andReturn:theValue(3)];
            [attribute stub:@selector(attributePrefix) andReturn:@"test_"];
        });
        afterEach(^{
            [AMAHashUtility clearStubs];
        });
        
        it(@"Should normalize, trim, lowercase, deduplicate, hash and create indexed attribute updates", ^{
            [normalizer stub:@selector(normalizeValue:) andReturn:normalized withArguments:value];
            [normalizer stub:@selector(normalizeValue:) andReturn:nil withArguments:invalidValue];
            NSString *trimmedLowercased = [[normalized
                                            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                           lowercaseString];
            stubHasher(trimmedLowercased, hashedValue);
            
            // Stub string attribute value update allocation with expected init
            [allocedStringValueUpdate stub:@selector(initWithValue:truncator:)
                                 andReturn:stringAttributeValueUpdate
                             withArguments:hashedValue, truncator];
            
            // Stub attribute update with expected init
            [userProfileUpdateProvider stub:@selector(attributeUpdateWithAttributeName:type:valueUpdate:)
                                  andReturn:attributeUpdate
                              withArguments:expectedAttributeName, theValue(AMAAttributeTypeString), stringAttributeValueUpdate];
            
            KWCaptureSpy *spy = [userProfileUpdateProvider captureArgument:@selector(profileUpdateWithAttributeUpdates:) atIndex:0];
            
            [attribute withValues:@[value, value, invalidValue, value]];
            
            NSArray<AMAAttributeUpdate *> *updates = spy.argument;
            // Only one valid value should produce one update
            [[theValue(updates.count) should] equal:theValue(1)];
            [[updates[0] should] equal:attributeUpdate];
        });
    });
    
});

SPEC_END
