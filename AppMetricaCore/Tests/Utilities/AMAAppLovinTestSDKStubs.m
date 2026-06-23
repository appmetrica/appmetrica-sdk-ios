
#import "AMAAppLovinTestSDKStubs.h"
#import <objc/message.h>

BOOL gALCCommunicatorAvailable = NO;
NSMutableArray *gALCSubscribedListeners = nil;
NSMutableArray *gALCUnsubscribedListeners = nil;

void AMAAppLovinTestSDKStubsReset(void) {
    gALCCommunicatorAvailable  = NO;
    gALCSubscribedListeners    = [NSMutableArray array];
    gALCUnsubscribedListeners  = [NSMutableArray array];
}

// Fake ALCMessage: responds to -topic and -data as the real SDK class does
@interface AMAFakeALCMessage : NSObject
- (instancetype)initWithData:(NSDictionary *)data topic:(NSString *)topic;
@end
@implementation AMAFakeALCMessage {
    NSDictionary *_data;
    NSString *_topic;
}
- (instancetype)initWithData:(NSDictionary *)data topic:(NSString *)topic {
    self = [super init];
    _data = data;
    _topic = topic;
    return self;
}
- (NSDictionary *)data { return _data; }
- (NSString *)topic { return _topic; }
@end

void AMAAppLovinSimulateMessage(NSDictionary *data, NSString *topic) {
    AMAFakeALCMessage *msg = [[AMAFakeALCMessage alloc] initWithData:data topic:topic];
    SEL sel = NSSelectorFromString(@"didReceiveMessage:");
    for (id listener in [gALCSubscribedListeners copy]) {
        if ([listener respondsToSelector:sel]) {
            ((void (*)(id, SEL, id))objc_msgSend)(listener, sel, msg);
        }
    }
}

// Fake ALCCommunicator — found by NSClassFromString(@"ALCCommunicator")
@interface ALCCommunicator : NSObject
@end
@implementation ALCCommunicator
+ (BOOL)respondsToSelector:(SEL)selector
{
    if (selector == NSSelectorFromString(@"defaultCommunicator")) {
        return gALCCommunicatorAvailable;
    }
    return [super respondsToSelector:selector];
}
+ (ALCCommunicator *)defaultCommunicator
{
    static ALCCommunicator *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[self alloc] init]; });
    return instance;
}
- (void)subscribe:(id)listener forTopic:(NSString *)topic
{
    [gALCSubscribedListeners addObject:listener];
}
- (void)unsubscribe:(id)listener forTopic:(NSString *)topic
{
    [gALCUnsubscribedListeners addObject:listener];
    [gALCSubscribedListeners removeObject:listener];
}
@end
