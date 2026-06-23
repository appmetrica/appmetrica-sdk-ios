
#pragma once

#import <Foundation/Foundation.h>

/// Whether the fake ALCCommunicator class is "available" (responds to SDK methods).
extern BOOL gALCCommunicatorAvailable;
extern NSMutableArray * _Nullable gALCSubscribedListeners;
extern NSMutableArray * _Nullable gALCUnsubscribedListeners;

void AMAAppLovinTestSDKStubsReset(void);

/// Send a fake message to all subscribers on the given topic.
void AMAAppLovinSimulateMessage(NSDictionary *data, NSString *topic);
